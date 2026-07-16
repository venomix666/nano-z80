// USB HID interface for the nano-Z80
//
// Based on USB HID core by nand2mario
//
// Registers:
// 00       -   New key
// 01       -   Keyboard character
// 02       -   Key modifier
// 03       -   Mouse button
// 04       -   Mouse dx
// 05       -   Mouse dy
// 06       -   {4'b0000, game_d, game_u, game_r, game_l}
// 07       -   {2'b00, game_sta, game_sel, game_y, game_x, game_b, game_a}
// 08       -   New USB report 
// 09       -   Device type - 0: no device, 1: keyboard, 2: mouse, 3: gamepad
// 0a       -   Error signal
// 0b       -   Arrow key configuration (0: ADM3A, 1: WordStar, 2: EMACS/MINCE, 3: VT52 for fuzix) 

module usb_interface(
	input               clk_i,
    input               clkusb_i,
	input               rst_n_i,
    input               wr_n,
	input   [7:0]       reg_addr_i,
    input   [7:0]       data_i,
    input               usb_cs,
    output  [7:0]       data_o,
    output              kb_int_n_o,
    inout               usb_dm,          // USB D+   
    inout               usb_dp           // USB D-
    
);

wire            [1:0]   typ;        // Device type
wire                    report;     // Pulse after report
wire                    conerr;     // Error signal
wire            [7:0]   key_modifiers;
wire            [7:0]   key1, key2, key3, key4;
wire            [7:0]   mouse_btn;
wire    signed  [7:0]   mouse_dx;
wire    signed  [7:0]   mouse_dy;
wire                    game_l, game_r, game_u, game_d;
wire                    game_a, game_b, game_x, game_y, game_sel, game_sta;


reg             [7:0]   key_active[2];
reg             [7:0]   keydown;
reg             [7:0]   keyascii;
reg                     new_key_set;
reg                     new_key;

reg             [7:0]   mouse_btn_reg;
reg     signed  [7:0]   mouse_dx_reg, mouse_dy_reg;
reg             [7:0]   game_dir_reg;
reg             [7:0]   game_btn_reg;

reg             [7:0]   data_o_reg;
reg                     report_reg;
reg                     new_key_set_reclocked;
reg                     new_key_set_reclocked_delay;

reg             [22:0]  key1_rpt_cnt;
reg             [22:0]  key2_rpt_cnt;

reg             new_key_next;

reg             [1:0]   arrow_key_conf;
reg             [7:0]   arrow_key_constants [15:0];

localparam      FIRST_REPEAT = 23'd8000000;
localparam      REPEAT_RATE = 23'd1200000;

// Interrupt when new key available
assign kb_int_n_o = ~new_key;

// Asynchronous read
always @(*)
begin
    case(reg_addr_i)
        8'h00: data_o_reg = {7'd0, new_key};
        8'h01: data_o_reg = keyascii;
        8'h02: data_o_reg = key_modifiers;
        8'h03: data_o_reg = mouse_btn_reg;
        8'h04: data_o_reg = mouse_dx_reg;
        8'h05: data_o_reg = mouse_dy_reg;
        8'h06: data_o_reg = game_dir_reg;
        8'h07: data_o_reg = game_btn_reg;
        8'h08: data_o_reg = {7'd0, report_reg};
        8'h09: data_o_reg = {6'd0, typ};
        8'h0a: data_o_reg = {7'd0, conerr};
        8'h0b: data_o_reg = {6'd0, arrow_key_conf};
        8'h74: data_o_reg = {7'd0, new_key};
        8'h75: data_o_reg = keyascii;
        default:
        begin
            data_o_reg = 8'd0;
        end
    endcase
end

assign data_o = data_o_reg;

