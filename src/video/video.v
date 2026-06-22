// Video generation for the nano-Z80
//
// Sync generation is based on the example from Gowin Semi.
//
// Registers:
// 00       - Line (selects which line is avaible at FE80-FECF)
// 01       - Cursor X
// 02       - Cursor Y
// 03       - Cursor visible
// 04       - Scroll up strobe
// 05       - Scroll down strobe
// 06       - tty write character
// 07       - tty busy flag
// 08       - Clear to EOL strobe
// 09       - Clear screen strobe
// 0A       - Clear to EOS strobe
// 0B       - Delete line strobe
// 0C       - Insert line strobe
// 0D (0A)  - tty output enabled
// 0E (0B)  - Autoscroll and line change enabled
// 10       - FG Red
// 11       - FG Green
// 12       - FG Blue
// 13       - BG Red
// 14       - BG Green
// 15       - BG Blue
// 20       - Video mode (0: 640x480 80 column text, 1: 160x120 8-bit graphics, 2 and 3 not implemented)
// 21       - Pixel Y (Page 2 starts on line 120 in 160x120)
// 22       - Pixel X LSB
// 23       - Pixel X MSB (ignored in 160x120 mode, in place for future support for hi-res modes)
// 24       - Pixel data (auto-increments on write)
// 25       - Video page (0 or 1), only used in 160x120 graphics for double buffering
// 26       - Palette color (0-255)
// 27       - Palette R
// 28       - Palette G
// 29       - Palette B
// 2A       - Vblank, output only, for sync
// 80-CF    - Line data

// 640x480 info:
/*  
    Horizontal Timings
    Active Pixels        640
    Front Porch           16
    Sync Width            96
    Back Porch            48
    Blanking Total       160
    Total Pixels         800
    Sync Polarity        neg

    Vertical Timings
    Active Lines         480
    Front Porch           10
    Sync Width             2
    Back Porch            33
    Blanking Total        45
    Total Lines          525
    Sync Polarity        neg
*/

module video(
    input               clk_vid_i,
    input               clk_i,
	input               rst_n_i,
    input               R_W_n,
	input   [7:0]       reg_addr_i,
    input   [7:0]       reg_addr_r_i,
    input   [7:0]       data_i,
    input               video_cs,
    output  [7:0]       data_o,
    output              tmds_clk_p_o,
    output              tmds_clk_n_o,
    output [2:0]        tmds_data_p_o,
    output [2:0]        tmds_data_n_o
);

// Parameters for 640x480 60Hz with 25.175 MHz clock
localparam      I_h_total       = 12'd800;
localparam      I_h_sync        = 12'd96;
localparam      I_h_bporch      = 12'd48;
localparam      I_h_res         = 12'd640;
localparam      I_v_total       = 12'd525;
localparam      I_v_sync        = 12'd2;
localparam      I_v_bporch      = 12'd33;
localparam      I_v_res         = 12'd480;
localparam      I_hs_pol        = 1'd0;
localparam      I_vs_pol        = 1'd0;
//localparam      char            = 7'h30;

localparam  [3:0]   IDLE = 4'd0,
                    WRITE_CHAR = 4'd1,
                    CLEAR_TO_EOL_INIT = 4'd2,
                    CLEAR_TO_EOL_RUN = 4'd3,
                    MOVE_CURSOR_X = 4'd4,
                    MOVE_CURSOR_Y = 4'd5,
                    CLEAR_SCREEN_INIT = 4'd6,
                    CLEAR_SCREEN_RUN = 4'd7,
                    CLEAR_TO_EOS_INIT = 4'd8,
                    CLEAR_TO_EOS_RUN = 4'd9,
                    DELETE_LINE_INIT = 4'd10,
                    DELETE_LINE_RUN = 4'd11,
                    COPY_LINE = 4'd12,
                    INSERT_LINE_INIT = 4'd13,
                    INSERT_LINE_RUN = 4'd14;

localparam N = 5; //delay N clocks

reg  [11:0]   V_cnt     ;
reg  [11:0]   H_cnt     ;
              
wire          Pout_de_w    ;                          
wire          Pout_hs_w    ;
wire          Pout_vs_w    ;

reg  [N-1:0]  Pout_de_dn   ;                          
reg  [N-1:0]  Pout_hs_dn   ;
reg  [N-1:0]  Pout_vs_dn   ;

//----------------------------
wire 		  De_pos;
wire 		  De_neg;
wire 		  Vs_pos;
	
