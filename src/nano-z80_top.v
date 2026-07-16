// nano-Z80
//
// A general purpose Z80 computer designed primarily for use with
// the Tang Nano 20K board.
//
// Features:
// Text mode video output, 80 columns, or graphics (160x120x8 or 320x200x8) over HDMI
// 8192k of SDRAM ram, divided into four pageable regions
// ROM which can be switched out
// SDCARD file access
// UART
// USB keyboard support
// Programmable interrupt controller
//
// Copyright (C) 2026 Henrik Löfgren

module nanoz80_top
(
    input           clk_i,
    input           rst_i, //S1
    input           clkusb_i,
    input           uart_rx_i,
    input           uart_b_rx_i,
    output          uart_tx_o,
    output          uart_b_tx_o,
    output          leds[5:0],
    output          ws2812_o,
    inout [12:0]    gpio,
    output          sdclk,
    output            tmds_clk_p    ,
    output            tmds_clk_n    ,
    output     [2:0]  tmds_data_p   ,//{r,g,b}
    output     [2:0]  tmds_data_n   ,
    inout           sdcmd,
    inout [3:0]     sddat,
    inout           usb_dp,
    inout           usb_dm,
    // Magic SDRAM pin names
    output O_sdram_clk,                                                        
    output O_sdram_cke,                                                        
    output O_sdram_cs_n,            // chip select                             
    output O_sdram_cas_n,           // columns address select                  
    output O_sdram_ras_n,           // row address select                      
    output O_sdram_wen_n,           // write enable                            
    inout [31:0] IO_sdram_dq,       // 32 bit bidirectional data bus           
    output [10:0] O_sdram_addr,     // 11 bit multiplexed address bus          
    output [1:0] O_sdram_ba,        // two banks                               
    output [3:0] O_sdram_dqm        // 32/4        
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
wire    [7:0]   video_data_o;
wire    [7:0]   mmu_data_o;
wire    [7:0]   pic_data_o;
wire    [7:0]   timer_data_o;
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
wire            video_cs;
wire            mmu_cs;
wire            pic_cs;
wire            timer_cs;
wire            addr_dec_cs;

wire    [7:0]   ledwire;

assign leds[5] = ~ledwire[5];
assign leds[4] = ~ledwire[4];
assign leds[3] = ~ledwire[3];
assign leds[2] = ~ledwire[2];
assign leds[1] = ~ledwire[1];
assign leds[0] = ~ledwire[0];

wire   [8:0]    high_addr;

// SDRAM clocks
wire clk50;
wire clk50_p;

// PLL to generate SDRAM clocks
Gowin_rPLL sdram_pll(
        .clkout(clk50), //output clkout
        .clkoutp(clk50_p), //output clkoutp
        .clkin(clk_i) //input clkin
);

wire wait_n;

// Interrupt controller signals
wire m1_n;
wire int_n;
wire vector_output;
wire [7:0] irq_ack;
wire timer_irq_n;
wire kb_irq_n;
wire uart_a_rx_irq_n;
wire uart_b_rx_irq_n;

tv80s CPU(
    // Outputs
    .m1_n(m1_n), 
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
    .wait_n(wait_n), 
    .int_n(int_n), 
    .nmi_n(1'b1), 
    .busrq_n(1'b1), 
    .di(cpu_data_i), 
    .cen(1'b1)
);

pic pic_inst(
    .clk_i(clk_i),
    .rst_n_i(rst_n),
    .wr_n(wr_n),
    .reg_addr_i(cpu_addr[7:0]),
    .data_i(cpu_data_o),
    .pic_cs(pic_cs),
    .int_n_i({4'b1111, uart_b_rx_irq_n, uart_a_rx_irq_n, kb_irq_n, timer_irq_n}),
    .ioreq_n(ioreq_n),
    .m1_n(m1_n),
    .data_o(pic_data_o),
    .int_n_o(int_n),
    .vector_output(vector_output),
    .irq_ack_o(irq_ack)
);

timer timer_inst(
    .clk_i(clk_i),
    .rst_n_i(rst_n),
    .wr_n(wr_n),
    .reg_addr_i(cpu_addr),
    .data_i(cpu_data_o),
    .timer_cs(timer_cs),
    .irq_ack(irq_ack[0]),
    .data_o(timer_data_o),
    .timer_irq_n_o(timer_irq_n)
);


bootrom bootrom_inst(
    .clk(clk_i),
    .adr(cpu_addr[12:0]),
    .data(rom_data_o)
);
 
sdram_z80_interface sdram_z80_interface_inst(
    .clk_50(clk50),
    .reset_n(rst_n),
    .addr_i(cpu_addr),
    .data_i(cpu_data_o),
    .data_o(ram_data_o),
    .mreq_n(mreq_n),
    .rd_n(rd_n),
    .wr_n(wr_n),
    .wait_n(wait_n),
    .ram_cs(ram_cs),


    .sd_clk(O_sdram_clk),                                        
    .sd_cke(O_sdram_cke),                                                 
    .sd_cs_n(O_sdram_cs_n),                                               
    .sd_cas_n(O_sdram_cas_n),                                             
    .sd_ras_n(O_sdram_ras_n),                                             
    .sd_we_n(O_sdram_wen_n),                                             
    .sd_dqm(O_sdram_dqm),                                                 
    .sd_a(O_sdram_addr),                                               
    .sd_ba(O_sdram_ba),                                                   
    .sd_dq(IO_sdram_dq),

    .current_bank_reg(high_addr)
);
         
                                                                  
mmu mmu_inst(                                                                  
    .clk_i(clk_i),                                                             
    .rst_n_i(rst_n),                                                           
    .wr_n(wr_n),                                                               
    .reg_addr_i(cpu_addr[2:0]),                                                
    .data_i(cpu_data_o),                                                       
    .addr_i(cpu_addr),                                                         
    .mmu_cs(mmu_cs),                                                           
    .data_o(mmu_data_o),                                                       
    .high_addr_o(high_addr)                                                    
);  

uart uart_inst(
        .clk(clk_i),
        .rst_n(rst_n),
        .data_i(cpu_data_o),
        .uart_rx(uart_rx_i),
        .uart_b_rx(uart_b_rx_i),
        .uart_cs(uart_cs),
        .R_W_n(wr_n),
        .reg_addr(cpu_addr),
        .data_o(uart_data_o),
        .uart_a_rx_irq_n_o(uart_a_rx_irq_n),
        .uart_b_rx_irq_n_o(uart_b_rx_irq_n),
        .uart_tx(uart_tx_o),
        .uart_b_tx(uart_b_tx_o)
);

addr_decoder addr_dec(
    .clk_i(clk_i),
    .rst_n_i(rst_n),
    .wr_n(wr_n),
    .addr_i(cpu_addr),
    .data_i(cpu_data_o),
    .mreq_n(mreq_n),
    .ioreq_n(ioreq_n),
    .m1_n(m1_n),
    .data_o(addr_dec_data_o),
    .ram_cs(ram_cs),
    .uart_cs(uart_cs),
    .led_cs(led_cs),
    .gpio_cs(gpio_cs),
    .usb_cs(usb_cs),
    .sd_cs(sd_cs),
    .rom_cs(rom_cs),
    .video_cs(video_cs),
    .mmu_cs(mmu_cs),
    .pic_cs(pic_cs),
    .timer_cs(timer_cs),
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
    .kb_int_n_o(kb_irq_n),
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

video video_inst(
    .clk_i(clk_i),
    .clk_vid_i(clk_i),
    .rst_n_i(rst_n),
    .R_W_n(wr_n),
    .reg_addr_i(cpu_addr[7:0]),
    .reg_addr_r_i(cpu_addr[7:0]),
    .data_i(cpu_data_o),
    .video_cs(video_cs),
    .data_o(video_data_o),
    .tmds_clk_p_o(tmds_clk_p),
    .tmds_clk_n_o(tmds_clk_n),
    .tmds_data_p_o(tmds_data_p),
    .tmds_data_n_o(tmds_data_n)
);


// CPU data input mux

always @(*) begin
        if(vector_output == 1'b1) cpu_data_i = pic_data_o;
        else if(rom_cs == 1'b1) cpu_data_i = rom_data_o;
        else if(ram_cs == 1'b1) cpu_data_i = ram_data_o;
        else if(uart_cs == 1'b1) cpu_data_i = uart_data_o;
        else if(led_cs == 1'b1) cpu_data_i = leds_data_o;
        else if(gpio_cs == 1'b1) cpu_data_i = gpio_data_o;
        else if(usb_cs == 1'b1) cpu_data_i = usb_data_o;
        else if(sd_cs == 1'b1) cpu_data_i = sd_data_o;
        else if(video_cs == 1'b1) cpu_data_i = video_data_o;
        else if(mmu_cs == 1'b1) cpu_data_i = mmu_data_o;
        else if(pic_cs == 1'b1) cpu_data_i = pic_data_o;
        else if(timer_cs == 1'b1) cpu_data_i = timer_data_o;
        else if(addr_dec_cs == 1'b1) cpu_data_i = addr_dec_data_o;
        else cpu_data_i = cpu_data_o;
end

endmodule