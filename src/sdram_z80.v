module sdram_z80_interface (
    input clk_50,          // 50.35 MHz
    input reset_n,
    
    // Z80 Bus
    input [15:0] addr_i,
    input [7:0]  data_i,
    output [7:0] data_o,
    input mreq_n, rd_n, wr_n,
    output reg wait_n,
    input ram_cs,
    // Physical SDRAM Pins (Tang Nano 20K / GW2AR-18)
    output        sd_clk,
    output        sd_cke,
    output        sd_cs_n,
    output reg    sd_ras_n,
    output reg    sd_cas_n,
    output reg    sd_we_n,
    output reg [3:0] sd_dqm,
    output reg [10:0] sd_a,  
    output reg [1:0]  sd_ba, 
    inout      [31:0] sd_dq,   
    
    // Banking Interface
    input [8:0] current_bank_reg
);

    // Command patterns
    localparam C_NOP = 3'b111, C_PRE = 3'b010, C_REF = 3'b001, 
               C_MRS = 3'b000, C_ACT = 3'b011, C_RD  = 3'b101, C_WR = 3'b100;

    reg [3:0] state;
    reg [15:0] wait_cnt;
    reg [11:0]  ref_timer;
    reg [31:0] data_latch;

    reg [8:0] current_bank_latch;
    reg [15:0] addr_i_latch;
    reg [7:0] data_i_latch;
    reg wr_n_latch;
    reg rd_n_latch;
  
    reg cycle_done;

    
    localparam STARTUP=0, INIT_PRE=1, INIT_REF=2, INIT_MRS=3,
               IDLE=4, ACT=5, READ_WRITE=6, WAIT_CL=7, REFRESH=8, REFRESH_WAIT=9, WAIT_EXTRA=10;

    // Bidirectional Bus Logic
    wire driving_bus = (state == READ_WRITE && !wr_n);
    assign sd_dq = driving_bus ? {data_i, data_i, data_i, data_i} : 32'bz;

    // Physical static signals
    assign sd_clk   = clk_50;
    assign sd_cke   = 1'b1;
    assign sd_cs_n  = 1'b0; 

    // Z80 Read Mux
    assign data_o = (addr_i[1:0] == 2'b00) ? data_latch[7:0]   :
                      (addr_i[1:0] == 2'b01) ? data_latch[15:8]  :
                      (addr_i[1:0] == 2'b10) ? data_latch[23:16] : data_latch[31:24];

    always @(posedge clk_50 or negedge reset_n) begin
        if (!reset_n) begin
            state <= STARTUP;
            wait_cnt <= 10000; 
            wait_n <= 0;      
            {sd_ras_n, sd_cas_n, sd_we_n} <= C_NOP;
            sd_dqm <= 4'b1111;
            ref_timer <= 0;
            cycle_done <= 1'b0;
            
        end else begin
            if(mreq_n) begin
                cycle_done <= 1'b0;
            end
            
            if(state > IDLE) begin
                if(ref_timer < 390) ref_timer <= ref_timer + 1;
            end

            case (state)
                STARTUP: if (wait_cnt > 0) wait_cnt <= wait_cnt - 1; else state <= INIT_PRE;
                
                INIT_PRE: begin
                    {sd_ras_n, sd_cas_n, sd_we_n} <= C_PRE; 
                    sd_a[10] <= 1; 
                    state <= INIT_REF; wait_cnt <= 8;
                end

                INIT_REF: begin
                    {sd_ras_n, sd_cas_n, sd_we_n} <= C_REF;
                    if (wait_cnt > 0) wait_cnt <= wait_cnt - 1; else state <= INIT_MRS;
                end

                INIT_MRS: begin
                    {sd_ras_n, sd_cas_n, sd_we_n} <= C_MRS;
                    sd_a <= 11'b000_0_010_0_000; 
                    state <= IDLE;
                end

                IDLE: begin
                    wait_n <= 1;
                    
                    {sd_ras_n, sd_cas_n, sd_we_n} <= C_NOP;
                    if (ref_timer >= 390) state <= REFRESH;
                    else if (!mreq_n && ram_cs && (!rd_n || !wr_n) && !cycle_done) begin
                        // Latch input signals
                        addr_i_latch <= addr_i;
                        data_i_latch <= data_i;
                        wr_n_latch <= wr_n;
                        rd_n_latch <= rd_n;
                        wait_n <= 0;
                        state <= ACT;
                    end

                end

                REFRESH: begin
                    {sd_ras_n, sd_cas_n, sd_we_n} <= C_REF;
                    wait_cnt <= 4;
                    ref_timer <= 0;
                    if(!mreq_n && ram_cs && (!rd_n || !wr_n)) begin 
                        wait_n <= 0;
                    end
                    
                    state <= REFRESH_WAIT;
                end

                REFRESH_WAIT: begin
                    {sd_ras_n, sd_cas_n, sd_we_n} <= C_NOP;
                    if(!mreq_n && ram_cs && (!rd_n || !wr_n)) begin
                        wait_n <= 0;
                    end
                    
                    if(wait_cnt > 0) wait_cnt <= wait_cnt - 1;
                    else begin 
                        state <= IDLE;
                    end
                end

                ACT: begin
                    {sd_ras_n, sd_cas_n, sd_we_n} <= C_ACT;
                    sd_ba <= current_bank_reg[8:7]; 
                    sd_a  <= {current_bank_reg[6:0], addr_i_latch[13:10]}; 
                  
                    state <= READ_WRITE;
                end

                READ_WRITE: begin
                    {sd_ras_n, sd_cas_n, sd_we_n} <= (!rd_n_latch) ? C_RD : C_WR;
                    sd_a <= {3'b100, addr_i_latch[9:2]}; // A10=1: Auto-Precharge
                    
                    if (!wr_n) begin
                        case(addr_i_latch[1:0])
                            2'b00: sd_dqm <= 4'b1110;
                            2'b01: sd_dqm <= 4'b1101;
                            2'b10: sd_dqm <= 4'b1011;
                            2'b11: sd_dqm <= 4'b0111;
                        endcase
                    end else sd_dqm <= 4'b0000;
                    
                    wait_cnt <= 2; 
                    state <= WAIT_CL;
                end

                WAIT_CL: begin
                    {sd_ras_n, sd_cas_n, sd_we_n} <= C_NOP;
                    if (wait_cnt > 0) wait_cnt <= wait_cnt - 1;
                    else begin
                        if (!rd_n_latch) data_latch <= sd_dq; 
                        
                        cycle_done <= 1'b1;
                        state <= IDLE;
                    end
                end
                
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule