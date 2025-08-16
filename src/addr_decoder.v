// nanoz80 address decoder
//
// A "register" at io-port 0xff is used to select peripherals
//
// Todo - add the possibility to switch the ROM to RAM

module addr_decoder(
    input               clk_i,
    input               rst_n_i,
    input               wr_n,
    input   [15:0]      addr_i,
    input   [7:0]       data_i,
    input               mreq_n,
    input               ioreq_n,
    output  [7:0]       data_o,
    output              ram_cs,
    output              uart_cs,
    output              rom_cs,
    output              addr_dec_cs
);

reg [7:0]   io_bank;
reg [7:0]   dummy_reg;
reg [7:0]   data_o_reg;
reg         ram_cs_reg;
reg         uart_cs_reg;
reg         rom_cs_reg;
reg         addr_dec_cs_reg;


// Register writing
always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        io_bank <= 8'd0;
    end
    else if(wr_n == 1'b0 && ioreq_n == 1'b0)
    case(addr_i[7:0])
        8'hff: io_bank <= data_i;
        default: dummy_reg <= data_i;
    endcase
end

// Address decoding
always @(*) begin
    // Default values
    data_o_reg <= 8'd0;
    ram_cs_reg <= 1'b0;
    rom_cs_reg <= 1'b0;
    uart_cs_reg <= 1'b0;
    addr_dec_cs_reg <= 1'b0;

    // Memory requests
    if(mreq_n == 1'b0 && addr_i[15] == 1'b0) rom_cs_reg <= 1'b1;
    if(mreq_n == 1'b0 && addr_i[15] == 1'b1) ram_cs_reg <= 1'b1;

    // IO requests
    if(ioreq_n == 1'b0)
    begin
        case(io_bank)
            8'h00: uart_cs_reg <= 1'b1;
            default: uart_cs_reg <= 1'b0;
        endcase
    end
end

assign data_o = data_o_reg;
assign ram_cs = ram_cs_reg;
assign uart_cs = uart_cs_reg;
assign rom_cs = rom_cs_reg;
assign addr_dec_cs = addr_dec_cs_reg;

endmodule
