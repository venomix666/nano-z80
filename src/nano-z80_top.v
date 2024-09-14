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
// Copyright (C) 2024 Henrik Löfgren

module nano6502_top
(
    input           clk_i,
    input           rst_i, //S1
    //input           clkusb_i,
    input           uart_rx_i,
    //input           uart_b_rx_i,
    output          uart_tx_o
    //output          uart_b_tx_o,
    //output          leds[5:0],
    //output          ws2812_o,
    //output          sdclk,
    //output            tmds_clk_p    ,
    //output            tmds_clk_n    ,
    //output     [2:0]  tmds_data_p   ,//{r,g,b}
    //output     [2:0]  tmds_data_n   ,
    //inout           sdcmd,
    //inout [3:0]     sddat,
    //inout           usb_dp,
    //inout           usb_dm
);



endmodule