// Register writing
always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        arrow_key_conf <= 2'd0;
        // Setup arrow key constants
        
        // ADM-3A
        arrow_key_constants[0] = 8'd12;
        arrow_key_constants[1] = 8'd8;
        arrow_key_constants[2] = 8'd10;
        arrow_key_constants[3] = 8'd11;

        // WordStar
        arrow_key_constants[4] = 8'd4;
        arrow_key_constants[5] = 8'd19;
        arrow_key_constants[6] = 8'd24;
        arrow_key_constants[7] = 8'd5;

        // EMACS / MINCE
        arrow_key_constants[8] = 8'd6;
        arrow_key_constants[9] = 8'd2;
        arrow_key_constants[10] = 8'd14;
        arrow_key_constants[11] = 8'd16;

        // VT52 for Fuzix
        arrow_key_constants[12] = 8'hC3; //C with high bit set
        arrow_key_constants[13] = 8'hC4; //D with high bit set
        arrow_key_constants[14] = 8'hC2; //B with high bit set
        arrow_key_constants[15] = 8'hC1; //A with high bit set

        

    end
    else if((!wr_n) && (usb_cs) && (reg_addr_i==8'h0b))
    begin
        arrow_key_conf <= data_i[1:0];
    end
end

// Latch data when new USB report comes
always @(posedge clkusb_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        keyascii <= 8'd0;
        key_active[0] <= 8'd0;
        key_active[1] <= 8'd0;

        mouse_btn_reg <= 8'd0;
        mouse_dx_reg <= 8'd0;
        mouse_dy_reg <= 8'd0;
        game_btn_reg <= 8'd0;
        game_dir_reg <= 8'd0;
        new_key_set <= 1'd0;

        key1_rpt_cnt <= FIRST_REPEAT;
        key2_rpt_cnt <= FIRST_REPEAT;

    end
    else if(report == 1'b1) 
    begin
        case(typ)
        1: begin // Keyboard

            if (key1 !=0 && key1 != key_active[0] && key1 != key_active[1]) begin
                keydown <= key1; keyascii <= scancode2char(key1, key_modifiers, 
                                                           arrow_key_constants[{arrow_key_conf, 2'd0}], 
                                                           arrow_key_constants[{arrow_key_conf, 2'd1}], 
                                                           arrow_key_constants[{arrow_key_conf, 2'd2}], 
                                                           arrow_key_constants[{arrow_key_conf, 2'd3}]);
                new_key_set <= 1'b1;
                key1_rpt_cnt <= FIRST_REPEAT;
            end
            else if (key2 !=0 && key2 != key_active[0] && key2 != key_active[1]) begin
                keydown <= key2; keyascii <= scancode2char(key2, key_modifiers, 
                                                           arrow_key_constants[{arrow_key_conf, 2'd0}], 
                                                           arrow_key_constants[{arrow_key_conf, 2'd1}], 
                                                           arrow_key_constants[{arrow_key_conf, 2'd2}], 
                                                           arrow_key_constants[{arrow_key_conf, 2'd3}]);
                new_key_set <= 1'b1;
                key2_rpt_cnt <= FIRST_REPEAT;
            end
            else new_key_set <= 1'b0;
            key_active[0] <= key1; key_active[1] <= key2;
        end
        2: begin // mouse
            mouse_btn_reg <= mouse_btn;
            mouse_dx_reg <= mouse_dx;
            mouse_dy_reg <= mouse_dy;
        end
        3: begin // gamepad
            game_dir_reg <= {4'b0000, game_d, game_u, game_r, game_l};
            game_btn_reg <= {2'b00, game_sta, game_sel, game_y, game_x, game_b, game_a};
        end
        endcase
    end
    else begin
        /* Handle auto-repeat */
        if(key_active[0] != 8'd0) begin
            key1_rpt_cnt <= key1_rpt_cnt - 1;
            if(key1_rpt_cnt == 23'd0) begin
                keydown <= key_active[0];
                keyascii <= scancode2char(key_active[0], key_modifiers,
                                          arrow_key_constants[{arrow_key_conf, 2'd0}], 
                                          arrow_key_constants[{arrow_key_conf, 2'd1}], 
                                          arrow_key_constants[{arrow_key_conf, 2'd2}], 
                                          arrow_key_constants[{arrow_key_conf, 2'd3}]);
                new_key_set <= 1'b1;
                key1_rpt_cnt <= REPEAT_RATE;
            end
            else new_key_set <= 1'b0;
        end
        else if(key_active[1] != 8'd0) begin
            key2_rpt_cnt <= key2_rpt_cnt - 1;
            if(key2_rpt_cnt == 23'd0) begin
                keydown <= key_active[1];
                keyascii <= scancode2char(key_active[1], key_modifiers,
                                          arrow_key_constants[{arrow_key_conf, 2'd0}], 
                                          arrow_key_constants[{arrow_key_conf, 2'd1}], 
                                          arrow_key_constants[{arrow_key_conf, 2'd2}], 
                                          arrow_key_constants[{arrow_key_conf, 2'd3}]);
                new_key_set <= 1'b1;
                key2_rpt_cnt <= REPEAT_RATE;
            end
            else new_key_set <= 1'b0;
        end
        else new_key_set <= 1'b0;
    end
end

// Reclock new_key_set to CPU clock, debounce and make it one-shot
always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0) new_key_set_reclocked <= 1'b0;
    else if (new_key_set_reclocked == 1'b0 && new_key_set_reclocked_delay == 1'b0) 
    begin
        new_key_set_reclocked <= new_key_set;
        new_key_set_reclocked_delay <= 1'b0;
    end
    else 
    begin
        new_key_set_reclocked_delay <= new_key_set_reclocked;
        new_key_set_reclocked <= 1'b0;
    end
end

// Latch the report pulse and clear on read
always @(posedge clk_i or negedge rst_n_i)
begin
    if(rst_n_i == 1'b0)
    begin
        report_reg <= 1'b0;
        new_key <= 1'b0;
        new_key_next <= 1'b1; 
    end
    else
    begin
        if(report == 1'b1) report_reg <= 1'b1;
        else if((usb_cs == 1'b1) && (reg_addr_i == 8'h08)) report_reg <= 1'b0;
        
        if(new_key_set_reclocked_delay == 1'b1) new_key_next <= 1'b1;
        else if((usb_cs == 1'b1) && ((reg_addr_i == 8'h01) || (reg_addr_i == 8'h75))) new_key_next <= 1'b0; 
        new_key <= new_key_next;
    end
end



usb_hid_host usb_hid_host_inst(
    .usbclk(clkusb_i),
    .usbrst_n(rst_n_i),
    .usb_dm(usb_dm),
    .usb_dp(usb_dp),
    .typ(typ),
    .report(report),
    .conerr(conerr),
    .key_modifiers(key_modifiers),
    .key1(key1),
    .key2(key2),
    .key3(key3),
    .key4(key4),
    .mouse_btn(mouse_btn),
    .mouse_dx(mouse_dx),
    .mouse_dy(mouse_dy),
    .game_l(game_l),
    .game_r(game_r),
    .game_u(game_u),
    .game_d(game_d),
    .game_a(game_a),
    .game_b(game_b),
    .game_x(game_x),
    .game_y(game_y),
    .game_sel(game_sel),
    .game_sta(game_sta),
    .dbg_hid_report()
);

endmodule

localparam [7:0] SHIFT_MASK = 8'b00100010;
localparam [7:0] CTRL_MASK = 8'b00010001;
function [7:0] scancode2char(input [7:0] scancode, input [7:0] modifiers, input [7:0] right, input [7:0] left, input [7:0] down, input [7:0] up); 
    reg [7:0] a;
    if (scancode >= 4 && scancode <= 29) begin   // a-z
        if (modifiers == 0)
            a = scancode - 4 + 97;             // a: 97, A: 65, ctrl+a: 1
        else if ((modifiers & SHIFT_MASK) && (modifiers & ~SHIFT_MASK) == 0)
            a = scancode - 4 + 65;
        else if ((modifiers & CTRL_MASK) && (modifiers & ~CTRL_MASK)==0)
            a = scancode - 3;
    end else if(scancode >=58 && scancode <= 69) begin // Function keys
        // Map function keys F1 - F12 to 0xf0 - 0xfc
        a = scancode + 182;
    end else if (modifiers == 0) begin
        case (scancode)
            30: a = "1";
            31: a = "2";
            32: a = "3";
            33: a = "4";
            34: a = "5";
            35: a = "6";
            36: a = "7";
            37: a = "8";
            38: a = "9";
            39: a = "0";
            40: a = 13;       // enter
            41: a = 27;         // esc
            42: a = 8;          // backspace
            43: a = 9;          // tab
            44: a = 32;         // space
            45: a = "-";        // -
            46: a = "=";        // =
            47: a = "[";        // [
            48: a = "]";        // ]
            49: a = "\\";       // \
            50: a = "#";        // non-use # ~
            51: a = ";";        // ;
            52: a = "'";        // '
            53: a = "`";        // `
            54: a = ",";        // ,
            55: a = ".";        // .
            56: a = "/";        // /
            57: ;               // caps lock
            79: a = right; //137;        // Right arrow
            80: a = left; //136;        // Left arrow
            81: a = down; //138;        // Down arrow
            82: a = up; //139;        // Up arrow
        endcase
    end if ((modifiers & SHIFT_MASK) && (modifiers & ~SHIFT_MASK) == 0) begin
        // shift down
        case (scancode)
            30: a = "!";
            31: a = "@";
            32: a = "#";
            33: a = "$";
            34: a = "%";
            35: a = "^";
            36: a = "&";
            37: a = "*";
            38: a = "(";
            39: a = ")";
            40: a = 13;       // enter
            41: a = 27;         // esc
            42: a = 8;          // backspace
            43: a = 9;          // tab
            44: a = 32;         // space
            45: a = "_";
            46: a = "+";
            47: a = "{"; 
            48: a = "}";
            49: a = "|";
            50: a = "~";
            51: a = ":";
            52: a = "\"";
            53: a = "~";
            54: a = "<";
            55: a = ">";
            56: a = "?";
            57: ;
        endcase 
    end 
    scancode2char = a;
endfunction