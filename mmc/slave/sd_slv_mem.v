//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

`include "TimeScale.v"
//memory module : address generator + ROM vendor specific
module sd_slv_mem (
  rst, clk,
  bus_width, read, ldad, adln,
  e, q
);
  input  rst;
  input  clk;

  input  [1:0] bus_width; //00-bit 10-nibble
  input        read     ; //read start pulse (cmd_17 or like)
  input  [9:0] ldad     ; //starting address
  input  [9:0] adln     ; //data bytes read length
  output       e        ; //memory data output enable
  output [3:0] q        ; //memory data out

  wire   [9:0] addr     ; //RAM out  address
  wire         shift    ; //address register shift for bit mode read
  wire         sft      ; //crc + stop bit enable
  wire   [3:0] qi       ; //memory data internal
  wire         cen_rom  ; //ROM read enable
  wire         crcC     ; //crc clear
  wire [3:0]   crc_16   ; //crc bit per each data bit
  wire         stop_en  ;
  wire         ei       ;
  
  // AL ??
  wire mem_enq;

  assign ei=mem_enq|sft|stop_en;
//assign ei=mem_enq|sft;   
     
  sd_slv_adg u_adg ( //memorry address generator
    .rst(rst),
    .clk(clk),
  
    .bus_width(bus_width), //00-bit 10-nibble
    .read     (read     ), //read start pulse
    .ldad     (ldad     ), //starting address
    .adln     (adln     ), //data bytes read length
    .addr     (addr     ), //RAM out  address
    .shift    (shift    ), //shift:: we always read a nibble but in bit mode we
    .en_rom   (cen_rom  ), //ROM read enable
    .sft      (sft      ), //read one bit at a time.
    .stop_en  (stop_en  ), //stop bit output enable
    .readq    (readq    ), //delayed read pulse
    .mem_enq  (mem_enq  ), //delayed cen_rom
    .crc_enq  (crc_enq  )  //crc enable
  );//sd_slv_adg u_adg

  sd_slv_rom u_rom (
    .a(addr   ), //address
    .e(cen_rom), //enable
    .s(shift  ), //shift
    .q(qi     ), //memory data out
    .ck(clk   ) 
  );//sd_slv_rom u_rom

  sd_slv_c16 u_c16A (
    .rst(rst    ),
    .clk(clk    ),
    .clr(crcC   ),
    .din(qi[0]  ),
    .cen(crc_enq),//crc calc enable
    .sft(sft    ),//crc shift
    .q  (crc_16[0]) 
  );//sd_slv_c16 u_c16A
  sd_slv_c16 u_c16B (
    .rst(rst    ),
    .clk(clk    ),
    .clr(crcC   ),
    .din(qi[1]  ),
    .cen(crc_enq),//crc calc enable
    .sft(sft    ),//crc shift
    .q  (crc_16[1]) 
  );//sd_slv_c16 u_c16B
  sd_slv_c16 u_c16C (
    .rst(rst    ),
    .clk(clk    ),
    .clr(crcC   ),
    .din(qi[2]  ),
    .cen(crc_enq),//crc calc enable
    .sft(sft    ),//crc shift
    .q  (crc_16[2]) 
  );//sd_slv_c16 u_c16C
  sd_slv_c16 u_c16D (
    .rst(rst    ),
    .clk(clk    ),
    .clr(crcC   ),
    .din(qi[3]  ),
    .cen(crc_enq),//crc calc enable
    .sft(sft    ),//crc shift
    .q  (crc_16[3]) 
  );//sd_slv_c16 u_c16D

  sd_slv_Rmx u_Rmx (//ROM data MUX
    .rst    (rst    ),
    .clk    (clk    ),
    .read   (readq  ), //one clock delayed read start pulse
    .cen    (sft    ), //crc + stop bit enable
    .stop_en(stop_en), //stop bit output enable
    .cen_rom(cen_rom), //ROM read enable
    .din    (qi     ), //rom data in
    .crc    (crc_16 ), //CRC data in
    //
    .ei     (ei     ),
    .e      (e      ),
    //
    .crcC(crcC  ), //crc clear
    .dout(q     )
  );//sd_slv_Rmx u_Rmx



endmodule

