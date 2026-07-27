module fontrom(clk, adr, data);
	input clk;
	input [11:0] adr;
	output [7:0] data;
	reg [7:0] data; 
	reg [7:0] mem [4096];
	initial $readmemh("fontrom_8bit.hex", mem);
	always @(posedge clk) data <= mem[adr];
endmodule
