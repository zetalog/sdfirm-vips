/*
 * ZETALOG's Personal COPYRIGHT
 *
 * Copyright (c) 2019
 *    ZETALOG - "Lv ZHENG".  All rights reserved.
 *    Author: Lv "Zetalog" Zheng
 *    Internet: zhenglv@hotmail.com
 *
 * This COPYRIGHT used to protect Personal Intelligence Rights.
 * Redistribution and use in source and binary forms with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    This product includes software developed by the Lv "Zetalog" ZHENG.
 * 3. Neither the name of this software nor the names of its developers may
 *    be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 * 4. Permission of redistribution and/or reuse of souce code partially only
 *    granted to the developer(s) in the companies ZETALOG worked.
 * 5. Any modification of this software should be published to ZETALOG unless
 *    the above copyright notice is no longer declaimed.
 *
 * THIS SOFTWARE IS PROVIDED BY THE ZETALOG AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE ZETALOG OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * @(#)jtag_dpi.v: jtag DPI-C module verilog part
 * $Id: jtag_dpi.v,v 1.1 2020-05-29 13:15:00 zhenglv Exp $
 */

`define CMD_RESET		0
`define CMD_TMS_SEQ		1
`define CMD_SCAN_CHAIN		2
`define CMD_SCAN_CHAIN_FLIP_TMS	3
`define CMD_STOP_SIMU		4

import "DPI-C" function void c_jtag_init();
import "DPI-C" function void c_jtag_exit();
import "DPI-C" function bit c_jtag_read(output int cmd,
					output int length,
					output reg[31:0] buffer_out[4096]);
import "DPI-C" function bit c_jtag_write(input int length,
					 input reg[31:0] buffer_in[4096]);

module jtag_dpi #(
`ifdef JTAG_DPI_DEBUG
  parameter DEBUG_INFO = 1,
`else
  parameter DEBUG_INFO = 0,
`endif
  parameter TP = 1,
  // Clock half period (clock period = 100 ns => 10MHz)
  parameter TCK_HALF_PERIOD = 5,
  parameter CMD_DELAY = 1000
)
(
  output reg	tms,
  output reg	tck,
  output reg	tdi,
  input reg	tdo,
  input		enable,
  input		init_done,
  input		tdo_oe,
  output reg	trst_n
);

  integer	cmd;
  integer	length;
  integer	nb_bits;
  integer	tck_duty = TCLK_HALF_PERIOD - 1;

  reg[31:0]	buffer_out[0:4095]; // Command from the DPI
  reg[31:0]	buffer_in[0:4095];  // Response to the DPI

  integer	flip_tms;

  reg[31:0]	data_out;
  reg[31:0]	data_in;

  integer	debug;

assign		tms_o = tms;
assign		tck_o = tck;
assign		tdi_o = tdi;

initial begin
  tck <= #TP 1'b0;
  tdi <= #TP 1'bz;
  tms <= #TP 1'b0;

  data_out <= 32'h0;
  data_in <= 32'h0;

  wait (init_done)
    if ($test$plusargs("jtag_dpi_enable")) main;
end

task main;
  integer i;
