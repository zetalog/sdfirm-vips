//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

`include "TimeScale.v"
//sd slave response 
//outputs the response and calculates the crc and sets start and stop bits.
module sd_slv_rsp (
  rst, clk, din, size, crc, start, 
  cmd_od, cmd_oe, cmd_od1, cmd_oe1, 
  crc_calc, crc_clrq, ind_clr
);
  input          rst;
  input          clk;   //host clock
  input  [135:0] din;   //reponse data 136 or 48 bits
  input         size;   //1 136, 0 48 bits
  input  [  6:0] crc;   //crc in
  input        start;   //start response (level)
  output      cmd_od;   //command data
  output      cmd_oe;   //command output enable
  output      cmd_od1;  //command data
  output      cmd_oe1;  //command output enable
  output      crc_calc;
  output      crc_clrq;
  output      ind_clr;

  //One output stream to calculate CRC.
  //One output stream for SD data out.
  reg        start_q;
  reg  [  7:0] cnt_q;
  wire [  7:0] cnt_i;
  reg  [135:0] din_q;   //reponse data 136 or 48 bits
  wire [135:0] din_i;   //reponse data 136 or 48 bits
  reg          cmd_oe;
  wire         cmd_oei;
  reg          crc_clrq;
  wire         crc_clri;
  reg          cmd_oe1;
  wire         cmd_oe1i;
  reg          cmd_od1;
  wire         cmd_od1i;
  reg          cmd_od0;
  reg          crc_calc;
  wire         crc_calci;
  reg          crc_mux;
  wire         crc_muxi;
  reg  [  6:0] crc_q;
  wire [  6:0] crc_i;
  reg          ind_clr;
  wire         ind_clri;

  //timing counter
  assign cnt_i=
  (start && !start_q &&  size) ? 8'd137 :
  (start && !start_q && !size) ? 8'd49  :
  (|cnt_q)                     ? (cnt_q - 8'd1) :
  cnt_q;

  //Data register. Load input and shift for output.
  assign din_i  =!(|cnt_q) ? din : {din_q[134:0], 1'b0};
  assign cmd_oei=(!cmd_oe && start && !start_q) || (cmd_oe && cnt_q != 8'd2);
  assign cmd_od=din_q[135];
  assign crc_clri=(cnt_q == 8'd1);
  assign cmd_oe1i =
  //set condition
  (!size && !cmd_oe1 && cnt_q == 8'd48 ) || 
  ( size && !cmd_oe1 && cnt_q == 8'd136) || 
  //clr condition
  (          cmd_oe1 && cnt_q != 8'd0 );
  assign ind_clri=cmd_oe1i & ~cmd_oe1;
  assign crc_calci=
  //start
  (!crc_calc && start && !start_q && !size) || 
  (!crc_calc && cnt_q == 8'd130   &&  size) || 
  //stop
  ( crc_calc && cnt_q != 8'd10);
  assign crc_muxi=(!crc_mux && cnt_q == 8'd9) || (crc_mux && cnt_q != 8'd2);
  assign cmd_od1i=!crc_mux ? cmd_od0 : crc_q[6];
  assign crc_i   =!crc_mux ? crc : {crc_q[6:0], 1'b0};
  
  

  always @ (posedge clk or posedge rst) begin
    if(rst) begin
      cnt_q   <= 8'h0;
      start_q <= 1'b0;
      din_q   <= 136'h0;
      cmd_oe  <= 1'b0;
      crc_clrq<= 1'b0;
      cmd_oe1 <= 1'b0;
      ind_clr <= 1'b0;
      cmd_od1 <= 1'b0;
      cmd_od0 <= 1'b0;
      crc_calc<= 1'b0;
      crc_mux <= 1'b0;
      crc_q   <= 7'd0;
    end else begin
      cnt_q   <= cnt_i;
      start_q <= start;
      din_q   <= din_i;
      cmd_oe  <= cmd_oei;
      crc_clrq<= crc_clri;
      cmd_oe1 <= cmd_oe1i;
      ind_clr <= ind_clri;
      cmd_od1 <= cmd_od1i;
      cmd_od0 <= cmd_od;
      crc_calc<= crc_calci;
      crc_mux <= crc_muxi;
      crc_q   <= crc_i;
    end
  end //always

endmodule

