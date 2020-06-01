//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

`include "TimeScale.v"
//Calculates CRC7
module sd_slv_cr7(rst, clk, clr, din, cen, all_one, crc);
  input        rst;
  input        clk;
  input        clr;
  input        din;
  input        cen;
  input        all_one; //force all ones
  output [6:0] crc;

  reg  q6, q5, q4, q3, q2, q1, q0;
  wire d6, d5, d4, d3, d2, d1, d0;

  assign d0=din^q6;
  assign d1=q0;
  assign d2=q1;
  assign d3=q2^d0;
  assign d4=q3;
  assign d5=q4;
  assign d6=q5;
  assign crc={q6, q5, q4, q3, q2, q1, q0};


always @ (posedge clk or posedge rst) begin
  if(rst) begin
    q0<=1'b0;
    q1<=1'b0;
    q2<=1'b0;
    q3<=1'b0;
    q4<=1'b0;
    q5<=1'b0;
    q6<=1'b0;
  end else begin
    if(clr) begin
        q0<=1'b0;
        q1<=1'b0;
        q2<=1'b0;
        q3<=1'b0;
        q4<=1'b0;
        q5<=1'b0;
        q6<=1'b0;
    end else begin
      if(all_one) begin
        q0<=1'b1;
        q1<=1'b1;
        q2<=1'b1;
        q3<=1'b1;
        q4<=1'b1;
        q5<=1'b1;
        q6<=1'b1;
      end else begin
        if(cen) begin
          q0<=d0;
          q1<=d1;
          q2<=d2;
          q3<=d3;
          q4<=d4;
          q5<=d5;
          q6<=d6;
        end
      end
    end
  end
end

endmodule

