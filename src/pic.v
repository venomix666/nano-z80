// Programmable interrupt controller core for the nano-Z80
//
// Supports 8 interrupt sources
// Designed for interrupt mode 2
//
// Registers:
// 00 Interrupt enable, bitwise, active high
// 01 Interrupt flags, bitwise, read only
// 10 Interrupt 0 vector
// 11 Interrupt 1 vector
// 12 Interrupt 2 vector
// 13 Interrupt 3 vector
// 14 Interrtpt 4 vector
// 15 Interrupt 5 vector
// 16 Interrupt 6 vector
// 17 Interrupt 7 vector
//
//
// Current assigment of interrupts:
// 0: Timer
// 1: Unused
// 2: Unused
// 3: Unused
// 4: Unused
// 5: Unused
// 6: Unused
// 7: Unused

module pic(
	input               clk_i,
	input               rst_n_i,
    input               wr_n,
	input   [7:0]       reg_addr_i,
    input   [7:0]       data_i,
    input               pic_cs,
    input   [7:0]       int_n_i,
    input               ioreq_n,
    input               m1_n,
    output [7:0]        data_o,
    output reg          int_n_o,
    output              vector_output,
    output [7:0]        irq_ack_o
);

reg [7:0] interrupt_enable;
reg [7:0] interrupt_flags;
reg [7:0] interrupt_vector[0:7];

reg [7:0] data_o_reg;

// Detect interrupt acknowledge
wire int_ack = (!m1_n && !ioreq_n);

// Detect pending interrupts
wire [7:0]  irq_pending_mask = (~int_n_i & interrupt_enable);
wire irq_pending = |irq_pending_mask;

reg int_active;
reg [7:0] int_select;
reg [7:0] prio_irq;

// Select irq with higher priority only
always @(*) begin
    prio_irq = 8'h00;
    if      (irq_pending_mask[0]) prio_irq[0] = 1'b1;
    else if (irq_pending_mask[1]) prio_irq[1] = 1'b1;
    else if (irq_pending_mask[2]) prio_irq[2] = 1'b1;
    else if (irq_pending_mask[3]) prio_irq[3] = 1'b1;
    else if (irq_pending_mask[4]) prio_irq[4] = 1'b1;
    else if (irq_pending_mask[5]) prio_irq[5] = 1'b1;
    else if (irq_pending_mask[6]) prio_irq[6] = 1'b1;
    else if (irq_pending_mask[7]) prio_irq[7] = 1'b1;
end

// Set interrupt flag to the CPU if any enabled input device requests an interrupt
assign int_n_o = irq_pending ? 1'b0 : 1'b1;

// Generate vector output active signal
assign vector_output = int_ack && int_active;

// Generate irq acknowledge signal
assign irq_ack_o = (int_ack && int_active) ? int_select : 8'h00;

always @(*)
begin
        // Provide interrupt vector to data bus when needed
        if(vector_output) 
        begin
                // Lower irq numbers have higher priority
                if(int_select[0]) data_o_reg = interrupt_vector[0];
                else if (int_select[1]) data_o_reg = interrupt_vector[1];
                else if (int_select[2]) data_o_reg = interrupt_vector[2];
                else if (int_select[3]) data_o_reg = interrupt_vector[3];
                else if (int_select[4]) data_o_reg = interrupt_vector[4];
                else if (int_select[5]) data_o_reg = interrupt_vector[5];
                else if (int_select[6]) data_o_reg = interrupt_vector[6];
                else if (int_select[7]) data_o_reg = interrupt_vector[7];
        end
        else begin
            case(reg_addr_i)
                8'h00: data_o_reg = interrupt_enable;
                8'h01: data_o_reg = interrupt_flags;
                8'h10: data_o_reg = interrupt_vector[0];
                8'h11: data_o_reg = interrupt_vector[1];
                8'h12: data_o_reg = interrupt_vector[2];   
                8'h13: data_o_reg = interrupt_vector[3];
                8'h14: data_o_reg = interrupt_vector[4];
                8'h15: data_o_reg = interrupt_vector[5];
                8'h16: data_o_reg = interrupt_vector[6];
                8'h17: data_o_reg = interrupt_vector[7];
                default: data_o_reg = 8'd0;
            endcase
        end
end

always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        interrupt_enable <= 8'h00;
        interrupt_vector[0] <= 8'h00;
        interrupt_vector[1] <= 8'h00;
        interrupt_vector[2] <= 8'h00;
        interrupt_vector[3] <= 8'h00;
        interrupt_vector[4] <= 8'h00;
        interrupt_vector[5] <= 8'h00;
        interrupt_vector[6] <= 8'h00;
        interrupt_vector[7] <= 8'h00;
    end
    else if(pic_cs && !wr_n)
    begin
        case(reg_addr_i)
            8'h00: interrupt_enable <= data_i;
            8'h10: interrupt_vector[0] <= data_i;
            8'h11: interrupt_vector[1] <= data_i;
            8'h12: interrupt_vector[2] <= data_i;
            8'h13: interrupt_vector[3] <= data_i;
            8'h14: interrupt_vector[4] <= data_i;
            8'h15: interrupt_vector[5] <= data_i;
            8'h16: interrupt_vector[6] <= data_i;
            8'h17: interrupt_vector[7] <= data_i;
            default: ;
        endcase
    end
end

always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        int_active <= 1'b0;
        int_select <= 8'h00;
        interrupt_flags <= 8'h00;
    end
    else
    begin
        interrupt_flags <= ~int_n_i;
        if(irq_pending) begin
            int_active <= 1'b1;
            if(!int_active) int_select <= prio_irq;
        end
        else if(!int_ack) begin
            int_active <= 1'b0;
            int_select <= 8'h00;
        end
    end
end

assign data_o = data_o_reg;

endmodule