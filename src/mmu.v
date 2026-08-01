// Very simple MMU core for the nano-Z80
//
// The memory is segmented into 4 16k regions which each can point to one of 512 pages
// for a total of 8192k of RAM
//
// Address ranges:
// Region 0 - 0x0000 to 0x3FFF
// Region 1 - 0x4000 to 0x7FFF
// Region 2 - 0x8000 to 0xBFFF
// Region 3 - 0xC000 to 0xFFFF
//
// Registers:
// 60 - region 0 page LSB (defaults to 00000000)
// 61 - region 0 page MSB (defaults to 0)
// 62 - region 1 page LSB (defaults to 00000001)
// 63 - region 1 page MSB (defaults to 0)
// 64 - region 2 page LSB (defaults to 00000010)
// 65 - region 2 page MSB (defaults to 0)
// 66 - region 3 page LSB (defaults to 00000011)
// 67 - region 3 page MSB (defaults to 0)
// 68 - Enable fixed region above 0xf000

module mmu(
	input               clk_i,
	input               rst_n_i,
    input               wr_n,
	input   [3:0]       reg_addr_i,
    input   [7:0]       data_i,
    input  [15:0]       addr_i,
    input               mmu_cs,
    output  [7:0]       data_o,
    output [8:0]       high_addr_o
);

reg [7:0]       data_o_reg;
reg [8:0]       high_addr_reg;

reg [8:0]       page_0;
reg [8:0]       page_1;
reg [8:0]       page_2;
reg [8:0]       page_3;
reg             fixed_page;

always @(*)
begin
        case(reg_addr_i)
            4'b0000: data_o_reg = page_0[7:0];
            4'b0001: data_o_reg = {7'd0, page_0[8]};
            4'b0010: data_o_reg = page_1[7:0];
            4'b0011: data_o_reg = {7'd0, page_1[8]};
            4'b0100: data_o_reg = page_2[7:0];
            4'b0101: data_o_reg = {7'd0, page_2[8]};
            4'b0110: data_o_reg = page_3[7:0];
            4'b0111: data_o_reg = {7'd0, page_3[8]};
            4'b1000: data_o_reg = {7'd0, fixed_page};
            default: data_o_reg = 8'd0;
        endcase
end

always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        page_0 <= 9'd0;
        page_1 <= 9'd1;
        page_2 <= 9'd2;
        page_3 <= 9'd3;
        fixed_page <= 1'd0;
    end
    else if(mmu_cs && !wr_n)
    begin
        case(reg_addr_i)
            4'b0000: page_0[7:0] <= data_i;
            4'b0001: page_0[8] <= data_i[0];
            4'b0010: page_1[7:0] <= data_i;
            4'b0011: page_1[8] <= data_i[0];
            4'b0100: page_2[7:0] <= data_i;
            4'b0101: page_2[8] <= data_i[0];
            4'b0110: page_3[7:0] <= data_i;
            4'b0111: page_3[8] <= data_i[0];
            4'b1000: fixed_page <= data_i[0];
        endcase
    end
end

//assign high_addr_o = {page[addr_i[15:14]]};
always @(*)
begin
    case(addr_i[15:14])
        2'b00: high_addr_reg = page_0;
        2'b01: high_addr_reg = page_1;
        2'b10: high_addr_reg = page_2;
        2'b11: begin
            if(addr_i[15:12] == 4'b1111 && fixed_page == 1'b1) high_addr_reg = 9'd3;
            else high_addr_reg = page_3;
        end
        default: high_addr_reg = 9'd0;
    endcase
end
assign data_o = data_o_reg;
assign high_addr_o = high_addr_reg;
endmodule
