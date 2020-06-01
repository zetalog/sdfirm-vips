//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

`include "TimeScale.v"
//memory mux module : outputs data, start, stop bits and crc
module sd_slv_Rmx (
  rst, clk,
  read, cen, stop_en, cen_rom,
  din, crc,
  ei, e,
  crcC, dout
);
  input  rst;
  input  clk;

  input        read;//read start pulse
  input        cen ;//crc + stop bit enable
  input     stop_en;//crc + stop bit enable
  input     cen_rom;//ROM read enable
  input  [3:0] din; //ROM data in
  input  [3:0] crc; //CRC data in
  input        ei ;
  output       e  ;
  output       crcC;//crc clear
  output [3:0] dout;
  reg    [3:0] dout;
  wire   [3:0] douti;

  reg    [3:0] dinq;
  reg          cen_romq;
  reg          readq   ;
  reg          cenq    ;
  reg          e       ;
  reg          stop_enq;
  reg    [3:0] crcq    ; //CRC data in sampled

  assign douti=
  readq   ? 4'h0 : 
  cen_romq? dinq : 
  stop_en ? 4'hf :
  cenq    ? crcq : 1'b1;
  assign crcC =read;

  always @ (posedge clk or posedge rst) begin
    if(rst) begin
      dinq    <= 4'h0;
      dout    <= 4'h0;
      e       <= 1'b0;
      readq   <= 1'b0;
      cen_romq<= 1'b0;
      cenq    <= 1'b0;
      crcq    <= 4'h0;
      stop_enq<= 1'b0;
    end else begin
      dinq    <= din;
      dout    <= douti;
      e       <= ei;
      readq   <= read;
      cen_romq<= cen_rom;
      cenq    <= cen;
      crcq    <= crc;
      stop_enq<= stop_en;
    end
  end

endmodule

