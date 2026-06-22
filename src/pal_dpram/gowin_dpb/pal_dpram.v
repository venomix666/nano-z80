//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9.03 Education
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Sun Jun 21 10:28:36 2026

module pal_dpram (douta, doutb, clka, ocea, cea, reseta, wrea, clkb, oceb, ceb, resetb, wreb, ada, dina, adb, dinb);

output [23:0] douta;
output [23:0] doutb;
input clka;
input ocea;
input cea;
input reseta;
input wrea;
input clkb;
input oceb;
input ceb;
input resetb;
input wreb;
input [7:0] ada;
input [23:0] dina;
input [7:0] adb;
input [23:0] dinb;

wire [7:0] dpb_inst_1_douta_w;
wire [7:0] dpb_inst_1_doutb_w;
wire gw_vcc;
wire gw_gnd;

assign gw_vcc = 1'b1;
assign gw_gnd = 1'b0;

DPB dpb_inst_0 (
    .DOA(douta[15:0]),
    .DOB(doutb[15:0]),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({gw_gnd,gw_gnd,ada[7:0],gw_gnd,gw_gnd,gw_vcc,gw_vcc}),
    .DIA(dina[15:0]),
    .ADB({gw_gnd,gw_gnd,adb[7:0],gw_gnd,gw_gnd,gw_vcc,gw_vcc}),
    .DIB(dinb[15:0])
);

defparam dpb_inst_0.READ_MODE0 = 1'b0;
defparam dpb_inst_0.READ_MODE1 = 1'b0;
defparam dpb_inst_0.WRITE_MODE0 = 2'b00;
defparam dpb_inst_0.WRITE_MODE1 = 2'b00;
defparam dpb_inst_0.BIT_WIDTH_0 = 16;
defparam dpb_inst_0.BIT_WIDTH_1 = 16;
defparam dpb_inst_0.BLK_SEL_0 = 3'b000;
defparam dpb_inst_0.BLK_SEL_1 = 3'b000;
defparam dpb_inst_0.RESET_MODE = "SYNC";
defparam dpb_inst_0.INIT_RAM_00 = 256'hFFFFFFFF55FF55FFFF55FF5555555555AAAA55AA00AA00AAAA00AA0000000000;
defparam dpb_inst_0.INIT_RAM_01 = 256'hFFFFE2E2CACAB6B6A2A292928181717161615151454538382C2C202014140000;
defparam dpb_inst_0.INIT_RAM_02 = 256'h3F008300C700FF00FF00FF00FF00FF00FF3FFF83FFC7FFFFC7FF83FF3FFF00FF;
defparam dpb_inst_0.INIT_RAM_03 = 256'hFF7FFFA6FFCAFFFFCAFFA6FF7FFF55FF00FF00FF00FF00FF00C70083003F0000;
defparam dpb_inst_0.INIT_RAM_04 = 256'h55FF55FF55FF55FF55CA55A6557F55557F55A655CA55FF55FF55FF55FF55FF55;
defparam dpb_inst_0.INIT_RAM_05 = 256'hBFAAD4AAE9AAFFAAFFAAFFAAFFAAFFAAFFBFFFD4FFE9FFFFE9FFD4FFBFFFAAAF;
defparam dpb_inst_0.INIT_RAM_06 = 256'hC233C266C299C2C299C266C233C200C2AAFFAAFFAAFFAAFFAAE9AAD4AABFAAAA;
defparam dpb_inst_0.INIT_RAM_07 = 256'h00C200C200C200C20099006600330000330066009900C200C200C200C200C200;
defparam dpb_inst_0.INIT_RAM_08 = 256'h5F3F7F3F9F3FC23FC23FC23FC23FC23FC25FC27FC29FC2C29FC27FC25FC23FC2;
defparam dpb_inst_0.INIT_RAM_09 = 256'hC293C2A6C2B6C2C2B6C2A6C293C283C2C23FC23FC23F3FC23F9F3F7F3F5F3F3F;
defparam dpb_inst_0.INIT_RAM_0A = 256'h83C283C283C283C283B683A6839383839383A683B683C283C283C283C283C283;
defparam dpb_inst_0.INIT_RAM_0B = 256'h24004D007100920092009200920092009224924D9271929271924D9224920092;
defparam dpb_inst_0.INIT_RAM_0C = 256'h924D9266927D92927D9266924D92339200920092009200920071004D00240000;
defparam dpb_inst_0.INIT_RAM_0D = 256'h3392339233923392337D3366334D33334D3366337D3392339233923392339233;
defparam dpb_inst_0.INIT_RAM_0E = 256'h6161716181619261926192619261926192619271928192929292819271926192;
defparam dpb_inst_0.INIT_RAM_0F = 256'h0000000000000000000000000000000061926192619261926192618161716161;

DPB dpb_inst_1 (
    .DOA({dpb_inst_1_douta_w[7:0],douta[23:16]}),
    .DOB({dpb_inst_1_doutb_w[7:0],doutb[23:16]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({gw_gnd,gw_gnd,gw_gnd,ada[7:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[23:16]}),
    .ADB({gw_gnd,gw_gnd,gw_gnd,adb[7:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[23:16]})
);

defparam dpb_inst_1.READ_MODE0 = 1'b0;
defparam dpb_inst_1.READ_MODE1 = 1'b0;
defparam dpb_inst_1.WRITE_MODE0 = 2'b00;
defparam dpb_inst_1.WRITE_MODE1 = 2'b00;
defparam dpb_inst_1.BIT_WIDTH_0 = 8;
defparam dpb_inst_1.BIT_WIDTH_1 = 8;
defparam dpb_inst_1.BLK_SEL_0 = 3'b000;
defparam dpb_inst_1.BLK_SEL_1 = 3'b000;
defparam dpb_inst_1.RESET_MODE = "SYNC";
defparam dpb_inst_1.INIT_RAM_00 = 256'hFFE2CAB6A2928171615145382C201400FF55FF55FF55FF55AA00AA00AA00AA00;
defparam dpb_inst_1.INIT_RAM_01 = 256'h55555555555555553F83C7FFFFFFFFFFFFFFFFFFC7833F000000000000000000;
defparam dpb_inst_1.INIT_RAM_02 = 256'hFFFFFFFFE9D4BFAAAAAAAAAAAAAAAAAA7FA6CAFFFFFFFFFFFFFFFFFFCAA67F55;
defparam dpb_inst_1.INIT_RAM_03 = 256'h336699C2C2C2C2C2C2C2C2C2996633000000000000000000BFD4E9FFFFFFFFFF;
defparam dpb_inst_1.INIT_RAM_04 = 256'h83838383838383835F7F9FC2C2C2C2C2C2C2C2C29F7F5F3F3F3F3F3F3F3F3F3F;
defparam dpb_inst_1.INIT_RAM_05 = 256'h92929292714D2400000000000000000093A6B6C2C2C2C2C2C2C2C2C2B6A69383;
defparam dpb_inst_1.INIT_RAM_06 = 256'h4D667D9292929292929292927D664D333333333333333333244D719292929292;
defparam dpb_inst_1.INIT_RAM_07 = 256'h00000000000000006D7981929292929292929292928171616161616161616161;

endmodule //pal_dpram
