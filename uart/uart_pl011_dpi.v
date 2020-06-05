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
 * @(#)uart_pl011_dpi.v: ACE ARM PL011 uart DPI-C module verilog part
 * $Id: uart_pl011_dpi.v,v 1.1 2019-05-30 08:58:00 zhenglv Exp $
 */

import "DPI-C" function void c_con_init();
import "DPI-C" function bit c_con_readable();
import "DPI-C" function bit c_con_writable();
import "DPI-C" function void c_con_write(input byte data);
import "DPI-C" function byte c_con_read();

`define ACE_DATA_WIDTH	128
`define ACE_ADDR_WIDTH	6
`define ACE_DATA_BYTES	(`ACE_DATA_WIDTH/8)

`define ACE_BYTE(r, b)	(((r) & (`ACE_DATA_BYTES-1)) + (b))
`define ACE_BIT(r, b)	((`ACE_BYTE(r, ((b) / 8)) * 8) + ((b) % 8))

module uart_pl011_dpi(
	// Clocks and resets
	input  wire			  clk,
	input  wire			  reset_n,

	// Read port
	input  wire			  val_read_i,
	input  wire [`ACE_ADDR_WIDTH-1:0] val_rd_addr_i,
	output wire [`ACE_DATA_WIDTH-1:0] val_rd_data_o,

	// Write port
	input  wire			  val_write_i,
	input  wire [`ACE_ADDR_WIDTH-1:0] val_wr_addr_i,
	input  wire [`ACE_DATA_BYTES-1:0] val_wr_strb_i,
	input  wire [`ACE_DATA_WIDTH-1:0] val_wr_data_i
);

//---------------------------------------------------------------------------
// Local constants
//---------------------------------------------------------------------------

localparam integer REG_WIDTH = 16;
localparam integer UART_DATA_WIDTH = 8;

// Register offsets
localparam integer UARTDR = 'h00;
localparam integer UARTFR = 'h18;
localparam integer UARTIBRD = 'h24;
localparam integer UARTFBRD = 'h28;
localparam integer UARTLCR_H = 'h2C;
localparam integer UARTCR = 'h30;

// Register fields
localparam integer UART_EN = 'h00;
localparam integer UART_FEN = 'h04;
localparam integer UART_TXE = 'h08;
localparam integer UART_RXE = 'h09;
localparam integer UART_BUSY = 'h03;
localparam integer UART_RXFE = 'h04;
localparam integer UART_TXFF = 'h05;
localparam integer UART_RXFF = 'h06;
localparam integer UART_TXFE = 'h07;

//---------------------------------------------------------------------------
// Signal declarations
//---------------------------------------------------------------------------

// Registers
reg [(REG_WIDTH-1):0] uartibrd;
reg [(REG_WIDTH-1):0] uartfbrd;
reg [(REG_WIDTH-1):0] uartlcr_h;
reg [(REG_WIDTH-1):0] uartcr;
reg [(REG_WIDTH-1):0] uartfr;
reg [(UART_DATA_WIDTH-1):0] uartdr;

wire uart_en;
wire uart_txe;
wire uart_rxe;
wire uart_fen;
wire uart_txfe;
wire uart_rxff;
wire uart_busy;

reg [(`ACE_DATA_WIDTH-1):0] rd_data;

// Assign indicators from registers
assign uart_en = uartcr[UART_EN];
assign uart_txe = uartcr[UART_TXE];
assign uart_rxe = uartcr[UART_RXE];
assign uart_fen = uartlcr_h[UART_FEN];
assign uart_txfe = uartfr[UART_TXFE];
assign uart_rxff = uartfr[UART_RXFF];
assign uart_busy = uartfr[UART_BUSY];

assign uartfr[UART_BUSY] = 0;
assign uartfr[UART_RXFE] = ~uart_rxff;
assign uartfr[UART_TXFF] = ~uart_txfe;

