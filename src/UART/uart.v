module uart(
	input                        clk,
	input                        rst_n,
    input       [7:0]            data_i,
	input                        uart_rx,
    input                        uart_cs,
    input                        uart_b_rx,
    input                        R_W_n,
    input       [7:0]            reg_addr,
    output      [7:0]            data_o,
    output                       uart_a_rx_irq_n_o,
    output                       uart_b_rx_irq_n_o,
	output                       uart_tx,
    output                       uart_b_tx
);

/*
0xfe00: TX data - write to initiate transmission
0xfe01: TX ready - UART is ready to accept a new TX byte
0xfe02: RX data
0xfe03: RX data available - high if a new byte is available in RX data
0xfe04: TX data B
0xfe05: TX ready B
0xfe06: RX data B
0xfe07: RX data available B
0xfe08: UART B baud rate
*/

parameter                        CLK_FRE  = 25.175;//Mhz
parameter                        UART_FRE = 115200;
parameter                        UART_B_FRE = 57600;

reg[7:0]                         tx_data;

reg                              tx_data_valid;
wire                             tx_data_ready;

reg[7:0]                         tx_b_data;

reg                              tx_b_data_valid;
wire                             tx_b_data_ready;

wire[7:0]                        rx_data;
reg [7:0]                        rx_data_reg;
reg                              rx_data_avail;
wire                             rx_data_valid;
wire                             rx_data_ready;

wire[7:0]                        rx_b_data;
reg [7:0]                        rx_b_data_reg;
reg                              rx_b_data_avail;
wire                             rx_b_data_valid;
wire                             rx_b_data_ready;

assign rx_data_ready = 1'b1;//always can receive data,
assign rx_b_data_ready = 1'b1;

assign uart_a_rx_irq_n_o = ~rx_data_avail;
assign uart_b_rx_irq_n_o = ~rx_b_data_avail;

// Registers for CPU interface

reg                             rx_avail;
reg                             tx_done;
reg [7:0]                       data_o_reg;

reg                             rx_b_avail;
reg                             tx_b_done;
reg [7:0]                       data_b_o_reg;
reg [2:0]                       uart_b_baud;

// RX buffers and index

reg [7:0]                       rx_buffer [255:0];
reg [7:0]                       rx_buffer_r;
reg [7:0]                       rx_buffer_w;

reg [7:0]                       rx_buffer_b [255:0];
reg [7:0]                       rx_buffer_b_r;
reg [7:0]                       rx_buffer_b_w;

reg                             uart_cs_prev;
reg                             uart_cs_prev2;
reg [7:0]                       reg_addr_prev;

always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
    begin
        tx_data <= 8'h00;
        tx_done <= 1'b1;
        tx_data_valid <= 1'b0;        
    end
    // TX handling
    else if(tx_data_valid && tx_data_ready) 
    begin
        tx_done <= 1'b1; 
        tx_data_valid <= 1'b0;
    end
    else if(uart_cs)
    begin
        if((reg_addr==8'h00 || reg_addr==8'h70) && !R_W_n)
        begin
                tx_done <= 1'b0;
                tx_data <= data_i;
                tx_data_valid <= 1'b1;
        end
    end
    else
    begin
        tx_data_valid <= 1'b0;
    end 
end

