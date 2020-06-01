//
// Copyright (c) 1999-2000 Pinhas Krengel.  Permission to copy is granted
// provided that this header remains intact.  This software is provided
// with no warranties.
//

// SD slave CSD register
`define CSD_STRUCTURE      2'b00            //127:126
`define RESERVED_125       6'b00_0000       //125:120
`define TAAC               8'h00            //119:112
`define NSAC               8'h00            //111:104
`define TRAN_SPEED         8'h32            //103: 96  max is 8'h5a
`define CCC               12'b010110110101  // 95: 84
`define READ_BL_LEN        4'h0             // 83: 80
`define READ_BL_PARTIAL    1'b1             // 79: 79
`define WRITE_BLK_MISALIGN 1'b0             // 78: 78
`define  READ_BLK_MISALIGN 1'b0             // 77: 77
`define DSR_IMP            1'b0             // 76: 76
`define RESERVED_75        2'b00            // 75: 74
`define C_SIZE            12'h000           // 73: 62
`define VDD_R_CURR_MIN     3'b000           // 61: 59
`define VDD_R_CURR_MAX     3'b000           // 58: 56
`define VDD_W_CURR_MIN     3'b000           // 55: 53
`define VDD_W_CURR_MAX     3'b000           // 52: 50
`define C_SIZE_MULT        3'b000           // 49: 47
`define ERASE_BLK_EN       1'b0             // 46: 46
`define SECTOR_SIZE        7'b0000000       // 45: 39
`define WP_GRP_SIZE        7'b0000000       // 38: 32
`define WP_GRP_ENABLE      1'b0             // 31: 31
`define RESERVED_30        2'b00            // 30: 29
`define R2W_FACTOR         3'b000           // 28: 26
`define WRITE_BL_LEN       4'h0             // 25: 22
`define WRITE_BL_PARTIAL   1'b0             // 21: 21
`define RESERVED_20        5'b00000         // 20: 16
`define FILE_FORMAT_GRP    1'b0             // 15: 15
`define COPY               1'b0             // 14: 14
`define PERM_WRITE_PROTECT 1'b0             // 13: 13
`define  TMP_WRITE_PROTECT 1'b0             // 12: 12
`define FILE_FORMAT        2'b00            // 11: 10
`define RESERVED_9         2'b00            //  9:  8
`define CRC_CSD            7'b0000000       //  7:  1
`define STOP_CSD           1'b1             //  0:  0
