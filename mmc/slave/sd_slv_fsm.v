//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

`include "TimeScale.v"
`include "sd_slv_ID_constants.v"
//sd slave state machine
module sd_slv_fsm(
  rst, clk, ind, arg, ok, clr, rsp_end, rca_q,
  ocr_o, 
  cmd_55, acmd_41, e_acmd_41, acmd_06, cmd_02, cmd_03, cmd_07, cmd_09, cmd_10, 
  cmd_16, cmd_17,
  size, c_state
);

  input         rst;
  input         clk;   //host clock
  input  [ 5:0] ind;   //command index
  input  [31:0] arg;   //command argument
  input         ok;    //command parsed okay
  input        clr;    //clear crc
  input    rsp_end;    //respond end
  input [ 15:0] rca_q;
  output        ocr_o; //OCR output
  output        cmd_55;//cmd55
  output       acmd_41;//acmd41
  output     e_acmd_41;//early indication of acmd41
  output       acmd_06;//acmd06
  output        cmd_02;//cmd02
  output        cmd_03;//cmd03
  output        cmd_07;//cmd07
  output        cmd_09;//cmd09
  output        cmd_10;//cmd10
  output        cmd_16;//cmd16
  output        cmd_17;//cmd17
  output          size;//size of response 1 136, 0 48
  output [3:0] c_state;//card status

  reg           ocr_o; //OCR output
  wire          ocr_i; //OCR output
  
  reg [3:0] c_state; //current state
  reg [3:0] n_state; //next    state
  parameter CS_IDLE =4'd0;
  parameter CS_RDEAY=4'd1;
  parameter CS_IDENT=4'd2;
  parameter CS_STBY =4'd3;
  parameter CS_TRAN =4'd4;
  parameter CS_DATA =4'd5;
  parameter CS_RCV  =4'd6;
  parameter CS_PRG  =4'd7;
  parameter CS_DIS  =4'd8;
  
  reg    cmd_00;
  wire   cmd_00i;
  reg    cmd_55;
  wire   cmd_55i;
  reg    acmd_41;
  wire   acmd_41i;
  reg  e_acmd_41;//early indication of acmd41
  wire e_acmd_41i;//early indication of acmd41
  reg    acmd_06;
  wire   acmd_06i;
  reg    cmd_02;
  wire   cmd_02i;
  reg    cmd_03;
  wire   cmd_03i;
  reg    cmd_07;
  wire   cmd_07i;
  reg    cmd_09;
  wire   cmd_09i;
  reg    cmd_10;
  wire   cmd_10i;
  reg    cmd_16;
  wire   cmd_16i;
  reg    cmd_17;
  wire   cmd_17i;
  reg    size;
  wire   sizei;
  
  //When ok pulse arrives, the command indication register is updated.
  assign  cmd_00i=
  ok ? (ind == 6'd0 ) :  cmd_00;
  assign  cmd_02i=ok ? (ind == 6'd2 ) : cmd_02  ? 1'b0 : cmd_02;
  assign  cmd_03i=ok ? (ind == 6'd3 ) : cmd_03  ? 1'b0 : cmd_03;
  assign  cmd_07i=ok ? (ind == 6'd7 ) : cmd_07  ? 1'b0 : cmd_07;
  assign  cmd_09i=ok ? (ind == 6'd9 ) : cmd_09  ? 1'b0 : cmd_09;
  assign  cmd_10i=ok ? (ind == 6'd10) : cmd_10  ? 1'b0 : cmd_10;
  assign  cmd_16i=ok ? (ind == 6'd16) : cmd_16  ? 1'b0 : cmd_16;
  assign  cmd_17i=ok ? (ind == 6'd17) : cmd_17  ? 1'b0 : cmd_17;
  assign  cmd_55i=ok ? (ind == 6'd55) : cmd_55  ? 1'b0 : cmd_55;
  assign acmd_41i=ok ? (ind == 6'd41) : acmd_41 ? 1'b0 : acmd_41;
  assign acmd_06i=ok ? (ind == 6'd6 ) : acmd_06 ? 1'b0 : acmd_06;
  assign ocr_i=cmd_55 & acmd_41;
  assign sizei=
  //Command of size 48 bits
  (ok && (ind == 6'd55 || ind == 6'd41)) ? 1'b0 :
  //Requires a response of 136 bits
  (ok && (ind == 6'd2  || ind == 6'd10 || ind == 6'd9)) ? 1'b1 :
  //Returns to a command of 48 bits after a response of 136 bits.
  (rsp_end                             ) ? 1'b0 :
  size;
  assign e_acmd_41i=(ok && ind == 6'd41) || (e_acmd_41 && !clr);
  
  // synthesis translate_off
  wire [10*8:1] dbg_cs;
  assign dbg_cs=
  (c_state == CS_IDLE ) ? "CS_IDLE"  :
  (c_state == CS_RDEAY) ? "CS_RDEAY" :
  (c_state == CS_IDENT) ? "CS_IDENT" :
  (c_state == CS_STBY ) ? "CS_STBY"  :
  (c_state == CS_TRAN ) ? "CS_TRAN"  :
  (c_state == CS_DATA ) ? "CS_DATA"  :
  (c_state == CS_RCV  ) ? "CS_RCV"   :
  (c_state == CS_PRG  ) ? "CS_PRG"   :
  (c_state == CS_DIS  ) ? "CS_DIS"   :
  "XX_XXXX";
  // synthesis translate_on
  always @(*) begin
    case (c_state)
      CS_IDLE : begin
        if(acmd_41) n_state=CS_RDEAY;
	else        n_state=CS_IDLE;
      end
      CS_RDEAY: begin
        if(cmd_00) n_state=CS_IDLE;
	else begin
          if(cmd_02) n_state=CS_IDENT;
	  else       n_state=CS_RDEAY;
	end
      end
      CS_IDENT: begin
        if(cmd_00) n_state=CS_IDLE;
	else begin
          if(cmd_03) n_state=CS_STBY;
	  else       n_state=CS_IDENT;
	end
      end
      CS_STBY : begin
        if(cmd_00) n_state=CS_IDLE;
	else begin
          if(cmd_07 && rca_q == `RCA) n_state=CS_TRAN;
	  else                        n_state=CS_STBY;
	end
      end
      CS_TRAN : begin
        if(cmd_00) n_state=CS_IDLE;
      end
      CS_DATA : begin
        if(cmd_00) n_state=CS_IDLE;
      end
      CS_RCV  : begin
        if(cmd_00) n_state=CS_IDLE;
      end
      CS_PRG  : begin
        if(cmd_00) n_state=CS_IDLE;
      end
      CS_DIS  : begin
        if(cmd_00) n_state=CS_IDLE;
      end
      default : begin
        n_state=CS_IDLE;
        //AL$display("ERROR FSM at default state at %d ", $time);
        //$finish;
      end
    endcase
  end //always
  
  always @ (posedge clk or posedge rst) begin
    if(rst) begin
      c_state <= CS_IDLE;
       cmd_00 <= 1'b0;
       cmd_55 <= 1'b0;
       cmd_02 <= 1'b0;
       cmd_03 <= 1'b0;
       cmd_07 <= 1'b0;
       cmd_09 <= 1'b0;
       cmd_10 <= 1'b0;
       cmd_16 <= 1'b0;
       cmd_17 <= 1'b0;
      acmd_41 <= 1'b0;
    e_acmd_41 <= 1'b0;
      acmd_06 <= 1'b0;
      ocr_o   <= 1'b0;
         size <= 1'b0;
    end else begin
      c_state <= n_state;
       cmd_00 <=    cmd_00i;
       cmd_55 <=    cmd_55i;
       cmd_02 <=    cmd_02i;
       cmd_03 <=    cmd_03i;
       cmd_07 <=    cmd_07i;
       cmd_09 <=    cmd_09i;
       cmd_10 <=    cmd_10i;
       cmd_16 <=    cmd_16i;
       cmd_17 <=    cmd_17i;
      acmd_41 <=   acmd_41i;
    e_acmd_41 <= e_acmd_41i;
      acmd_06 <=   acmd_06i;
      ocr_o   <=   ocr_i;
         size <=   sizei;
    end
  end


endmodule