always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
    begin
        tx_b_data <= 8'h00;
        tx_b_done <= 1'b1;
        tx_b_data_valid <= 1'b0;
        uart_b_baud <= 3'd4; // 57600 default baudrate
    end
    // TX handling
    else if(tx_b_data_valid && tx_b_data_ready) 
    begin
        tx_b_done <= 1'b1; 
        tx_b_data_valid <= 1'b0;
    end
    else if(uart_cs)
    begin
        if(reg_addr==8'b00000100 && !R_W_n)
        begin
                tx_b_done <= 1'b0;
                tx_b_data <= data_i;
                tx_b_data_valid <= 1'b1;
        end
        else if(reg_addr==8'b00001000 && !R_W_n)
        begin
            uart_b_baud <= data_i[2:0];
        end
    end
    else
    begin
        tx_b_data_valid <= 1'b0;
    end
    
end

always@(*)
begin
        case (reg_addr)
            8'b00000000: data_o_reg <= tx_data;
            8'b00000001: data_o_reg <= {7'd0, tx_data_ready};
            8'b00000010: data_o_reg <= rx_data_reg;
            8'b00000011: data_o_reg <= {7'd0, rx_data_avail}; 
            8'b00000100: data_o_reg <= tx_b_data;
            8'b00000101: data_o_reg <= {7'd0, tx_b_data_ready};
            8'b00000110: data_o_reg <= rx_b_data_reg;
            8'b00000111: data_o_reg <= {7'd0, rx_b_data_avail};
            8'b00001000: data_o_reg <= {5'd0, uart_b_baud};
            8'b00001001: data_o_reg <= rx_buffer_b_r;
            8'b00001010: data_o_reg <= rx_buffer_b_w;
            8'b00001011: data_o_reg <= rx_buffer_r;
            8'b00001100: data_o_reg <= rx_buffer_w;
            8'h70: data_o_reg <= tx_data;
            8'h71: data_o_reg <= {7'd0, tx_data_ready};
            8'h72: data_o_reg <= rx_data_reg;
            8'h73: data_o_reg <= {7'd0, rx_data_avail};

            default: data_o_reg <= 8'd0;
        endcase
end

always@(posedge clk)
begin
    if(rst_n == 1'b0) begin
        uart_cs_prev <= 1'b0;
    end
    else begin
        uart_cs_prev <= uart_cs;
    end
end

always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
    begin
        rx_data_reg <= 8'd0;
        //rx_data_avail <= 1'b0;
        rx_buffer_r <= 8'd0;
        rx_buffer_w <= 8'd0;
    end
    // Latch rx data and status
    else if(rx_data_valid)
    begin
        rx_buffer[rx_buffer_w] <= rx_data;
        rx_buffer_w <= rx_buffer_w + 1;
    end
    else if((reg_addr == 8'b00000010 || reg_addr == 8'h72) && (uart_cs) && (!uart_cs_prev) && (rx_data_avail))
    begin
        rx_data_reg <= rx_buffer[rx_buffer_r];
        rx_buffer_r <= rx_buffer_r + 1;
    end
end

assign rx_data_avail = (rx_buffer_r != rx_buffer_w);

always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
    begin
        rx_b_data_reg <= 8'd0;
        rx_buffer_b_r <= 8'd0;
        rx_buffer_b_w <= 8'd0;
    end
    // Latch rx data and status
    else if(rx_b_data_valid)
    begin
        rx_buffer_b[rx_buffer_b_w] <= rx_b_data;
        rx_buffer_b_w <= rx_buffer_b_w + 1;
    end
    else if((reg_addr == 8'b00000110) && (uart_cs) && (!uart_cs_prev) && (rx_b_data_avail))
    begin
        rx_b_data_reg <= rx_buffer_b[rx_buffer_b_r];
        rx_buffer_b_r <= rx_buffer_b_r + 1;
    end

end

assign rx_b_data_avail = (rx_buffer_b_r != rx_buffer_b_w);

assign data_o = data_o_reg;

uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.rx_data                    (rx_data                  ),
	.rx_data_valid              (rx_data_valid            ),
	.rx_data_ready              (rx_data_ready            ),
	.rx_pin                     (uart_rx                  )
);

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);

// Instantiate UART B
uart_rx_flex#
(
	.CLK_FRE(CLK_FRE)
) uart_rx_inst_b
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.rx_data                    (rx_b_data                  ),
	.rx_data_valid              (rx_b_data_valid            ),
	.rx_data_ready              (rx_b_data_ready            ),
	.rx_pin                     (uart_b_rx                  ),
    .baudrate                   (uart_b_baud                )
);

uart_tx_flex#
(
	.CLK_FRE(CLK_FRE)
) uart_tx_inst_b
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_b_data                  ),
	.tx_data_valid              (tx_b_data_valid            ),
    .baudrate                   (uart_b_baud                ),
	.tx_data_ready              (tx_b_data_ready            ),
	.tx_pin                     (uart_b_tx                  )
);
endmodule