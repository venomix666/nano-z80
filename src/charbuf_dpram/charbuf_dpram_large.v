//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9.03 Education
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Tue Jul 14 14:31:03 2026

module charbuf_dpram_large (douta, doutb, clka, ocea, cea, reseta, wrea, clkb, oceb, ceb, resetb, wreb, ada, dina, adb, dinb);

output [7:0] douta;
output [7:0] doutb;
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
input [13:0] ada;
input [7:0] dina;
input [13:0] adb;
input [7:0] dinb;

wire [13:0] dpb_inst_0_douta_w;
wire [1:0] dpb_inst_0_douta;
wire [13:0] dpb_inst_0_doutb_w;
wire [1:0] dpb_inst_0_doutb;
wire [13:0] dpb_inst_1_douta_w;
wire [3:2] dpb_inst_1_douta;
wire [13:0] dpb_inst_1_doutb_w;
wire [3:2] dpb_inst_1_doutb;
wire [13:0] dpb_inst_2_douta_w;
wire [5:4] dpb_inst_2_douta;
wire [13:0] dpb_inst_2_doutb_w;
wire [5:4] dpb_inst_2_doutb;
wire [13:0] dpb_inst_3_douta_w;
wire [7:6] dpb_inst_3_douta;
wire [13:0] dpb_inst_3_doutb_w;
wire [7:6] dpb_inst_3_doutb;
wire [7:0] dpb_inst_4_douta_w;
wire [7:0] dpb_inst_4_douta;
wire [7:0] dpb_inst_4_doutb_w;
wire [7:0] dpb_inst_4_doutb;
wire dff_q_0;
wire dff_q_1;
wire cea_w;
wire ceb_w;
wire gw_gnd;

assign cea_w = ~wrea & cea;
assign ceb_w = ~wreb & ceb;
assign gw_gnd = 1'b0;

DPB dpb_inst_0 (
    .DOA({dpb_inst_0_douta_w[13:0],dpb_inst_0_douta[1:0]}),
    .DOB({dpb_inst_0_doutb_w[13:0],dpb_inst_0_doutb[1:0]}),
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
    .BLKSELA({gw_gnd,gw_gnd,ada[13]}),
    .BLKSELB({gw_gnd,gw_gnd,adb[13]}),
    .ADA({ada[12:0],gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[1:0]}),
    .ADB({adb[12:0],gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[1:0]})
);

defparam dpb_inst_0.READ_MODE0 = 1'b0;
defparam dpb_inst_0.READ_MODE1 = 1'b0;
defparam dpb_inst_0.WRITE_MODE0 = 2'b00;
defparam dpb_inst_0.WRITE_MODE1 = 2'b00;
defparam dpb_inst_0.BIT_WIDTH_0 = 2;
defparam dpb_inst_0.BIT_WIDTH_1 = 2;
defparam dpb_inst_0.BLK_SEL_0 = 3'b000;
defparam dpb_inst_0.BLK_SEL_1 = 3'b000;
defparam dpb_inst_0.RESET_MODE = "SYNC";

DPB dpb_inst_1 (
    .DOA({dpb_inst_1_douta_w[13:0],dpb_inst_1_douta[3:2]}),
    .DOB({dpb_inst_1_doutb_w[13:0],dpb_inst_1_doutb[3:2]}),
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
    .BLKSELA({gw_gnd,gw_gnd,ada[13]}),
    .BLKSELB({gw_gnd,gw_gnd,adb[13]}),
    .ADA({ada[12:0],gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[3:2]}),
    .ADB({adb[12:0],gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[3:2]})
);

defparam dpb_inst_1.READ_MODE0 = 1'b0;
defparam dpb_inst_1.READ_MODE1 = 1'b0;
defparam dpb_inst_1.WRITE_MODE0 = 2'b00;
defparam dpb_inst_1.WRITE_MODE1 = 2'b00;
defparam dpb_inst_1.BIT_WIDTH_0 = 2;
defparam dpb_inst_1.BIT_WIDTH_1 = 2;
defparam dpb_inst_1.BLK_SEL_0 = 3'b000;
defparam dpb_inst_1.BLK_SEL_1 = 3'b000;
defparam dpb_inst_1.RESET_MODE = "SYNC";

DPB dpb_inst_2 (
    .DOA({dpb_inst_2_douta_w[13:0],dpb_inst_2_douta[5:4]}),
    .DOB({dpb_inst_2_doutb_w[13:0],dpb_inst_2_doutb[5:4]}),
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
    .BLKSELA({gw_gnd,gw_gnd,ada[13]}),
    .BLKSELB({gw_gnd,gw_gnd,adb[13]}),
    .ADA({ada[12:0],gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[5:4]}),
    .ADB({adb[12:0],gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[5:4]})
);

defparam dpb_inst_2.READ_MODE0 = 1'b0;
defparam dpb_inst_2.READ_MODE1 = 1'b0;
defparam dpb_inst_2.WRITE_MODE0 = 2'b00;
defparam dpb_inst_2.WRITE_MODE1 = 2'b00;
defparam dpb_inst_2.BIT_WIDTH_0 = 2;
defparam dpb_inst_2.BIT_WIDTH_1 = 2;
defparam dpb_inst_2.BLK_SEL_0 = 3'b000;
defparam dpb_inst_2.BLK_SEL_1 = 3'b000;
defparam dpb_inst_2.RESET_MODE = "SYNC";

DPB dpb_inst_3 (
    .DOA({dpb_inst_3_douta_w[13:0],dpb_inst_3_douta[7:6]}),
    .DOB({dpb_inst_3_doutb_w[13:0],dpb_inst_3_doutb[7:6]}),
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
    .BLKSELA({gw_gnd,gw_gnd,ada[13]}),
    .BLKSELB({gw_gnd,gw_gnd,adb[13]}),
    .ADA({ada[12:0],gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[7:6]}),
    .ADB({adb[12:0],gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[7:6]})
);

