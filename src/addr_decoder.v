// nanoz80 address decoder
//
// A register at io-port 0x7f (may be moved?) is used to select peripherals
// Port 0x7e (may be moved?) contains a register to disable the ROM for a full 64K of RAM
// UART is always mapped to ports 0x70, 0x71, 0x72, 0x73 to avoid interference
// with other peripherals during monitor and debug prints etc.
// The idea is to leave 128 continous ports for sector transfers [0x80 - 0xFF]
// It remains to be seen if this is a good idea however... DMA?

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
    output              led_cs,
    output              gpio_cs,
    output              addr_dec_cs
);

reg [7:0]   io_bank;
reg [7:0]   dummy_reg;
reg [7:0]   data_o_reg;
reg         ram_cs_reg;
reg         uart_cs_reg;
reg         rom_cs_reg;
reg         led_cs_reg;
reg         gpio_cs_reg;
reg         addr_dec_cs_reg;
reg         rom_disable;

// Register writing
always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        io_bank <= 8'd0;
        rom_disable <= 1'd0;
    end
    else if(wr_n == 1'b0 && ioreq_n == 1'b0)
    case(addr_i[7:0])
        8'h7f: io_bank <= data_i;
        8'h7e: rom_disable <= data_i[0];
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
    led_cs_reg <= 1'b0;
    gpio_cs_reg <= 1'b0;
    addr_dec_cs_reg <= 1'b0;

    // Memory requests
    if(mreq_n == 1'b0 && addr_i < 16'h2000 && rom_disable == 1'b0) rom_cs_reg <= 1'b1;
    else if(mreq_n == 1'b0) ram_cs_reg <= 1'b1;

    // IO requests
    if(ioreq_n == 1'b0 && (addr_i[7:0] < 8'h70 || addr_i[7:0] > 8'h7f))
    begin
        case(io_bank)
            8'h00: led_cs_reg <= 1'b1;
            8'h01: gpio_cs_reg <= 1'b1;
            default: led_cs_reg <= 1'b0;
        endcase
    end
    else if(ioreq_n == 1'b0 && addr_i[7:0] > 8'h6f && addr_i[7:0] < 8'h74)
        uart_cs_reg <= 1'b1;
    else if(ioreq_n == 1'b0 && addr_i[7:0] > 8'h73 && addr_i[7:0] < 8'h80)
        addr_dec_cs_reg <= 1'b1;

    // Reading of internal registers
    if(ioreq_n == 1'b0)
    begin
        case(addr_i[7:0])
            8'h7e: data_o_reg <= {7'd0, rom_disable};
            8'h7f: data_o_reg <= io_bank;
            default: data_o_reg <= 8'd0;
        endcase
    end
end

assign data_o = data_o_reg;
assign ram_cs = ram_cs_reg;
assign uart_cs = uart_cs_reg;
assign led_cs = led_cs_reg;
assign gpio_cs = gpio_cs_reg;
assign rom_cs = rom_cs_reg;
assign addr_dec_cs = addr_dec_cs_reg;

endmodule
