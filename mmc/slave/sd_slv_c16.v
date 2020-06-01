//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

`include "TimeScale.v"
//Calculates CRC16
module sd_slv_c16(rst, clk, clr, din, cen, sft, q);
  input         rst;
  input         clk;
  input         clr;
  input         din;
  input         cen;
  input         sft; //crc shift
  output        q  ;

  reg  [15:0] C;
  wire [15:0] d;
  wire [15:0] dCrc;
  wire i;

  assign q=C[15];
  assign i=din ^ C[15];
  assign d=cen ? dCrc : sft ? {C[14:0], 1'b0} : C;
  
  assign dCrc=
  {C[14:12], C[11], C[10:5]  , C[4], C[3:0] , 1'b0} ^
  {3'b000  , i    , 6'b000000, i   , 4'b0000, i   };


always @ (posedge clk or posedge rst) begin
  if(rst) begin
    C <= 16'h0;
  end else begin
    if(clr) begin
      C <= 16'h0;
    end else begin
      C<=d;
    end
  end
end

endmodule

