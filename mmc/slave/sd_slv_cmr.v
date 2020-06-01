
//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

`include "TimeScale.v"
//sd slave command read
//Listens to the command line and parses each command.
//Check CRC of the command as well as start and stop bits.
module sd_slv_cmr(
  rst, clk, cmd_in, ind_clr, size, ind, arg, ok, rsp_end, acmd_06, c_state,
  crc_clrq, cmd_inq2, crc_calc_enq, crc_clac, rca_q, 
  cmd_16, cmd_17, blk_len_by, bus_width, start_add_q
);
input         rst;
input         clk;   //host clock
input         cmd_in;//host command line
input        ind_clr;//ind clear (during response)
input         size  ;//1 136, 0 48 bits
output [ 5:0] ind;   //command index
output [31:0] arg;   //command argument
output        ok;    //command parsed okay
output   rsp_end;    //respond end
input    acmd_06;
input  [3:0] c_state;//card status 
//crc output
output        crc_clrq;
output        cmd_inq2;
output        crc_calc_enq;
input   [6:0] crc_clac;
output [15:0]    rca_q;
input         cmd_16;
input         cmd_17;
output [31:0] blk_len_by;
output [ 1:0] bus_width;
output [31:0] start_add_q;



reg           ok;    //command parsed okay
wire          ok1;
reg       rsp_end;   //respond end
wire      rsp_endi;  //respond end

//              0  1  2   7  8 39 40 46 47
//bit position 47 46 45..40 39..8 7..1 0
//value         0  1 x      x     x    1
//description  start
//description      transmission
//description        command index
//description               argument
//description                     crc7
//description                          end bit

reg [1:0] ps, ns;
parameter IDLE=2'b00;
parameter CINP=2'b01;//command parse in progress
parameter CRCM=2'b10;//CRC compare

reg        crc_calc_enq; //crc calculate enable
wire       crc_calc_eni; //crc calculate enable
reg        crc_from_cmq; //crc from command enable
wire       crc_from_cmi; //crc from command enable
reg  [6:0] crc_regq;
wire [6:0] crc_regi;

reg        cmd_q;
wire       cmd_start;
wire       rsp_start;
reg  [7:0] rsp_cnt_q;
wire [7:0] rsp_cnt_i;
reg  [7:0] cmd_cnt_q;
wire [7:0] cmd_cnt_i;

reg  crc_clrq;
wire crc_clri;

//delay the cmd_in by two
reg  cmd_inq1, cmd_inq2;

reg         ind_shiftq;
wire        ind_shifti;
reg  [ 5:0] ind;   //command index
wire [ 5:0] indi; 
//
reg         arg_shiftq;
wire        arg_shifti;
reg  [31:0] arg;   //command argument
wire [31:0] argi; 

reg  [15:0] rca_q;
wire [15:0] rca_i;
reg         rca_shift_q;
wire        rca_shift_i;
//
reg  [31:0] blk_len_by;
wire [31:0] blk_len_byi;
reg  [31:0] cmd_reg_in_q;
wire [31:0] cmd_reg_in_i;
reg         reg_shift_q;
wire        reg_shift_i;
reg  [ 1:0] bus_width;
wire [ 1:0] bus_widthi;
reg  [ 1:0] bus_width_q;
wire [ 1:0] bus_width_i;
reg  [31:0] start_add_q;
wire [31:0] start_add_i;

assign rca_shift_i=
(!rca_shift_q && cmd_cnt_q == 8'd8) || (rca_shift_q && cmd_cnt_q != 8'd23);
assign rca_i=rca_shift_q ? {rca_q[14:0], cmd_in} : rca_q;
//
assign reg_shift_i=
(!reg_shift_q && cmd_cnt_q == 8'd8) || (reg_shift_q && cmd_cnt_q != 8'd39);
assign cmd_reg_in_i=reg_shift_q ? {cmd_reg_in_q[30:0], cmd_in} : cmd_reg_in_q;
assign blk_len_byi=cmd_16  ? cmd_reg_in_q      : blk_len_by;
assign start_add_i=cmd_17  ? cmd_reg_in_q      : start_add_q;
assign bus_widthi =acmd_06 ? cmd_reg_in_q[1:0] : bus_width;

//crc calculate enable
assign crc_calc_eni=
//set
(!crc_calc_enq && cmd_start) || 
//clear
( crc_calc_enq && cmd_cnt_q != 8'd41  && !size) ||
( crc_calc_enq && cmd_cnt_q != 8'd129 &&  size);

//crc from command
assign crc_regi    =crc_from_cmq ? {crc_regq[5:0], cmd_in} : crc_regq;
assign crc_from_cmi=
//set
(!crc_from_cmq && cmd_cnt_q == 8'd39  && !size) || 
(!crc_from_cmq && cmd_cnt_q == 8'd127 &&  size) || 
//clr
( crc_from_cmq && cmd_cnt_q != 8'd46  && !size) ||
( crc_from_cmq && cmd_cnt_q != 8'd134 &&  size);


//A command  starts with 01, when the command count is zero.
//A response starts with 00, when the command count is zero.
assign cmd_start=!(|cmd_cnt_q) && !(|rsp_cnt_q) && ( cmd_in && !cmd_q);
assign rsp_start=!(|cmd_cnt_q) && !(|rsp_cnt_q) && (!cmd_in && !cmd_q);
assign rsp_endi =rsp_cnt_q == 8'd135;

assign rsp_cnt_i=
( rsp_cnt_q == 8'd0   && rsp_start) ? 8'd2              : 
( rsp_cnt_q == 8'd47  && !size    ) ? 8'd0              :
( rsp_cnt_q == 8'd135 &&  size    ) ? 8'd0              :
(|rsp_cnt_q)                        ?(rsp_cnt_q + 8'd1) :
rsp_cnt_q;
assign cmd_cnt_i=
( cmd_cnt_q == 8'd0   && cmd_start) ? 8'd2              : 
( cmd_cnt_q == 8'd47  && !size    ) ? 8'd0              :
( cmd_cnt_q == 8'd135 &&  size    ) ? 8'd0              :
(|cmd_cnt_q)                        ?(cmd_cnt_q + 8'd1) :
cmd_cnt_q;

//ok is assert when we are at time slot #47/135 and crc is matched.
assign crc_clri=(
  (!size && cmd_cnt_q == 8'd46) || (size && cmd_cnt_q == 8'd133) ||
  (!size && rsp_cnt_q == 8'd46) || (size && rsp_cnt_q == 8'd133)
);
assign oki     =crc_clrq && (crc_clac == crc_regq);

//command index shift enable
assign ind_shifti=
(!ind_shiftq && cmd_start) || (ind_shiftq && cmd_cnt_q != 8'd7);
assign indi=
ind_clr    ? 6'd0               :
ind_shiftq ? {ind[4:0], cmd_in} : 
ind;

//command argument shift enable
assign arg_shifti=
(!arg_shiftq && cmd_cnt_q == 8'd7) || 
( arg_shiftq && cmd_cnt_q != 8'd39);
assign argi=arg_shiftq ? {arg[30:0], cmd_in} : arg;



always @ (posedge clk or posedge rst) begin
  if(rst) begin
    cmd_q       <= 1'b1;
    cmd_cnt_q   <= 8'd0;
    rsp_cnt_q   <= 8'd0;
    crc_calc_enq<= 1'b0;
    crc_regq    <= 7'h0;
    crc_from_cmq<= 1'b0;
    cmd_inq1    <= 1'b1;
    cmd_inq2    <= 1'b1;
    crc_clrq    <= 1'b0;
    ok          <= 1'b0;
    ind_shiftq  <= 1'b0;
    ind         <= 6'h0;
    arg_shiftq  <= 1'b0;
    arg         <=32'h0;
    rsp_end     <= 1'b0;
    rca_q       <=16'h0;
    rca_shift_q <= 1'b0;
    blk_len_by  <=32'h0;
    start_add_q <= 1'b0;
    cmd_reg_in_q<=32'h0;
    bus_width   <= 1'b0;
    bus_width_q <= 1'b0;
    reg_shift_q <= 1'b0;
  end else begin
    cmd_q       <= cmd_in;
    cmd_cnt_q   <= cmd_cnt_i;
    rsp_cnt_q   <= rsp_cnt_i;
    crc_calc_enq<= crc_calc_eni;
    crc_regq    <= crc_regi;
    crc_from_cmq<= crc_from_cmi;
    cmd_inq1    <= cmd_in;
    cmd_inq2    <= cmd_inq1;
    crc_clrq    <= crc_clri;
    ok          <= oki;
    ind_shiftq  <= ind_shifti;
    ind         <= indi;
    arg_shiftq  <= arg_shifti;
    arg         <= argi;
    rsp_end     <= rsp_endi;
    rca_q       <= rca_i;
    rca_shift_q <= rca_shift_i;
    blk_len_by  <= blk_len_byi;
    start_add_q <= start_add_i;
    cmd_reg_in_q<= cmd_reg_in_i;
    bus_width   <= bus_widthi;
    bus_width_q <= bus_width_i;
    reg_shift_q <= reg_shift_i;
  end
end

endmodule

