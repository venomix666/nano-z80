// Simple timer core for the nano-Z80
//
// Counts up once per millisecond from a set value
// Generates timer interrupt and resets counter when compare value is reached
// Default frequency is 100 Hz
// 
// Registers:
// 00       Timer running (0 stopped, 1 running)
// 01       Timer compare value in milliseconds LSB
// 02       Timer compare value in milliseconds MSB
// 03       Timer current milliseconds LSB (read only)
// 04       Timer current milliseonds MSB (read only)

module timer(
	input               clk_i,
	input               rst_n_i,
    input               wr_n,
	input   [2:0]       reg_addr_i,
    input   [7:0]       data_i,
    input               timer_cs,
    input               irq_ack,
    output  [7:0]       data_o,
    output              timer_irq_n_o
);
parameter CLK_FRE               = 25_175_000; 
parameter TIMER_MS_DELAY        = (CLK_FRE / 1_000); // Millisecond delay

reg [7:0]   data_o_reg;

reg [14:0]  timer_sub;

reg [15:0]  timer_ms;

reg [15:0]  timer_set_ms;

reg timer_run;

reg irq_n;

// Register reading
always @(*)
begin
        case(reg_addr_i)
            3'b000: data_o_reg = {7'd0, timer_run};
            3'b001: data_o_reg = timer_set_ms[7:0];
            3'b010: data_o_reg = timer_set_ms[15:8];
            3'b011: data_o_reg = timer_ms[7:0];
            3'b100: data_o_reg = timer_ms[15:8];
            default: data_o_reg = 8'd0;
        endcase
end

// Register writing
always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        timer_run <= 1'b0;
        // Default timer tick is 10 ms / 100 Hz
        timer_set_ms[7:0] <= 8'd10;
        timer_set_ms[15:8] <= 8'd0;
    end
    else if(timer_cs && !wr_n)
    begin
        case(reg_addr_i)
            3'b000: timer_run <= data_i[0];
            3'b001: timer_set_ms[7:0] <= data_i;
            3'b010: timer_set_ms[15:8] <= data_i;
            default: ;
        endcase
    end
end

// Timer logic
always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        timer_sub <= 15'd0;
        timer_ms <= 16'd0;
        irq_n <= 1'b1;
    end
    else
    begin
        if(timer_run) begin
            if(irq_ack) irq_n <= 1'b1;

            if(timer_sub == TIMER_MS_DELAY) begin
                    timer_sub <= 15'd0;
                    timer_ms <= timer_ms + 1;
            end
            else
                timer_sub <= timer_sub + 1;

            if(timer_ms == timer_set_ms) begin
                timer_ms <= 16'd0;
                if(!irq_ack) irq_n <= 1'b0;
            end
            
           
        end
        else begin
            // Reset timer if stopped
            timer_sub <= 15'd0;
            timer_ms <= 15'd0;
            irq_n <= 1'b1;
        end
    end
end

assign data_o = data_o_reg;
assign timer_irq_n_o = irq_n;

endmodule