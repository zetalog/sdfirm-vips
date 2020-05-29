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
 * @(#)uart_dpi.v: uart DPI-C module verilog part
 * $Id: uart_dpi.v,v 1.1 2019-05-29 12:41:00 zhenglv Exp $
 */

import "DPI-C" function void c_con_init();
import "DPI-C" function bit c_con_readable();
import "DPI-C" function bit c_con_writable();
import "DPI-C" function void c_con_write(input byte data);
import "DPI-C" function byte c_con_read();

module uart_dpi #(
`ifdef UART_DPI_FIXED_BAUD
  parameter BAUD = 'x,
  parameter FREQ = 'x,
`else
  parameter CYCLES_PER_SYMBOL = 16,
`endif
  parameter string NAME = "uart0")
 (
  input      clk,
  input      rst,
  output reg tx,
  input      rx
 );

  /* TX/RX state */
  parameter IDLE   = 3'b000;
  parameter START  = 3'b001; /* Start bit seen */
  parameter DATA   = 3'b010;
  parameter PARITY = 3'b011;
  parameter STOP   = 3'b100; /* Wait stop bit */

`ifdef UART_DPI_FIXED_BAUD
  localparam CYCLES_PER_SYMBOL = FREQ/BAUD;
`endif

  initial begin
    c_con_init();
  end

  /* TX */
  reg [2:0] txstate;
  int txcount;
  int txcycle;
  reg [7:0] txsymbol;
  reg txpoll;
  reg txdata;

  always_comb begin
    case (txstate)
      IDLE : begin
        if (txpoll) begin
          if (c_con_readable()) begin
            txsymbol = c_con_read();
            txdata = 1'b1;
          end
        end else begin
          txdata = 1'b0;
        end
        tx = 1'b1;
      end
      START : begin
        txdata = 1'b1;
        tx = 1'b0;
      end
      DATA : begin
        txdata = 1'b1;
        tx = txsymbol[txcount];
      end
      STOP : begin
        txdata = 1'b1;
        tx = 1'b1;
      end
    endcase
  end

  always@(posedge clk or negedge rst) begin
    if (~rst) begin
      txstate <= IDLE;
      txcount <= 0;
      txcycle <= 0;
      txpoll <= 1'b0;
    end else begin
      case (txstate)
        IDLE : begin
          if (txdata) begin
            txstate <= START;
          end else begin
            txpoll <= c_con_readable();
          end
          txcycle <= 0;
        end
        START : begin
          txpoll <= 1'b0;
          if (txcycle == CYCLES_PER_SYMBOL - 1) begin
            txstate <= DATA;
            txcount <= 0;
            txcycle <= 0;
          end else begin
            txcycle <= txcycle + 1;
          end
        end
        DATA : begin
          if (txcycle == CYCLES_PER_SYMBOL - 1) begin
            if (txcount == 7) begin
              txstate <= STOP;
            end
            txcount <= txcount + 1;
            txcycle <= 0;
          end else begin
            txcycle <= txcycle + 1;
          end
        end
        STOP : begin
          if (txcycle == CYCLES_PER_SYMBOL - 1) begin
            txstate <= IDLE;
          end else begin
            txcycle <= txcycle + 1;
          end
        end
      endcase
    end
  end

  /* RX */
  reg [2:0] rxstate;
  int rxcount;
  int rxcycle;
  reg [7:0] rxsymbol;

  always@(posedge clk or negedge rst) begin
    if (~rst) begin
      rxstate <= IDLE;
      rxcycle <= 0;
      rxcount <= 0;
    end else begin
      case (rxstate)
        IDLE : begin
          if (~rx) begin
            rxstate <= START;
            rxcycle <= CYCLES_PER_SYMBOL/2 - 1;
          end else begin
            rxsymbol <= 8'bxxxxxxxx;
            rxcycle <= 0;
          end
        end
        START : begin
          if (rxcycle == CYCLES_PER_SYMBOL - 1) begin
            if (rx) begin
              rxstate <= IDLE;
            end else begin
              rxstate <= DATA;
              rxcount <= 0;
            end
            rxcycle <= 0;
          end else begin
            rxcycle <= rxcycle + 1;
          end
        end
        DATA : begin
          if (rxcycle == CYCLES_PER_SYMBOL - 1) begin
            if (rxcount == 8) begin
              rxstate <= STOP;
            end
            rxsymbol[rxcount - 1] <= rx;
            rxcycle <= 0;
          end else begin
            if (rxcount == 0) begin
              rxcount <= rxcount + 1;
            end
            rxcycle <= rxcycle + 1;
          end
        end
        STOP : begin
          if (rxcycle == CYCLES_PER_SYMBOL - 1) begin
            if (rx) begin
              rxstate <= IDLE;
              if (c_con_writable()) begin
                c_con_write(rxsymbol);
              end
          end
        end else begin
          rxcycle <= rxcycle + 1;
        end
      endcase
    end
  end