begin
  trst_n = 1'b0;
  #100;
  trst_n = 1'b1;
  #100;

  $display("JTAG debug module with DPI-C interface enabled.");

  reset_tap;
  goto_run_test_idle_from_reset;

  while (1) begin
    // Check for incoming command wait until a command is sent
    // Poll with a delay here
    cmd = -1;

    while (cmd == -1) begin
      #CMD_DELAY c_jtag_read(cmd, length, nb_bits, buffer_out);
      if (DEBUG_INFO) begin
        $display("\nJTAG (DPI): read: len=%d, cmd=%h, bits=%d",
                 length, cmd, nb_bits);
        for (i = 0; i < length; i = i + 1) begin
          $display("JTAG (DPI): %d=%h", i, buffer_out[i]);
        end
      end
    end

    // now switch on the command
    case (cmd)
      `CMD_RESET: begin
        if (DEBUG_INFO)
          $display("JTAG (DPI): %t -----> CMD_RESET %h", $time, length);
        reset_tap;
        goto_run_test_idle_from_reset;
      end
      `CMD_TMS_SEQ: begin
        if (DEBUG_INFO)
          $display("JTAG (DPI): %t -----> CMD_TMS_SEQ", $time);
        do_tms_seq;
      end
      `CMD_SCAN_CHAIN: begin
        if (DEBUG_INFO)
          $display("JTAG (DPI): %t -----> CMD_SCAN_CHAIN", $time);
        flip_tms = 0;
        do_scan_chain;
        if (DEBUG_INFO) begin
          $display("\nJTAG (DPI): write: len=%d", length);
          for (i = 0; i < length; i = i + 1) begin
            $display("JTAG (DPI): %d=%h", i, buffer_in[i]);
          end
        end
        c_jtag_write(length, buffer_in);
      end
      `CMD_SCAN_CHAIN_FLIP_TMS: begin
        if (DEBUG_INFO)
          $display("JTAG (DPI): %t -----> CMD_SCAN_CHAIN_FLIP_TMS", $time);
        flip_tms = 1;
        do_scan_chain;
        if (DEBUG_INFO) begin
          $display("\nJTAG (DPI): write: len=%d", length);
          for (i = 0; i < length; i = i + 1) begin
            $display("JTAG (DPI): %d=%h", i, buffer_in[i]);
          end
        end
        c_jtag_write(length, buffer_in);
      end
      `CMD_STOP_SIMU: begin
        if (DEBUG_INFO)
          $display("JTAG (DPI): %t -----> CMD_STOP_SIMU", $time);
        $finish();
      end
      default: begin
        if (DEBUG_INFO)
          $display("JTAG (DPI): %t -----> UNKNOWN: %x", $time, cmd);
        $finish();
      end
    endcase
end endtask

// Generation of the TCK signal
task gen_clk;
  input[31:0] number;
  integer i;
begin
  for (i = 0; i < number; i = i + 1) begin
    #TCK_HALF_PERIOD tck <= 1;
    #TCK_HALF_PERIOD tck <= 0;
  end
end endtask

// TAP reset
task reset_tap; begin
  if (DEBUG_INFO)
    $display("JTAG (DPI): (%0t) reset.", $time);
  tms <= #1 1'b1;
  gen_clk(5);
end endtask

// Goes to RunTestIdle state
task goto_run_test_idle_from_reset; begin
  if (DEBUG_INFO)
    $display("JTAG (DPI): (%0t) idle.", $time);
  tms <= #1 1'b0;
  gen_clk(1);
end endtask

// OpenOCD TMS
task do_tms_seq;
  integer	i, j;
  reg[31:0]	data;
  integer	nb_bits_rem;
  integer	nb_bits_in_this_byte;
begin
  if (DEBUG_INFO)
    $display("(%0t) Task do_tms_seq of %d bits (length = %d).",
             $time, nb_bits, length);
  // Number of bits to send in the last byte
  nb_bits_rem = nb_bits % 8;
  for (i = 0; i < length; i = i + 1) begin
    // If we are in the last byte, we have to send only nb_bits_rem bits.
    // If not, we send the whole byte.
    nb_bits_in_this_byte = (i == (length - 1)) ? nb_bits_rem : 8;
    data = buffer_out[i];
    for (j = 0; j < nb_bits_in_this_byte; j = j + 1) begin
      tms <= #1 1'b0;
      if (data[j] == 1) begin
        tms <= #1 1'b1;
      end
      gen_clk(1);
    end
  end
  tms <= #1 1'b0;
end endtask

// OpenOCD BSCAN
task do_scan_chain;
  integer	_bit;
  integer	nb_bits_rem;
  integer	nb_bits_in_this_byte;
  integer	index;
begin
  if (DEBUG_INFO)
    $display("(%0t) Task do_scan_chain of %d bits (length = %d).",
             $time, nb_bits, length);
  // Number of bits to send in the last byte
  nb_bits_rem = nb_bits % 8;
  if (nb_bits_rem == 0) begin
    nb_bits_rem = 8;
  end
  for (index = 0; index < length; index = index + 1) begin
    // If we are in the last byte, we have to send only nb_bits_rem bits
    // if it's not zero. If not, we send the whole byte.
    nb_bits_in_this_byte = (index == (length - 1)) ? nb_bits_rem : 8;
    data_out = buffer_out[index];
    for (_bit = 0; _bit < nb_bits_in_this_byte; _bit = _bit + 1) begin
      tdi <= data_out[_bit];
      // On the last bit, send TMS to '1'
      if (((_bit == (nb_bits_in_this_byte - 1)) &&
           (index == (length - 1))) && (flip_tms == 1)) begin
        tms <= 1'b1;
      end
      #TCK_HALF_PERIOD tck <= 1;
      #1 data_in[_bit] <= tdo;
      #tck_duty tck <= 0;
    end
    buffer_in[index] = data_in;
  end
  tms <= 1'b0;
  tdi <= 1'b0;
end endtask

endmodule
