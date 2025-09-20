// nano-Z80
//
// A general purpose Z80 computer designed primarily for use with
// the Tang Nano 20K board.
//
// Planned features for first version:
// Text mode video output, 80 columns, over HDMI
// 64K block ram
// ROM which can be switched out
// SDCARD file access
// UART
// USB keyboard support
//
// Copyright (C) 2025 Henrik Löfgren

module nanoz80_top
(
    input           clk_i,
    input           rst_i, //S1
    input           clkusb_i,
    input           uart_rx_i,
    //input           uart_b_rx_i,
    output          uart_tx_o,
    //output          uart_b_tx_o,
    output          leds[5:0],
    output          ws2812_o,
    inout [12:0]    gpio,
    output          sdclk,
    //output            tmds_clk_p    ,
    //output            tmds_clk_n    ,
    //output     [2:0]  tmds_data_p   ,//{r,g,b}
    //output     [2:0]  tmds_data_n   ,
    inout           sdcmd,
    inout [3:0]     sddat,
    inout           usb_dp,
    inout           usb_dm
);

wire            mreq_n;
wire            ioreq_n;
wire            rd_n;
wire            wr_n;
wire    [15:0]  cpu_addr;
wire    [7:0]   cpu_data_o;
wire    [7:0]   rom_data_o;
wire    [7:0]   ram_data_o;
wire    [7:0]   uart_data_o;
wire    [7:0]   leds_data_o;
wire    [7:0]   gpio_data_o;
wire    [7:0]   usb_data_o;
wire    [7:0]   sd_data_o;
wire    [7:0]   addr_dec_data_o;

reg     [7:0]   cpu_data_i;

wire            rst_n;  // Active high reset signal
wire            rst_p;

assign rst_n = ~rst_i;
assign rst_p = rst_i;

wire            ram_cs;
wire            uart_cs;
wire            rom_cs;
wire            led_cs;
wire            gpio_cs;
wire            usb_cs;
wire            sd_cs;
wire            addr_dec_cs;

wire    [7:0]   ledwire;

assign leds[5] = ~ledwire[5];
assign leds[4] = ~ledwire[4];
assign leds[3] = ~ledwire[3];
assign leds[2] = ~ledwire[2];
assign leds[1] = ~ledwire[1];
assign leds[0] = ~ledwire[0];

tv80s CPU(
    // Outputs
    .m1_n(), 
    .mreq_n(mreq_n), 
    .iorq_n(ioreq_n), 
    .rd_n(rd_n), 
    .wr_n(wr_n), 
    .rfsh_n(), 
    .halt_n(), 
    .busak_n(), 
    .A(cpu_addr), 
    .dout(cpu_data_o),
    // Inputs
    .reset_n(rst_n), 
    .clk(clk_i), 
    .wait_n(1'b1), 
    .int_n(1'b1), 
    .nmi_n(1'b1), 
    .busrq_n(1'b1), 
    .di(cpu_data_i), 
    .cen(1'b1)
);

bootrom bootrom_inst(
    .clk(clk_i),
    .adr(cpu_addr[12:0]),
    .data(rom_data_o)
);
 
instram main_ram(
    .clk(clk_i),
    .adr(cpu_addr),
    .rwn(wr_n),
    .cs(ram_cs),
    .data_i(cpu_data_o),
    .data_o(ram_data_o)
);

uart uart_inst(
        .clk(clk_i),
        .rst_n(rst_n),
        .data_i(cpu_data_o),
        .uart_rx(uart_rx_i),
        .uart_cs(uart_cs),
        .R_W_n(wr_n),
        .reg_addr(cpu_addr[3:0]),
        .data_o(uart_data_o),
        .uart_tx(uart_tx_o)
);

addr_decoder addr_dec(
    .clk_i(clk_i),
    .rst_n_i(rst_n),
    .wr_n(wr_n),
    .addr_i(cpu_addr),
    .data_i(cpu_data_o),
    .mreq_n(mreq_n),
    .ioreq_n(ioreq_n),
    .data_o(addr_dec_data_o),
    .ram_cs(ram_cs),
    .uart_cs(uart_cs),
    .led_cs(led_cs),
    .gpio_cs(gpio_cs),
    .usb_cs(usb_cs),
    .sd_cs(sd_cs),
    .rom_cs(rom_cs),
    .addr_dec_cs(addr_dec_cs)
);

leds leds_inst(
    .clk_i(clk_i),
    .rst_n_i(rst_n),
    .wr_n(wr_n),
    .reg_addr_i(cpu_addr),
    .data_i(cpu_data_o),
    .led_cs(led_cs),
    .data_o(leds_data_o),
    .leds(ledwire),
    .ws2812(ws2812_o)
);

gpio gpio_inst(
    .clk_i(clk_i),
    .rst_n_i(rst_n),
    .wr_n(wr_n),
    .reg_addr_i(cpu_addr),
    .data_i(cpu_data_o),
    .gpio_cs(gpio_cs),
    .data_o(gpio_data_o),
    .gpio(gpio)
);

usb_interface usb_interface_inst(
    .clk_i(clk_i),
    .rst_n_i(rst_n),
    .clkusb_i(clkusb_i),
    .wr_n(wr_n),
    .reg_addr_i(cpu_addr[7:0]),
    .data_i(cpu_data_o),
    .usb_cs(usb_cs),
    .data_o(usb_data_o),
    .usb_dp(usb_dp),
    .usb_dm(usb_dm)
);

sd_interface sd_interface_inst(
    .clk_i(clk_i),
    .rst_n_i(rst_n), 
    .wr_n(wr_n),
    .reg_addr_i(cpu_addr[7:0]),
    .data_i(cpu_data_o),
    .sd_cs(sd_cs),
    .data_o(sd_data_o),
    .sdclk(sdclk),
    .sdcmd(sdcmd),
    .sddat(sddat) 
);


// CPU data input mux

always @(*) begin
        if(rom_cs == 1'b1) cpu_data_i = rom_data_o;
        else if(ram_cs == 1'b1) cpu_data_i = ram_data_o;
        else if(uart_cs == 1'b1) cpu_data_i = uart_data_o;
        else if(led_cs == 1'b1) cpu_data_i = leds_data_o;
        else if(gpio_cs == 1'b1) cpu_data_i = gpio_data_o;
        else if(usb_cs == 1'b1) cpu_data_i = usb_data_o;
        else if(sd_cs == 1'b1) cpu_data_i = sd_data_o;
        else if(addr_dec_cs == 1'b1) cpu_data_i = addr_dec_data_o;
        else cpu_data_i = cpu_data_o;
end

endmodule