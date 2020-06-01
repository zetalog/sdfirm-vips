//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

`include "TimeScale.v"
`include "sd_slv_CSD_constants.v"
//sd slave registers
//write if register write command is detected.
//output the register.
module sd_slv_reg(
  rst, clk, 
  csdR
);
input          rst;
input          clk;
output [126:0] csdR;
reg    [126:0] csdR;

always @ (posedge clk or posedge rst) begin
  if(rst) begin
    csdR <= 127'h0;
  end
  else begin
    csdR <= {
      `CSD_STRUCTURE,
      `RESERVED_125,
      `TAAC,
      `NSAC,
      `TRAN_SPEED,
      `CCC,
      `READ_BL_LEN,
      `READ_BL_PARTIAL,
      `WRITE_BLK_MISALIGN,
      `READ_BLK_MISALIGN,
      `DSR_IMP,
      `RESERVED_75,
      `C_SIZE,
      `VDD_R_CURR_MIN,
      `VDD_R_CURR_MAX,
      `VDD_W_CURR_MIN,
      `VDD_W_CURR_MAX,
      `C_SIZE_MULT,
      `ERASE_BLK_EN,
      `SECTOR_SIZE,
      `WP_GRP_SIZE,
      `WP_GRP_ENABLE,
      `RESERVED_30,
      `R2W_FACTOR,
      `WRITE_BL_LEN,
      `WRITE_BL_PARTIAL,
      `RESERVED_20,
      `FILE_FORMAT_GRP,
      `COPY,
      `PERM_WRITE_PROTECT,
      `TMP_WRITE_PROTECT,
      `FILE_FORMAT,
      `RESERVED_9,
      `CRC_CSD
    };
  end
end

endmodule