reg  [11:0]   De_vcnt     ;
reg  [11:0]   De_hcnt     ;
reg  [11:0]   De_hcnt_d1  ;
reg  [11:0]   De_hcnt_d2  ;

reg dvi_hs;
reg dvi_vs;
reg dvi_oe;

//==============================================================================
//Generate HS, VS, DE signals
always@(posedge clk_vid_i or negedge rst_n_i)
begin
	if(!rst_n_i)
		V_cnt <= 12'd0;
	else     
		begin
			if((V_cnt >= (I_v_total-1'b1)) && (H_cnt >= (I_h_total-1'b1)))
				V_cnt <= 12'd0;
			else if(H_cnt >= (I_h_total-1'b1))
				V_cnt <=  V_cnt + 1'b1;
			else
				V_cnt <= V_cnt;
		end
end

//-------------------------------------------------------------    
always @(posedge clk_vid_i or negedge rst_n_i)
begin
	if(!rst_n_i)
		H_cnt <=  12'd0; 
	else if(H_cnt >= (I_h_total-1'b1))
		H_cnt <=  12'd0 ; 
	else 
		H_cnt <=  H_cnt + 1'b1 ;           
end

//-------------------------------------------------------------
assign  Pout_de_w = ((H_cnt>=(I_h_sync+I_h_bporch))&(H_cnt<=(I_h_sync+I_h_bporch+I_h_res-1'b1)))&
                    ((V_cnt>=(I_v_sync+I_v_bporch))&(V_cnt<=(I_v_sync+I_v_bporch+I_v_res-1'b1))) ;
assign  Pout_hs_w =  ~((H_cnt>=12'd0) & (H_cnt<=(I_h_sync-1'b1))) ;
assign  Pout_vs_w =  ~((V_cnt>=12'd0) & (V_cnt<=(I_v_sync-1'b1))) ;  

//-------------------------------------------------------------
always@(posedge clk_vid_i or negedge rst_n_i)
begin
	if(!rst_n_i)
		begin
			Pout_de_dn  <= {N{1'b0}};                          
			Pout_hs_dn  <= {N{1'b1}};
			Pout_vs_dn  <= {N{1'b1}}; 
		end
	else 
		begin
			Pout_de_dn  <= {Pout_de_dn[N-2:0],Pout_de_w};                          
			Pout_hs_dn  <= {Pout_hs_dn[N-2:0],Pout_hs_w};
			Pout_vs_dn  <= {Pout_vs_dn[N-2:0],Pout_vs_w}; 
		end
end

assign dvi_de = Pout_de_dn[4];

always@(posedge clk_vid_i or negedge rst_n_i)
begin
	if(!rst_n_i)
		begin                        
			dvi_hs  <= 1'b1;
			dvi_vs  <= 1'b1; 
		end
	else 
		begin                         
			dvi_hs  <= I_hs_pol ? ~Pout_hs_dn[3] : Pout_hs_dn[3] ;
			dvi_vs  <= I_vs_pol ? ~Pout_vs_dn[3] : Pout_vs_dn[3] ;
		end
end

// CPU interface
reg     [7:0]   data_o_reg;
reg     [7:0]   data_i_delay;
reg     [7:0]   data_i_d_delay;
reg     [4:0]   line;
reg     [6:0]   cursor_x;
reg     [6:0]   cursor_x_pre;
reg             cursor_x_strobe;
reg     [4:0]   cursor_y;
reg     [4:0]   cursor_y_pre;
reg             cursor_y_strobe;
reg             cursor_visible;
reg     [23:0]  cursor_cnt;
reg             scroll_up;
reg             scroll_down;
reg             tty_write_strobe;
reg             clear_to_eol_strobe;
reg             clear_screen_strobe;
reg             clear_to_eos_strobe;
reg             delete_line_strobe;
reg             insert_line_strobe;
reg             tty_enabled;
reg             scroll_enabled;
reg     [6:0]   source_line;
reg     [6:0]   dest_line;
reg             copy_write;
wire            cursor_active;

reg     [7:0]   fg_r;
reg     [7:0]   fg_g;
reg     [7:0]   fg_b;
reg     [7:0]   bg_r;
reg     [7:0]   bg_g;
reg     [7:0]   bg_b;


reg     [1:0]   video_mode;


always @(posedge clk_i) data_i_delay <= data_i;
always @(posedge clk_i) data_i_d_delay <= data_i_delay;

always @(*)
begin
    if(reg_addr_i == 8'h00) data_o_reg <= {3'd0, line};
    else if(reg_addr_i == 8'h01) data_o_reg <= {1'd0, cursor_x};
    else if(reg_addr_i == 8'h02) data_o_reg <= {3'd0, cursor_y};
    else if(reg_addr_i == 8'h03) data_o_reg <= {7'd0, cursor_visible};
    else if(reg_addr_i == 8'h07) data_o_reg <= {7'd0, tty_busy_reg};
    else if(reg_addr_i == 8'h77) data_o_reg <= {7'd0, tty_busy_reg};
    else if(reg_addr_i == 8'h0a) data_o_reg <= {7'd0, tty_enabled};
    else if(reg_addr_i == 8'h0b) data_o_reg <= {7'd0, scroll_enabled};
    else if(reg_addr_i == 8'h10) data_o_reg <= fg_r;
    else if(reg_addr_i == 8'h11) data_o_reg <= fg_g;
    else if(reg_addr_i == 8'h12) data_o_reg <= fg_b;
    else if(reg_addr_i == 8'h13) data_o_reg <= bg_r;
    else if(reg_addr_i == 8'h14) data_o_reg <= bg_g;
    else if(reg_addr_i == 8'h15) data_o_reg <= bg_b;
    else if(reg_addr_i == 8'h20) data_o_reg <= {6'd0, video_mode};
    else if(reg_addr_i == 8'h21) data_o_reg <= wpixel_y;
    else if(reg_addr_i == 8'h22) data_o_reg <= wpixel_x[7:0];
    else if(reg_addr_i == 8'h23) data_o_reg <= {7'd0, wpixel_x[8]};
    else if(reg_addr_i == 8'h24) data_o_reg <= vmem_out;
    else if(reg_addr_i == 8'h25) data_o_reg <= {7'd0, vpage};
    else if(reg_addr_i == 8'h26) data_o_reg <= pal_color;
    else if(reg_addr_i == 8'h27) data_o_reg <= palmem_out[7:0];
    else if(reg_addr_i == 8'h28) data_o_reg <= palmem_out[15:8];
    else if(reg_addr_i == 8'h29) data_o_reg <= palmem_out[23:16];
    else if(reg_addr_i == 8'h2a) data_o_reg <= {7'd0, vblank};
    else if(reg_addr_i[7] && (reg_addr_i[6:0] < 80)) data_o_reg <= charbuf_data_o;
    else data_o_reg <= 8'd0;
end

always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        line <= 5'd0;
        cursor_x_pre <= 7'd0;
        cursor_y_pre <= 4'd0;
        cursor_x_strobe <= 1'd0;
        cursor_y_strobe <= 1'd0;
        scroll_up <= 1'd0;
        scroll_down <= 1'd0;
        cursor_visible <= 1'd1;
        tty_wdata_pre <= 8'd0;
        tty_write_strobe <=1'd0;
        clear_to_eol_strobe <= 1'd0;
        clear_screen_strobe <= 1'd1;
        clear_to_eos_strobe <= 1'd0;
        delete_line_strobe <= 1'd0;
        insert_line_strobe <= 1'd0;
        tty_enabled <= 1'd1;
        scroll_enabled <= 1'd1;
        
        fg_r <= 8'h80;
        fg_g <= 8'h80;
        fg_b <= 8'h80;
        bg_r <= 8'h00;
        bg_g <= 8'h00;
        bg_b <= 8'h00;
    
        video_mode <= 2'd0;

        pal_write <= 1'd0;
        pal_color <= 8'd0;
    
        vpage <= 1'd0;

        wpixel_x <= 9'd0;
        wpixel_y <= 8'd0;
        pixel_write <= 1'd0;
        wpixel_inc <= 1'd0;

    end
    else if(!R_W_n && video_cs)
    begin
        if(reg_addr_i == 8'h00) line <= data_i_delay[4:0];
        else if(reg_addr_i==8'h01) 
        begin
            cursor_x_pre <= data_i_delay[6:0];
            cursor_x_strobe <= 1'd1;
        end
        else if(reg_addr_i==8'h02) 
        begin
            cursor_y_pre <= data_i_delay[4:0];
            cursor_y_strobe <= 1'd1;
        end
        else if(reg_addr_i==8'h03) cursor_visible <= data_i_delay[0];
        else if(reg_addr_i==8'h04) scroll_up <= 1'd1;
        else if(reg_addr_i==8'h05) scroll_down <= 1'd1;
        else if(reg_addr_i==8'h06 || reg_addr_i == 8'h76)
        begin
            tty_wdata_pre <= data_i_delay;
            tty_write_strobe <= 1'd1;
        end
        else if(reg_addr_i==8'h08) clear_to_eol_strobe <= 1'd1;
        else if(reg_addr_i==8'h09) clear_screen_strobe <= 1'd1;
        else if(reg_addr_i==8'h0a) clear_to_eos_strobe <= 1'd1;
        else if(reg_addr_i==8'h0b) delete_line_strobe <= 1'd1;
        else if(reg_addr_i==8'h0c) insert_line_strobe <= 1'd1;
        else if(reg_addr_i==8'h0d) tty_enabled = data_i_delay[0];
        else if(reg_addr_i==8'h0e) scroll_enabled = data_i_delay[0];
        else if(reg_addr_i==8'h10) fg_r = data_i_delay;
        else if(reg_addr_i==8'h11) fg_g = data_i_delay;
        else if(reg_addr_i==8'h12) fg_b = data_i_delay;
        else if(reg_addr_i==8'h13) bg_r = data_i_delay;
        else if(reg_addr_i==8'h14) bg_g = data_i_delay;
        else if(reg_addr_i==8'h15) bg_b = data_i_delay;
        else if(reg_addr_i==8'h20) video_mode <= data_i_delay[1:0];
        else if(reg_addr_i==8'h21) wpixel_y <= data_i_delay;
        else if(reg_addr_i==8'h22) wpixel_x[7:0] <= data_i_delay;
        else if(reg_addr_i==8'h23) wpixel_x[8] <= data_i_delay[0];
        else if(reg_addr_i==8'h24) begin
                vmem_in <= data_i_delay;
                pixel_write <= 1'd1;   
                wpixel_inc <= 1'd1;
        end
        else if(reg_addr_i==8'h25) vpage = data_i_delay[0];
        else if(reg_addr_i==8'h26) pal_color = data_i_delay;
        else if(reg_addr_i==8'h27) begin
                palmem_in <= {palmem_out[23:8], data_i_delay};
                pal_write <= 1'd1;
        end
        else if(reg_addr_i==8'h28) begin
                palmem_in <= {palmem_out[23:16], data_i_delay, palmem_out[7:0]};
                pal_write <= 1'd1;
        end
        else if(reg_addr_i==8'h29) begin
                palmem_in <= {data_i_delay, palmem_out[15:0]};
                pal_write <= 1'd1;
        end
        else
        begin
            scroll_up <= 1'd0;
            scroll_down <= 1'd0;
            cursor_x_strobe <= 1'd0;
            cursor_y_strobe <= 1'd0;
            tty_write_strobe <= 1'd0;
            clear_to_eol_strobe <= 1'd0;
            clear_screen_strobe <= 1'd0;
            clear_to_eos_strobe <= 1'd0;
            delete_line_strobe <= 1'd0;
            insert_line_strobe <= 1'd0;
            pal_write <= 1'd0;
            pixel_write <= 1'd0;

        end
    end
    else
    begin
        scroll_up <= 1'd0;
        scroll_down <= 1'd0;
        cursor_x_strobe <= 1'd0;
        cursor_y_strobe <= 1'd0;
        tty_write_strobe <= 1'd0;
        clear_to_eol_strobe <= 1'd0;
        clear_screen_strobe <= 1'd0;
        clear_to_eos_strobe <= 1'd0;
        delete_line_strobe <= 1'd0;
        insert_line_strobe <= 1'd0;
        pal_write <= 1'd0;
        pixel_write <= 1'd0;
        if(wpixel_inc == 1'b1) begin
            if(wpixel_x == 9'd159) begin
                wpixel_x <= 9'd0;
                if(wpixel_y == 8'd239) wpixel_y <= 8'd0;
                else wpixel_y <= wpixel_y + 1;
            end 
            else begin 
                wpixel_x <= wpixel_x + 1;
            end
            wpixel_inc <= 1'b0;
        end
    end
end

assign data_o = data_o_reg;

// tty state machine
reg [3:0]   tty_state;
reg [3:0]   return_state;
reg [7:0]   tty_wdata;
reg [7:0]   tty_wdata_pre;
reg         tty_we;
reg [11:0]  tty_waddr;
reg         tty_scroll;
reg [6:0]   tty_clr_cnt;
//reg [6:0]   tty_rd_cnt;
reg [4:0]   tty_clr_y;
reg         tty_busy_reg;
wire        tty_busy;

assign tty_busy = (tty_state != IDLE);

always @(posedge clk_vid_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        tty_state <= IDLE;
        return_state <= IDLE;
        cursor_x <= 7'd0;
        cursor_y <= 5'd0;
        tty_we <= 1'd0;
        tty_waddr <= 12'd0;
        tty_scroll <= 1'd0;
        tty_clr_cnt <= 7'd0;
        //tty_rd_cnt <= 7'd0;
        tty_clr_y <= 5'd0;
        tty_wdata <= 7'd0;
        source_line <= 6'd0;
        dest_line <= 6'd0;
        copy_write <= 1'd0;
        tty_busy_reg <= 1'd0;
    end
    else
    begin
        tty_busy_reg <= tty_busy;
        case(tty_state)
            IDLE:
            begin
                if(cursor_x_strobe) tty_state <= MOVE_CURSOR_X;
                else if(cursor_y_strobe) tty_state <= MOVE_CURSOR_Y;
                else if(tty_write_strobe && tty_enabled) tty_state <= WRITE_CHAR;
                else if(clear_to_eol_strobe) tty_state <= CLEAR_TO_EOL_INIT;
                else if(clear_screen_strobe) tty_state <= CLEAR_SCREEN_INIT;
                else if(clear_to_eos_strobe) tty_state <= CLEAR_TO_EOS_INIT;
                else if(delete_line_strobe) tty_state <= DELETE_LINE_INIT;
                else if(insert_line_strobe) tty_state <= INSERT_LINE_INIT;
                else tty_state <= IDLE;
                
                tty_we <= 1'd0;
                tty_scroll <= 1'd0;
                tty_clr_cnt <= 7'd0;
            
                return_state <= IDLE;
            end
            WRITE_CHAR:
            begin
                if(tty_wdata_pre == 8'h0d) 
                begin
                    cursor_x <= 7'd0;
                    tty_state <= IDLE;
                end
                else if(tty_wdata_pre == 8'h0a)
                begin
                    if(cursor_y < 5'd29) 
                    begin
                        cursor_y <= cursor_y + 1;
                        tty_state <= IDLE;
                        tty_scroll <= 1'd0;
                    end
                    else
                    begin
                        cursor_y <= cursor_y;
                        if(scroll_enabled) tty_scroll <= 1'd1;
                        else tty_scroll <= 1'd0;
                        return_state <= IDLE;
                        tty_state <= CLEAR_TO_EOL_INIT;
                    end
                end
                else if(tty_wdata_pre == 8'h08)
                begin
                    tty_wdata <= 8'd0;
                    tty_we <= 1'd1;
                    tty_waddr <= {(cursor_y+start_y) % LINES, 4'd0}+{(cursor_y+start_y) % LINES, 6'd0}+cursor_x-1;
                    if(cursor_x > 0) cursor_x <= cursor_x - 1;
                    tty_state <= IDLE;
                end
                else
                begin
                    tty_we <= 1'd1;
                    tty_waddr <= {(cursor_y+start_y) % LINES, 4'd0}+{(cursor_y+start_y) % LINES, 6'd0}+cursor_x;
                    tty_wdata <= tty_wdata_pre;
                    if(cursor_x < 7'd79) 
                    begin
                        cursor_x <= cursor_x + 1;
                        tty_state <= IDLE;
                        tty_scroll <= 1'd0;
                    end
                    else if(scroll_enabled)
                    begin
                        cursor_x <= 7'd0;
                        if(cursor_y < 5'd29) 
                        begin
                            cursor_y <= cursor_y + 1;
                            tty_state <= IDLE;
                            tty_scroll <= 1'd0;
                        end
                        else
                        begin
                            cursor_y <= cursor_y;
                            tty_scroll <= 1'd1;
                            return_state <= IDLE;
                            tty_state <= CLEAR_TO_EOL_INIT;
                        end
                    end
                end
            end
            MOVE_CURSOR_X:
            begin
                cursor_x <= cursor_x_pre;
                tty_state <= IDLE;
            end
            MOVE_CURSOR_Y:
            begin
                cursor_y <= cursor_y_pre;
                tty_state <= IDLE;
            end
            CLEAR_TO_EOL_INIT:
            begin
                tty_scroll <= 1'd0;
                tty_clr_cnt <= cursor_x;
                tty_state <= CLEAR_TO_EOL_RUN;
                tty_wdata <= 8'd0;
            end
            CLEAR_TO_EOL_RUN:
            begin
                if(tty_clr_cnt < 7'd80)
                begin
                    tty_we <= 1'd1;
                    tty_wdata <= 8'd0;
                    tty_waddr <= {(cursor_y+start_y) % LINES, 4'd0}+{(cursor_y+start_y) % LINES, 6'd0}+tty_clr_cnt;
                    tty_clr_cnt <= tty_clr_cnt + 1;
                    tty_state <= CLEAR_TO_EOL_RUN;
                end
                else
                begin
                    tty_we <= 1'd0;
                    tty_state <= return_state;
                end
            end
            CLEAR_SCREEN_INIT:
            begin
                cursor_x <= 7'd0;
                cursor_y <= 5'd0;
                tty_clr_y <= 5'd0;
                tty_state <= CLEAR_SCREEN_RUN;
            end
            CLEAR_SCREEN_RUN:
            begin
                if(tty_clr_y < 5'd31)
                begin
                    return_state <= CLEAR_SCREEN_RUN;
                    tty_clr_y <= tty_clr_y + 1;
                    cursor_y <= tty_clr_y - 1;
                    tty_state <= CLEAR_TO_EOL_INIT;
                end
                else
                begin
                    tty_state <= IDLE;
                    cursor_y <= 5'd0;
                end
            end
            CLEAR_TO_EOS_INIT:
            begin
                return_state <= CLEAR_TO_EOS_RUN;
                tty_clr_y <= cursor_y+1;
                tty_state <= CLEAR_TO_EOL_INIT;
            end
            CLEAR_TO_EOS_RUN:
            begin
                if(tty_clr_y < 5'd30)
                begin
                    cursor_x <= 0;
                    return_state <= CLEAR_TO_EOS_RUN;
                    tty_clr_y <= tty_clr_y + 1;
                    cursor_y <= tty_clr_y;
                    tty_state <= CLEAR_TO_EOL_INIT;
                end
                else
                begin
                    tty_state <= IDLE;
                end
            end
            DELETE_LINE_INIT:
            begin
                cursor_x <= 0;
                tty_clr_y <= cursor_y;
                tty_state <= DELETE_LINE_RUN;
                copy_write <= 1'b0;
            end
            DELETE_LINE_RUN:
            begin
                if(tty_clr_y < 5'd29)
                begin
                    dest_line <= tty_clr_y;
                    source_line <= tty_clr_y+1;
                    tty_clr_cnt <= 7'd0;
                    //tty_rd_cnt <= 7'd0;
                    return_state <= DELETE_LINE_RUN;
                    tty_state <= COPY_LINE;
                    tty_clr_y <= tty_clr_y + 1;
                end
                else
                begin
                    // Clear the last line
                    cursor_x <= 0;
                    cursor_y <= 5'd29;
                    return_state <= IDLE;
                    tty_state <= CLEAR_TO_EOL_INIT;
                end
            end
            COPY_LINE:
            begin
                if(tty_clr_cnt < 7'd80)
                begin
                    if(!copy_write)
                    begin
                        // Read a byte from the source line
                        tty_we <= 1'd0;
                        tty_wdata <= 8'd0;
                        tty_waddr <= {(source_line+start_y) % LINES, 4'd0}+{(source_line+start_y) % LINES, 6'd0}+tty_clr_cnt;
                        tty_state <= COPY_LINE;
                        copy_write <= 1'b1;
                    end
                    else
                    begin
                        // And write it to the destination line
                        tty_we <= 1'd1;
                        tty_wdata <= char;
                        tty_waddr <= {(dest_line+start_y) % LINES, 4'd0}+{(dest_line+start_y) % LINES, 6'd0}+tty_clr_cnt-1;
                        tty_state <= COPY_LINE;
                        copy_write <= 1'b0;
                        tty_clr_cnt <= tty_clr_cnt + 1;
                    end
                end
                else
                begin
                    tty_we <= 1'd0;
                    tty_state <= return_state;
                end
            end
            INSERT_LINE_INIT:
            begin
                cursor_x <= 0;
                tty_clr_y <= 5'd29;
                tty_state <= INSERT_LINE_RUN;
                copy_write <= 1'b0;
            end
            INSERT_LINE_RUN:
            begin
                if(tty_clr_y > cursor_y)
                begin
                    dest_line <= tty_clr_y;
                    source_line <= tty_clr_y-1;
                    tty_clr_cnt <= 7'd0;
                    //tty_rd_cnt <= 7'd0;
                    return_state <= INSERT_LINE_RUN;
                    tty_state <= COPY_LINE;
                    tty_clr_y <= tty_clr_y - 1;
                end
                else
                begin
                    // Clear the original line
                    cursor_x <= 0;
                    return_state <= IDLE;
                    tty_state <= CLEAR_TO_EOL_INIT;
                end
            end
            default: tty_state <= IDLE;
        endcase
    end
end


// Scrolling
reg [4:0] start_y;
localparam LINES = 30;

always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin 
        start_y <= 5'd0;
    end
    else if(scroll_up || tty_scroll)
        start_y <= (start_y + 1) % LINES;
    else if(scroll_down)
    begin
        if(start_y == 0) start_y <= LINES - 1;
        else start_y <= start_y - 1;
    end
end

// Cursor blink counter
always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        cursor_cnt <= 24'd0;
    end
    else if(cursor_cnt == 24'hffffff) cursor_cnt <= 24'd0; 
    else cursor_cnt <= cursor_cnt + 24'd1;

end

assign cursor_active = (cursor_cnt > 24'h800000) && cursor_visible;

// Character addressing
wire    [11:0]  char_x_offset;
wire    [11:0]  char_y_offset;
wire    [6:0]   char_x;
wire    [4:0]   char_y;
wire    [4:0]   scroll_y;
wire    [4:0]   scroll_line;
wire    [7:0]   char;

wire    [7:0]   charbuf_data_o;
wire    [11:0]  charbuf_addr;
wire    [11:0]  charbuf_waddr;
wire    [11:0]  charbuf_raddr;

wire    [7:0]   video_out_r;
wire    [7:0]   video_out_g;
wire    [7:0]   video_out_b;

//wire    [11:0]   tty_waddr;
wire    [7:0]   char_cur;
reg     [6:0]   char_x_delay;


assign char_x_offset = H_cnt-12'd148;//-12'd149;      
assign char_x = char_x_offset[9:3];
assign char_y_offset = V_cnt-12'd35;
assign char_y = char_y_offset[8:4];
assign scroll_y = (char_y + start_y) % LINES;
assign scroll_line = (line + start_y) % LINES;
//assign char = char_y+char_x;
assign charbuf_addr = {scroll_y, 4'd0}+{scroll_y, 6'd0}+char_x;  // Y*80 + X
assign charbuf_waddr = {scroll_line, 4'd0}+{scroll_line, 6'd0}+reg_addr_i[6:0];
assign charbuf_xaddr = {scroll_line, 4'd0}+{scroll_line, 6'd0}+reg_addr_r_i[6:0];
//assign tty_waddr = {(cursor_y+start_y) % LINES, 4'd0}+{(cursor_y+start_y) % LINES, 6'd0}+cursor_x;
assign charbuf_raddr = (tty_we || tty_busy) ? tty_waddr : charbuf_addr;

always @(posedge clk_vid_i)
    char_x_delay <= char_x;

// Character buffer - PORT A connects to CPU, PORT B connector to character generator
charbuf_dpram charbuf(
        .douta(charbuf_data_o), //output [7:0] douta
        .doutb(char), //output [7:0] doutb
        .clka(clk_i), //input clka
        .ocea(1'b1), //input ocea
        .cea(1'b1), //input cea
        .reseta(1'b0), //input reseta
        .wrea(~R_W_n && video_cs && reg_addr_i[7]),// && (reg_addr_i[6:0] < 80)), //input wrea
        .clkb(clk_vid_i), //input clkb
        .oceb(1'b1), //input oceb
        .ceb(1'b1), //input ceb
        .resetb(1'b0), //input resetb
        .wreb(tty_we), //input wreb
        .ada(/*R_W_n ? charbuf_xaddr :*/ charbuf_waddr), //input [11:0] ada
        .dina(data_i_delay), //input [7:0] dina
        .adb(charbuf_raddr), //input [11:0] adb
        .dinb(tty_wdata) //input [7:0] dinb
    );

// Font drawing
wire    [2:0]   font_x;
wire    [11:0]  y_offset;
wire    [3:0]   font_y;
wire    [10:0]  font_addr;
wire    [7:0]   font_data;
wire            font_out;

assign font_x = H_cnt[2:0]-6;
assign y_offset = V_cnt - 12'd35;
assign font_y = y_offset[3:0]; 
assign font_addr = {char, font_y};
assign char_cur[6:0] = char[6:0];
assign char_cur[7] = (cursor_active && (char_x_delay == cursor_x) && (char_y == cursor_y)) ? ~char[7] : char[7];
assign font_out = char_cur[7] ? ~font_data[7'd7-font_x] : font_data[7'd7-font_x];


// Graphics mode stuff

wire [7:0] vmem_out;
wire [7:0] pixel_data;

wire [15:0] pixel_addr;

wire [7:0]  pixel_y;
wire [8:0]  pixel_x;
wire [11:0]  pixel_y_offset;
wire [11:0]  pixel_x_offset;

reg [7:0]   wpixel_y;
reg [8:0]   wpixel_x;
reg         vpage;
reg         pixel_write;
reg [7:0]   vmem_in;
reg         wpixel_inc;

wire [15:0] wpixel_addr;
wire [15:0] page_offset;

wire        vblank;

assign pixel_y_offset = V_cnt-12'd35;
assign pixel_x_offset = H_cnt-12'd147;
assign pixel_x = pixel_x_offset[9:2];
assign pixel_y = pixel_y_offset[9:2];

// Only support 160x120 for now
assign page_offset = (vpage == 1'b0) ? 16'h0000 : 16'h4B00;
assign pixel_addr = page_offset + {pixel_y, 7'd0} + {pixel_y, 5'd0} + pixel_x;

// Only support 160x120 for now
assign wpixel_addr = {wpixel_y, 7'd0} + {wpixel_y, 5'd0} + wpixel_x;

// Vertical blanking signal for sync
assign vblank = ((V_cnt < 12'd35) | (V_cnt > 12'd515)) ? 1'b1 : 1'b0;

// Video memory for graphics mode,  320x200 bytes for double buffering of 160x120 (could be optimized)
// Port A connects to CPU, Port B to video generator
    vbuf_dpram video_mem(
        .douta(vmem_out), //output [7:0] douta
        .doutb(pixel_data), //output [7:0] doutb
        .clka(clk_i), //input clka
        .ocea(1'b1), //input ocea
        .cea(1'b1), //input cea
        .reseta(1'b0), //input reseta
        .wrea(pixel_write), //input wrea
        .clkb(clk_vid_i), //input clkb
        .oceb(1'b1), //input oceb
        .ceb(1'b1), //input ceb
        .resetb(1'b0), //input resetb
        .wreb(1'b0), //input wreb
        .ada(wpixel_addr), //input [15:0] ada
        .dina(vmem_in), //input [7:0] dina
        .adb(pixel_addr), //input [15:0] adb
        .dinb(7'd0) //input [7:0] dinb
    );

wire [23:0] palmem_out;
wire [23:0] color_out;
reg [23:0]  palmem_in;

reg         pal_write;
reg [7:0]   pal_color;

// Palette memory
    pal_dpram pal_mem(
        .douta(palmem_out), //output [23:0] douta
        .doutb(color_out), //output [23:0] doutb
        .clka(clk_i), //input clka
        .ocea(1'b1), //input ocea
        .cea(1'b1), //input cea
        .reseta(1'b0), //input reseta
        .wrea(pal_write), //input wrea
        .clkb(clk_vid_i), //input clkb
        .oceb(1'b1), //input oceb
        .ceb(1'b1), //input ceb
        .resetb(1'b0), //input resetb
        .wreb(1'b0), //input wreb
        .ada(pal_color), //input [7:0] ada
        .dina(palmem_in), //input [23:0] dina
        .adb(pixel_data), //input [7:0] adb
        .dinb(23'd0) //input [23:0] dinb
    );

assign video_out_r = (video_mode == 2'd0) ? (font_out ? fg_r : bg_r) : color_out[7:0];
assign video_out_g = (video_mode == 2'd0) ? (font_out ? fg_g : bg_g) : color_out[15:8];
assign video_out_b = (video_mode == 2'd0) ? (font_out ? fg_b : bg_b) : color_out[23:16];

fontrom fontrom_inst(
    .clk(clk_i),
    .adr(font_addr),
    .data(font_data)
);

DVI_TX_Top dvi_tx(
		.I_rst_n(rst_n_i), //input I_rst_n
		.I_rgb_clk(clk_vid_i), //input I_rgb_clk
		.I_rgb_vs(dvi_vs), //input I_rgb_vs
		.I_rgb_hs(dvi_hs), //input I_rgb_hs
		.I_rgb_de(dvi_de), //input I_rgb_de
		.I_rgb_r(video_out_r), //input [7:0] I_rgb_r {font_out, 7'd0}
		.I_rgb_g(video_out_g), //input [7:0] I_rgb_g
		.I_rgb_b(video_out_b), //input [7:0] I_rgb_b
		.O_tmds_clk_p(tmds_clk_p_o), //output O_tmds_clk_p
		.O_tmds_clk_n(tmds_clk_n_o), //output O_tmds_clk_n
		.O_tmds_data_p(tmds_data_p_o), //output [2:0] O_tmds_data_p
		.O_tmds_data_n(tmds_data_n_o) //output [2:0] O_tmds_data_n
	);

endmodule