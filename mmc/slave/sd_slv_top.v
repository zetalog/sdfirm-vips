//
// Copyright (c) Pini Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

`include "TimeScale.v"
`include "sd_slv_ID_constants.v"

//sd slave top
module sd_slv_top(DATA0, DATA1, DATA2, DATA3, CMD, CLK, rst);
  output      DATA0;
  output      DATA1;
  output      DATA2;
  output      DATA3;
  inout       CMD;
  input       CLK;
  input       rst;

  wire  [ 5:0] ind;
  wire  [31:0] arg;
  wire         ok;
  wire         ocr_o;
  wire         cmd_55;
  wire         cmd_02;
  wire         cmd_03;
  wire         cmd_07;
  wire         cmd_09;
  wire         cmd_10;
  wire         cmd_16;
  wire         cmd_17;
  wire        acmd_41;
  wire      e_acmd_41;
  wire        acmd_06;
  wire [135:0] rsp;
  wire         size;
  wire         start_rsp;
  wire         rsp_end;

  //crc output
  wire         crc_clrq;
  wire         cmd_inq2;
  wire         crc_calc_enq;
  wire   [6:0] crc_clac;

  wire         rsp_oe;
  wire         rsp_od;
  wire         rsp_oe1;
  wire         rsp_od1;
  wire         crc_calc;
  wire         rsp_clrq;
  wire [ 15:0] rca_q;
  wire [126:0] csdR;
  wire [ 31:0] blk_len_by;
  wire [  1:0] bus_width;
  wire [  3:0] c_state;
  wire [ 31:0] start_add_q;
  //
  wire       clr_mx;
  wire       din_mx;
  wire       cen_mx;
  wire       ind_clr;
  
  //Temporary     55 no error crc + end bit 
  //(just for testing the first response)
  assign rsp=cmd_55 ? {
    27'b00_110111_0000000000000000000, c_state, 9'b000000000, 8'b0000000_1,
    88'h0
  } : 
  //R3
  acmd_41 ? {
  //27'b00_101001_0000000000000000000, c_state, 9'b000100000, 8'b0000000_1,
    27'b00_111111_0000000000000000000, c_state, 9'b000100000, 8'b1111111_1,
    88'h0
  } : 
  acmd_06 ? {
    27'b00_000110_0000000000000000000, c_state, 9'b000100000, 8'b0000000_1,
    88'h0
  } : 
  //always respond
  cmd_02                    ? {8'b00_111111, `CID, `STOP_BIT} :
  //if my address, I shall respond.
  (cmd_10 && rca_q == `RCA) ? {8'b00_111111, `CID, `STOP_BIT} :
  //if my address, I shall respond.
  (cmd_09 && rca_q == `RCA) ? {8'b00_111111, csdR, `STOP_BIT} :
  //              command code              0 for CRC + stop bit
  cmd_03 ? {8'b00_000011, `RCA, `R6_NO_ERR, 8'h01, 88'h0} :
  //R1b a response tp cmd_07
  cmd_07 ? {
    27'b00_000111_0000000000000000000, c_state, 9'b000000000, 8'b0000000_1,
    88'h0
  } : 
  //cmd16 R1 response
  cmd_16 ? { 
    27'b00_010000_0000000000000000000, c_state, 9'b000000000, 8'b0000000_1,
    88'h0
  } : 
  //cmd17 R1 response
  cmd_17 ? { 
    27'b00_010001_0000000000000000000, c_state, 9'b000000000, 8'b0000000_1,
    88'h0
  } : 
  {136{1'b1}};
  
  assign start_rsp=
  cmd_55|acmd_41|cmd_02|cmd_03|cmd_10|cmd_09|cmd_07|cmd_16|acmd_06|cmd_17;

  assign CMD = rsp_oe1 ? rsp_od1 : 1'bZ;

  sd_slv_reg u_reg (
    .rst(rst),
    .clk(CLK),
    //outputs - registers
    .csdR(csdR)
  ); //sd_slv_reg u_reg
  sd_slv_cmr u_cmr (
    .rst(rst),
    .clk(CLK),
    .cmd_in(CMD),
    .ind_clr(ind_clr),
    .size(size ),//1 136, 0 48 bits
    .ind(ind),
    .arg(arg),
    .ok (ok ),
    .rsp_end(rsp_end),
    .acmd_06(acmd_06),
    .c_state(c_state),  //card status
//crc output
    .crc_clrq(crc_clrq),
    .cmd_inq2(cmd_inq2),
    .crc_calc_enq(crc_calc_enq),
    .crc_clac(crc_clac),
    .rca_q(rca_q),          //captured rca
    //block length
    .cmd_16     (cmd_16     ),//input 
    .cmd_17     (cmd_17     ),//input 
    .blk_len_by (blk_len_by ),//block length bytes
    .bus_width  (bus_width  ),//data bus width
    .start_add_q(start_add_q) //read (cmd_17) start address
  );//sd_slv_cmr u_cmr
  sd_slv_fsm u_fsm (
    .rst(rst),
    .clk(CLK),
    .ind(ind),
    .arg(arg),
    .ok (ok ),
    .clr(clr_mx),
    .rsp_end(rsp_end),
    .rca_q(rca_q), //captured rca
    //outputs
    .ocr_o  (ocr_o  ),
    .cmd_55 (cmd_55 ),
    .acmd_41(acmd_41),
    .e_acmd_41(e_acmd_41),
    .acmd_06(acmd_06),
    .cmd_02 (cmd_02 ),
    .cmd_03 (cmd_03 ),
    .cmd_07 (cmd_07 ),
    .cmd_09 (cmd_09 ),
    .cmd_10 (cmd_10 ),
    .cmd_16 (cmd_16 ),
    .cmd_17 (cmd_17 ),
    .size(size)      ,  //1 136, 0 48 bits
    .c_state(c_state)   //card status
  );//sd_slv_fsm u_fsm
  sd_slv_rsp u_rsp (
    .rst(rst),
    .clk(CLK),
    
    .din (rsp ), //reponse data 136 or 48 bits
    .size(size), //1 136, 0 48 bits

    .crc  (crc_clac ),
    .start(start_rsp),  //start response (level)
    //outputs
    .cmd_od (rsp_od ),  //repsonse command data
    .cmd_oe (rsp_oe ),
    .cmd_od1(rsp_od1),  //repsonse command data
    .cmd_oe1(rsp_oe1),
    .crc_calc(crc_calc),
    .crc_clrq(rsp_clrq),
    .ind_clr (ind_clr)
  );//sd_slv_rsp u_rsp

  //                     response   command
  assign clr_mx=rsp_oe ? rsp_clrq : crc_clrq;
  assign din_mx=rsp_oe ? rsp_od   : cmd_inq2;
  assign cen_mx=rsp_oe ? crc_calc : crc_calc_enq;
  //The module is used both for command check and response generation.
  sd_slv_cr7 u_crc7 (
    .rst(rst),  
    .clk(CLK),  
    .clr(clr_mx),    //clr crc registers
    .din(din_mx),    //Data in for crc 
    .cen(cen_mx),    //enable crc
    .all_one(e_acmd_41), //force all ones
    .crc(crc_clac)   //Data output of crc result
  );//sd_slv_cr7 u_crc7

  wire [3:0] mem_data;
  wire       mem_Doen;
  sd_slv_mem u_mem ( //memory module
    .rst(rst),
    .clk(CLK),
    
    .bus_width(bus_width  ),
    .read     (cmd_17     ),
    .ldad(start_add_q[9:0]),
    .adln( blk_len_by[9:0]),

    .e(mem_Doen),
    .q(mem_data) 
  );//sd_slv_mem u_mem
  //because of icarus bug I drive 1 instead of z
  assign DATA3=(bus_width == 2'b10 && mem_Doen) ? mem_data[3] : 1'bz;
  assign DATA2=(bus_width == 2'b10 && mem_Doen) ? mem_data[2] : 1'bz;
  assign DATA1=(bus_width == 2'b10 && mem_Doen) ? mem_data[1] : 1'bz;
  assign DATA0=(                      mem_Doen) ? mem_data[0] : 1'bz;



endmodule