//---------------------------------------------------------------------------
// Reads
//---------------------------------------------------------------------------
always @ (*) begin
	if (val_read_i) begin
		case (val_rd_addr_i)
		UARTDR: begin
			if (uart_en & uart_fen & uart_rxe & c_con_readable()) begin
				rd_data[`ACE_BIT(UARTDR,REG_WIDTH-1):`ACE_BIT(UARTDR,0)] = {8'b0, c_con_read()};
`ifdef UART_PL011_DPI_DEBUG
				$display("READ UARTDR %h", rd_data);
`endif
			end else begin
				rd_data[`ACE_BIT(UARTDR,REG_WIDTH-1):`ACE_BIT(UARTDR,0)] = 16'b0;
`ifdef UART_PL011_DPI_DEBUG
				$display("READ UARTDR %h", 16'b0);
`endif
			end
		end
		UARTFR: begin
			rd_data[`ACE_BIT(UARTFR,REG_WIDTH-1):`ACE_BIT(UARTFR,0)] = uartfr;
`ifdef UART_PL011_DPI_DEBUG
			$display("READ UARTFR %h-%h", rd_data, uartfr);
`endif
		end
		UARTLCR_H: begin
			rd_data[`ACE_BIT(UARTLCR_H,REG_WIDTH-1):`ACE_BIT(UARTLCR_H,0)] = uartlcr_h;
`ifdef UART_PL011_DPI_DEBUG
			$display("READ UARTLCR_H %h-%h", rd_data, uartlcr_h);
`endif
		end
		UARTFBRD: begin
			rd_data[`ACE_BIT(UARTFBRD,REG_WIDTH-1):`ACE_BIT(UARTFBRD,0)] = uartfbrd;
`ifdef UART_PL011_DPI_DEBUG
			$display("READ UARTFBRD %h-%h", rd_data, uartfbrd);
`endif
		end
		UARTIBRD: begin
			rd_data[`ACE_BIT(UARTIBRD,REG_WIDTH-1):`ACE_BIT(UARTIBRD,0)] = uartibrd;
`ifdef UART_PL011_DPI_DEBUG
			$display("READ UARTIBRD %h-%h", rd_data, uartibrd);
`endif
		end
		UARTCR: begin
			rd_data[`ACE_BIT(UARTCR,REG_WIDTH-1):`ACE_BIT(UARTCR,0)] = uartcr;
`ifdef UART_PL011_DPI_DEBUG
			$display("READ UARTCR %h-%h", rd_data, uartcr);
`endif
		end
		endcase
	end
end

//---------------------------------------------------------------------------
// Writes
//---------------------------------------------------------------------------
always @ (posedge clk or negedge reset_n) begin
	if (~reset_n) begin
		uartdr <= 0;
		uartfr[UART_RXFF] <= 1;
		uartfr[UART_BUSY-1:0] <= {3'b0};
		uartibrd <= 0;
		uartfbrd <= 0;
		uartlcr_h <= 0;
		uartcr <= 0;
	end else begin
		uartfr[UART_RXFF] <= c_con_readable();
		uartfr[UART_TXFE] <= c_con_writable();
		if (val_write_i) begin
			case (val_wr_addr_i)
			UARTDR: begin
				if (val_wr_strb_i[0]) begin
					if (uart_en & uart_fen & uart_txe & uart_txfe) begin
						c_con_write(val_wr_data_i[7:0]);
`ifdef UART_PL011_DPI_DEBUG
						$display("WRITE UARTDR %h", val_wr_data_i);
`endif
					end
				end
			end
			UARTIBRD: begin
				if (val_wr_strb_i[`ACE_BYTE(UARTIBRD,REG_WIDTH-1):`ACE_BYTE(UARTIBRD,0)]) begin
					uartibrd <= val_wr_data_i[`ACE_BIT(UARTIBRD,REG_WIDTH-1):`ACE_BIT(UARTIBRD,0)];
`ifdef UART_PL011_DPI_DEBUG
					$display("WRITE UARTIBRD %h-%h", val_wr_data_i, uartibrd);
`endif
				end
			end
			UARTFBRD: begin
				if (val_wr_strb_i[`ACE_BYTE(UARTFBRD,REG_WIDTH-1):`ACE_BYTE(UARTFBRD,0)]) begin
					uartibrd <= val_wr_data_i[`ACE_BIT(UARTFBRD,REG_WIDTH-1):`ACE_BIT(UARTFBRD,0)];
`ifdef UART_PL011_DPI_DEBUG
					$display("WRITE UARTFBRD %h-%h", val_wr_data_i, uartfbrd);
`endif
				end
			end
			UARTLCR_H: begin
				if (val_wr_strb_i[`ACE_BYTE(UARTLCR_H,REG_WIDTH-1):`ACE_BYTE(UARTLCR_H,0)]) begin
					uartlcr_h <= val_wr_data_i[`ACE_BIT(UARTLCR_H,REG_WIDTH-1):`ACE_BIT(UARTLCR_H,0)];
`ifdef UART_PL011_DPI_DEBUG
					$display("WRITE UARTLCR_H %h-%h", val_wr_data_i, uartlcr_h);
`endif
				end
			end
			UARTCR: begin
				if (val_wr_strb_i[`ACE_BYTE(UARTCR,REG_WIDTH-1):`ACE_BYTE(UARTCR,0)]) begin
					uartcr <= val_wr_data_i[`ACE_BIT(UARTCR,REG_WIDTH-1):`ACE_BIT(UARTCR,0)];
`ifdef UART_PL011_DPI_DEBUG
					$display("WRITE UARTCR %h-%h", val_wr_data_i, uartcr);
`endif
				end
			end
			endcase
		end
	end
end

initial begin
	c_con_init();
end

//---------------------------------------------------------------------------
// Output assignments
//---------------------------------------------------------------------------
assign val_rd_data_o = rd_data;

endmodule
