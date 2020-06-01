//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//
`include "TimeScale.v"

//address generator for ROM
module sd_slv_adg (
  rst, clk, bus_width, read, ldad, adln,
  addr, shift, en_rom, sft, stop_en, readq, mem_enq, crc_enq
);
  input  rst;
  input  clk;

  input  [1:0] bus_width; //00-bit 10-nibble
  input        read     ; //read start pulse
  input  [9:0] ldad     ; //starting address
  input  [9:0] adln     ; //data bytes read length
  output [9:0] addr     ; //RAM out  address
  output       shift    ; //shift:: we always read a nibble but in bit mode we
  output       en_rom   ; //read enable for rom
  output       sft      ; //read enable for crc
  output       stop_en  ; //read enable for crc
  output       readq    ; //delayed read pulse
  output       mem_enq  ; //delayed cen_rom
  output       crc_enq  ; //crc enable
  reg          readq    ; //delayed read pulse
  reg          en_romq  ; //read one bit at a time.
  reg          en_rom   ; //read one bit at a time.
  wire         en_romi  ; //read one bit at a time.
  reg          sft      ; //read one bit at a time.
  wire         sfti     ; //read one bit at a time.
  reg          stop_en  ; //read enable for crc
  wire         stop_eni ; //read enable for crc
  reg    [9:0] addr     ; //RAM out  address
  wire   [9:0] addri    ; //RAM out  address
  reg    [9:0] addrend  ; //RAM end  address
  wire   [9:0] addrendi ; //RAM end  address
  reg    [1:0] bitCnt   ; //nibble mode bit count
  wire   [1:0] bitCnti  ; //nibble mode bit count
  reg   [10:0] bit1Cnt  ; //nibble mode bit count
  wire  [10:0] bit1Cnti ; //nibble mode bit count
  reg          shift    ; //shift bit mode
  wire         shifti   ; //shift bit mode

  reg    [9:0] add_lim;
  wire   [9:0] add_limi;

  reg    [3:0] crcCnt;
  wire   [3:0] crcCnti;

  reg          mem_enq;
  wire         mem_eni;
  reg          crc_enq;
  wire         crc_eni;
  wire         crc_endi;
  reg          crc_endq;

  assign crc_eni=
  (!crc_enq && en_rom && !en_romq) || 
  ( crc_enq && bit1Cnt !=  addrend         && bus_width == 2'b10) ||
  ( crc_enq && bit1Cnt != {addrend, 2'b00} && bus_width == 2'b00);
//( crc_enq && addr != addrend && bus_width == 2'b10);

  assign mem_eni=en_rom;
//(!mem_enq && en_rom && !en_romq) || (mem_enq && addr != addrend);

//to debug without the CRC
//assign add_limi=(adln*2)+10'd17;
  assign add_limi=(adln*2);
  //capture end address
  assign addrendi=read ? (ldad + add_lim) : addrend;
  //current address handler
  assign addri=
  read                                      ? ldad   :
  (en_rom && bus_width == 2'b10)            ? addr+1 : //nibble mode
  (en_rom && bus_width == 2'b00 && &bitCnt) ? addr+1 : //bit    mode
  addr;
  assign bitCnti=
  (bus_width == 2'b10          ) ?          2'b00 :
  (bus_width == 2'b00 && read  ) ? bitCnt + 2'b01 : 
  (bus_width == 2'b00 && en_rom) ? bitCnt + 2'b01 : 
  bitCnt;
  assign bit1Cnti=
  readq                                               ?           11'd1 :
  (bit1Cnt == {addrend, 2'b00} && bus_width == 2'b00) ?           11'd0 :
  (bit1Cnt ==  addrend         && bus_width == 2'b10) ?           11'd0 :
  (bit1Cnt   != 11'h0                               ) ? bit1Cnt + 11'd1 :
  bit1Cnt;
  assign shifti=
  (bitCnt != 2'b11 && bus_width == 2'b00) ? 1'b1 : 1'b0;
  //read enable for ROM
  assign en_romi=
  //start condition same for 1 or 4 bus width
  (!en_rom && read) || 
  //stop conditions
//( en_rom && addr != addrend   );
  ( en_rom && bit1Cnt != addrend          && bus_width == 2'b10) ||
  ( en_rom && bit1Cnt != {addrend, 2'b00} && bus_width == 2'b00);
  //read enable for CRC
  assign crc_endi=crcCnt != 4'd15;
  assign sfti=(
    (!sft && !crc_eni && crc_enq) || //set when ROM enable changes from H to L.
    ( sft && crc_endq           )
  );
  assign stop_eni=~sfti & sft;
  assign crcCnti=
  (crcCnt != 4'd0) ? (crcCnt + 4'd1) : //count
  sft              ?           4'd1  : crcCnt;
  
  
  always @ (posedge clk or posedge rst) begin
    if(rst) begin
      add_lim <= 10'h0;
      addr    <= 10'h0;
      addrend <= 10'h0;
      bitCnt  <=  2'h0;
      bit1Cnt <= 11'd0;
      shift   <=  1'b0;
      en_rom  <=  1'b0;
      en_romq <=  1'b0;
      sft     <=  1'b0;
      stop_en <=  1'b0;
      crcCnt  <=  4'd0;
      crc_endq<=  1'b0;
      readq   <=  1'b0; //delayed read pulse
      mem_enq <=  1'b0;
      crc_enq <=  1'b0;
    end
    else begin
      add_lim <= add_limi;
      addr    <= addri;
      addrend <= addrendi;
      bitCnt  <= bitCnti;
      bit1Cnt <= bit1Cnti;
      shift   <= shifti;
      en_romq <= en_rom;
      en_rom  <= en_romi;
      sft     <= sfti;
      stop_en <= stop_eni;
      crcCnt  <= crcCnti;
      crc_endq<= crc_endi;
      readq   <= read; //delayed read pulse
      mem_enq <= mem_eni;
      crc_enq <= crc_eni;
    end
  end
  

endmodule