defparam dpb_inst_3.READ_MODE0 = 1'b0;
defparam dpb_inst_3.READ_MODE1 = 1'b0;
defparam dpb_inst_3.WRITE_MODE0 = 2'b00;
defparam dpb_inst_3.WRITE_MODE1 = 2'b00;
defparam dpb_inst_3.BIT_WIDTH_0 = 2;
defparam dpb_inst_3.BIT_WIDTH_1 = 2;
defparam dpb_inst_3.BLK_SEL_0 = 3'b000;
defparam dpb_inst_3.BLK_SEL_1 = 3'b000;
defparam dpb_inst_3.RESET_MODE = "SYNC";

DPB dpb_inst_4 (
    .DOA({dpb_inst_4_douta_w[7:0],dpb_inst_4_douta[7:0]}),
    .DOB({dpb_inst_4_doutb_w[7:0],dpb_inst_4_doutb[7:0]}),
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
    .BLKSELA({ada[13],ada[12],ada[11]}),
    .BLKSELB({adb[13],adb[12],adb[11]}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[7:0]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[7:0]})
);

defparam dpb_inst_4.READ_MODE0 = 1'b0;
defparam dpb_inst_4.READ_MODE1 = 1'b0;
defparam dpb_inst_4.WRITE_MODE0 = 2'b00;
defparam dpb_inst_4.WRITE_MODE1 = 2'b00;
defparam dpb_inst_4.BIT_WIDTH_0 = 8;
defparam dpb_inst_4.BIT_WIDTH_1 = 8;
defparam dpb_inst_4.BLK_SEL_0 = 3'b100;
defparam dpb_inst_4.BLK_SEL_1 = 3'b100;
defparam dpb_inst_4.RESET_MODE = "SYNC";

DFFE dff_inst_0 (
  .Q(dff_q_0),
  .D(ada[13]),
  .CLK(clka),
  .CE(cea_w)
);
DFFE dff_inst_1 (
  .Q(dff_q_1),
  .D(adb[13]),
  .CLK(clkb),
  .CE(ceb_w)
);
MUX2 mux_inst_4 (
  .O(douta[0]),
  .I0(dpb_inst_0_douta[0]),
  .I1(dpb_inst_4_douta[0]),
  .S0(dff_q_0)
);
MUX2 mux_inst_9 (
  .O(douta[1]),
  .I0(dpb_inst_0_douta[1]),
  .I1(dpb_inst_4_douta[1]),
  .S0(dff_q_0)
);
MUX2 mux_inst_14 (
  .O(douta[2]),
  .I0(dpb_inst_1_douta[2]),
  .I1(dpb_inst_4_douta[2]),
  .S0(dff_q_0)
);
MUX2 mux_inst_19 (
  .O(douta[3]),
  .I0(dpb_inst_1_douta[3]),
  .I1(dpb_inst_4_douta[3]),
  .S0(dff_q_0)
);
MUX2 mux_inst_24 (
  .O(douta[4]),
  .I0(dpb_inst_2_douta[4]),
  .I1(dpb_inst_4_douta[4]),
  .S0(dff_q_0)
);
MUX2 mux_inst_29 (
  .O(douta[5]),
  .I0(dpb_inst_2_douta[5]),
  .I1(dpb_inst_4_douta[5]),
  .S0(dff_q_0)
);
MUX2 mux_inst_34 (
  .O(douta[6]),
  .I0(dpb_inst_3_douta[6]),
  .I1(dpb_inst_4_douta[6]),
  .S0(dff_q_0)
);
MUX2 mux_inst_39 (
  .O(douta[7]),
  .I0(dpb_inst_3_douta[7]),
  .I1(dpb_inst_4_douta[7]),
  .S0(dff_q_0)
);
MUX2 mux_inst_44 (
  .O(doutb[0]),
  .I0(dpb_inst_0_doutb[0]),
  .I1(dpb_inst_4_doutb[0]),
  .S0(dff_q_1)
);
MUX2 mux_inst_49 (
  .O(doutb[1]),
  .I0(dpb_inst_0_doutb[1]),
  .I1(dpb_inst_4_doutb[1]),
  .S0(dff_q_1)
);
MUX2 mux_inst_54 (
  .O(doutb[2]),
  .I0(dpb_inst_1_doutb[2]),
  .I1(dpb_inst_4_doutb[2]),
  .S0(dff_q_1)
);
MUX2 mux_inst_59 (
  .O(doutb[3]),
  .I0(dpb_inst_1_doutb[3]),
  .I1(dpb_inst_4_doutb[3]),
  .S0(dff_q_1)
);
MUX2 mux_inst_64 (
  .O(doutb[4]),
  .I0(dpb_inst_2_doutb[4]),
  .I1(dpb_inst_4_doutb[4]),
  .S0(dff_q_1)
);
MUX2 mux_inst_69 (
  .O(doutb[5]),
  .I0(dpb_inst_2_doutb[5]),
  .I1(dpb_inst_4_doutb[5]),
  .S0(dff_q_1)
);
MUX2 mux_inst_74 (
  .O(doutb[6]),
  .I0(dpb_inst_3_doutb[6]),
  .I1(dpb_inst_4_doutb[6]),
  .S0(dff_q_1)
);
MUX2 mux_inst_79 (
  .O(doutb[7]),
  .I0(dpb_inst_3_doutb[7]),
  .I1(dpb_inst_4_doutb[7]),
  .S0(dff_q_1)
);
endmodule //charbuf_dpram_large
