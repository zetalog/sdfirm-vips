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
 * @(#)uart_16550_dpi.v: APB 16550 uart DPI-C module verilog part
 * $Id: uart_16550_dpi.v,v 1.1 2019-05-29 12:41:00 zhenglv Exp $
 */

/* Follows SNPS DW_apb_uart, which is a 16550 compatible UART controller */

//-------------------------------------------------------------------------
// Settings
//-------------------------------------------------------------------------
// Name:        APB_DATA_WIDTH
// Default:     32
// Values:      8 16 32
// Width of APB data bus to which this component is attached. The data
// width can be set to 8, 16, or 32. Register access is on 32-bit
// boundaries, unused bits are held at static 0.
`define APB_DATA_WIDTH                  32
`define APB_DATA_WIDTH_32
//`define APB_DATA_WIDTH_16
//`define APB_DATA_WIDTH_8
`define UART_ADDR_SLICE_LHS             8

// Name:        FIFO_MODE
// Default:     16
// Values:      0 16 32 64 128 256 1024 2048
// Receiver and Transmitter FIFO depth in bytes. A setting of NONE means
// no FIFOs, which implies the 16540-compatible mode of operation. Most
// enhanced features and unavailable in the 16540 mode such as the Auto
// Flow Control and Programmable THRE interrupt modes. Setting a FIFO
// depth greater than 256 restricts the FIFO Memory to External only.
`define FIFO_MODE_ENABLED
// Size of FIFO address bus. Calculated by log2(FIFO depth).
`define FIFO_ADDR_WIDTH                 6
`define FIFO_MODE                       (2**FIFO_ADDR_WIDTH)

// Name:        FRACTIONAL_BAUD_DIVISOR_EN
// Default:     Disabled
// Values:      Disabled (0), Enabled (1)
// Configures the peripheral to have Fractional Baud Rate Divisor. If
// enabled, new fractional divisor latch register (DLF) is included to
// program the fractional divisor values.
`define FRACTINAL_BAUD_DIVISOR_EN       0
//`define FRACTIONAL_BAUD_DIVISOR_EN_EQ_1

// Name:        DLF_SIZE
// Default:     4
// Values:      4, ..., 6
// Enabled:     FRACTIONAL_BAUD_DIVISOR_EN==1
// Specifies the width of the fractional divisor. A high value means more
// precision but long averaging period.
`define DLF_SIZE                        4

//-------------------------------------------------------------------------
// Definitions
//-------------------------------------------------------------------------
// The definitions are kept smallest to save chip area.
// APB_UART_WIDTH = uart register width in APB (4-bytes registers)
// APB_ADDR_WIDTH = paddr width
// APB_DATA_WIDTH = prdata/pwdata width
// UART_ADDR_WIDTH = uart register index
// UART_DATA_WIDTH = uart register width except RBR and THR (1-byte register
//                   content)
// UART_DATA_BITS = uart register width of RBR and THR (9-bits if 9-bits is
//                  enabled)
`define APB_ADDR_WIDTH                  `UART_ADDR_SLICE_LHS
`define APB_UART_WIDTH                  2
`define UART_ADDR_WIDTH                 (`APB_ADDR_WIDTH-`APB_UART_WIDTH)
`define UART_DATA_WIDTH                 8
`ifdef UART_9BIT_DATA_EN
`define UART_DATA_BITS                  9
`else
`define UART_DATA_BITS                  8
`endif

//-------------------------------------------------------------------------
// State machine
//-------------------------------------------------------------------------
`define APB_FSM_WIDTH                   3
`define APB_IDLE                        3'b001
`define APB_SETUP                       3'b010
`define APB_ENABLE                      3'b100

//-------------------------------------------------------------------------
// Registers
//-------------------------------------------------------------------------
`define APB2UART(a)                     ((a) >> `APB_UART_WIDTH)
`define UART2APB(a)                     ((a) << `APB_UART_WIDTH)
`define UART_RBR                        `APB2UART('h00)
`define UART_THR                        `APB2UART('h00)
`define UART_DLL                        `APB2UART('h00)
`define UART_DLH                        `APB2UART('h04)
`define UART_IER                        `APB2UART('h04)
`define UART_FCR                        `APB2UART('h08)
`define UART_IIR                        `APB2UART('h08)
`define UART_LCR                        `APB2UART('h0C)
`define UART_MCR                        `APB2UART('h10)
`define UART_LSR                        `APB2UART('h14)
`define UART_USR                        `APB2UART('h7C)
`define UART_DLF                        `APB2UART('hC0)

// LSR
`define LSR_DR                          'h00
`define LSR_THRE                        'h05
`define LSR_TEMT                        'h06
`define LSR_RFE                         'h07
// USR
`define USR_BUSY                        'h00
`define USR_TFNF                        'h01
`define USR_TFE                         'h02
`define USR_RFNE                        'h03
`define USR_RFF                         'h04
// LCR
`define LCR_DLAB                        'h07
// FCR
`define FCR_FIFOE                       'h00
`define FCR_RFIFOR                      'h01
`define FCR_XFIFOR                      'h02
`define FCR_TET_SBIT                    4
`define FCR_TET_NBIT                    2
`define FCR_TET_EMPTY                   0
`define FCR_TET_CHAR_2                  1
`define FCR_TET_QUARTER_FULL            2
`define FCR_TET_HALF_FULL               3
`define FCR_RT_SBIT                     6
`define FCR_RT_NBIT                     2
`define FCR_RT_CHAR_1                   0
`define FCR_RT_QUATER_FULL              1
`define FCR_RT_HALF_FULL                2
`define FCR_RT_CHAR_2                   3
// MCR
`define MCR_DTR                         'h00
`define MCR_RTS                         'h00
`define MCR_AFCE                        'h05
`define MCR_SIRE                        'h06
// IER
`define IER_ERBFI                       'h00
`define IER_ETBEI                       'h01
// IIR
`define IIR_IID_NONE                    4'h1
`define IIR_IID_TBEI                    4'h2
`define IIR_IID_RBFI                    4'h4

import "DPI-C" function void c_con_init();
import "DPI-C" function bit c_con_readable();
import "DPI-C" function bit c_con_writable();
import "DPI-C" function void c_con_write(input byte data);
import "DPI-C" function byte c_con_read();

module dw_apb_uart_dpi(
	input  pclk,
	input  presetn,
	input  penable,
	input  pwrite,
	input  [`APB_DATA_WIDTH-1:0]pwdata,
// address bus
// paddr[1:0] is used to select byte enable signal.
// In APB_DATA_WIDTH=32 configuration, all four bytes of a 32 bit register
// is enabled. Hence the LSB two bits are not used in this configuration.
// paddr[0] is used to select lower byte of the 16-bit data word register.
// In APB_DATA_WIDTH=16 configuration, always 16-bit words are selected and
// hence LSB bit of the paddr is not used in this configuration.
	input  [`APB_ADDR_WIDTH-1:0]prdata,
	input  psel,
	output [`APB_DATA_WIDTH-1:0]prdata,
	output intr,
	output uart_lp_req_pclk,
	output uart_lp_req_sclk,
);

// baudrate generator
reg [`UART_DATA_WIDTH-1:0]dll;
reg [`UART_DATA_WIDTH-1:0]dlh;
`ifdef FRACTIONAL_BAUD_DIVISOR_EN_EQ_1
reg [`UART_DATA_WIDTH-1:0]dlf;
`endif

// control registers
reg [`UART_DATA_WIDTH-1:0]fcr;
reg [`UART_DATA_WIDTH-1:0]lcr;
reg [`UART_DATA_WIDTH-1:0]mcr;

// status registers
reg [`UART_DATA_WIDTH-1:0]lsr;
reg [`UART_DATA_WIDTH-1:0]usr;

// irq registers
reg [`UART_DATA_WIDTH-1:0]ier;
reg [`UART_DATA_WIDTH-1:0]iir;

// register temporal
reg [`UART_ADDR_WIDTH-1:0]reg_addr;
reg [`APB_DATA_WIDTH-1:0]reg_rdata;
reg [`APB_DATA_WIDTH-1:0]reg_wdata;

// APB state machine
reg [`APB_FSM_WIDTH-1:0]apb_slv_cs;
reg [`APB_FSM_WIDTH-1:0]apb_slv_ns;
reg apb_write;

localparam APB_PAD_UART_DATA = `APB_DATA_WIDTH - `UART_DATA_WIDTH;
localparam APB_PAD_UART_BITS = `APB_DATA_WIDTH - `UART_DATA_BITS;

wire lcr_dlab;
// write poll
wire lsr_temt;
wire lsr_thre;
// read poll
wire lsr_dr;
// wait busy
wire usr_busy;
wire fcr_fifoe;
wire fcr_xfifor;
wire fcr_rfifor;
// irq status
wire [3:0]iir_iid;
wire txi;
wire rxi;

assign ier_erbfi = ier[`IER_ERBFI];
assign ier_etbei = ier[`IER_ETBEI];
assign lcr_dlab = lcr[`LCR_DLAB];
assign lsr_temt = lsr[`LSR_TEMT];
assign lsr_thre = lsr[`LSR_THRE];
assign lsr_dr = lsr[`LSR_DR];
assign usr_busy = lsr[`USR_BUSY];
assign fcr_fifoe = fcr[`FCR_FIFOE];
assign fcr_xfifor = fcr[`FCR_XFIFOR];
assign fcr_rfifor = fcr[`FCR_RFIFOR];
assign iir_iid = iir[3:0];
assign uart_lp_req_pclk = 0;
assign uart_lp_req_sclk = 0;
assign txi = ier_etbei && lsr_temt;
assign rxi = ier_erbfi && lsr_dr;
assign intr = txi || rxi;

always @(*) begin : sample_irq_id_PROC
	if (rxi) begin
		iir[3:0] = `IIR_IID_RBFI;
	end else begin
		if (txi) begin
			iir[3:0] = `IIR_IID_TBEI;
		end else begin
			iir[3:0] = `IIR_IID_NONE;
		end
	end
end

always @(posedge pclk or negedge presetn) begin : sample_pclk_state_PROC
	if (~presetn) begin
		apb_slv_cs <= `APB_IDLE;
	end else begin
		apb_slv_cs <= apb_slv_ns;
	end
end

always @(*) begin : next_fsm_combo_PROC
	case (apb_slv_cs)
	`APB_IDLE : begin
		if (psel) begin
			apb_slv_ns = `APB_SETUP;
		end
	end
	`APB_SETUP : begin
		if (penable) begin
			apb_slv_ns = `APB_ENABLE;
			apb_write = pwrite;
		end
	end
	`APB_ENABLE : begin
		if (~penable) begin
			if (~psel) begin
				apb_slv_ns = `APB_IDLE;
			end
		end
	end
	default : apb_slv_ns <= `APB_IDLE;
	endcase
end

always @(posedge pclk or negedge presetn) begin : sample_fifo_PROC
	if (~presetn) begin
		lsr[`LSR_TEMT] <= 1'b1;
		lsr[`LSR_THRE] <= 1'b1;
		lsr[`LSR_DR] <= 1'b0;
	end else begin
		if (fcr_xfifor) begin
			lsr[`LSR_TEMT] <= 1'b1;
			lsr[`LSR_THRE] <= 1'b1;
			lsr[`FCR_XFIFOR] <= 1'b0;
		end else begin
			lsr[`LSR_TEMT] <= c_con_writable();
			lsr[`LSR_THRE] <= c_con_writable();
		end
		if (fcr_rfifor) begin
			lsr[`LSR_DR] <= 1'b0;
			fcr[`FCR_RFIFOR] <= 1'b0;
		end else begin
			lsr[`LSR_DR] <= c_con_readable();
		end
	end
end

always @(posedge pclk or negedge presetn) begin : sample_pclk_paddr_PROC
	if (~presetn) begin
		reg_addr <= {`UART_ADDR_WIDTH{1'b0}};
	end else begin
		if (psel) begin
			// Strip off bits [1:0] which are embedded into byte enables
			reg_addr <= paddr[`APB_ADDR_WIDTH-1:`APB_UART_WIDTH];
`ifdef UART_16550_DPI_DEBUG
			$display("UART(%s)%h, %s", pwrite ? "W" : "R", `UART2APB(reg_addr), penable ? "E" : "D");
`endif
		end
	end
end

always @(posedge pclk or negedge presetn) begin : sample_pclk_wdata_PROC
	if (~presetn) begin
		reg_wdata <= {`APB_DATA_WIDTH{1'b0}};
	end else begin
		reg_wdata <= pwdata;
	end
end

always @(posedge pclk or negedge presetn) begin : sample_pclk_regfields_PROC
	if (~presetn) begin
		lcr <= 0;
		mcr <= 0;
		fcr <= 0;
		lsr <= 0;
		usr <= 0;
		dll <= 0;
		dlh <= 0;
		ier <= 0;
		iir <= 0;
	end else begin
		if (apb_slv_ns == `APB_ENABLE && apb_write) begin
			case (reg_addr)
			`UART_LCR : begin
				lcr <= reg_wdata[`UART_DATA_WIDTH-1:0];
`ifdef UART_16550_DPI_DEBUG
				$display("WRITE_UART_LCR %h-%h", reg_wdata, lcr);
`endif
			end
			`UART_MCR : begin
				mcr <= reg_wdata[`UART_DATA_WIDTH-1:0];
`ifdef UART_16550_DPI_DEBUG
				$display("WRITE_UART_MCR %h-%h", reg_wdata, mcr);
`endif
			end
			`UART_FCR : begin
				fcr <= reg_wdata[`UART_DATA_WIDTH-1:0];
`ifdef UART_16550_DPI_DEBUG
				$display("WRITE_UART_FCR %h-%h", reg_wdata, fcr);
`endif
			end
			`UART_LSR : begin
				lsr <= reg_wdata[`UART_DATA_WIDTH-1:0];
`ifdef UART_16550_DPI_DEBUG
				$display("WRITE_UART_LSR %h-%h", reg_wdata, lsr);
`endif
			end
			`UART_USR : begin
				usr <= reg_wdata[`UART_DATA_WIDTH-1:0];
`ifdef UART_16550_DPI_DEBUG
				$display("WRITE_UART_USR %h-%h", reg_wdata, usr);
`endif
			end
			`UART_IER : begin
				if (lcr_dlab) begin
					usr <= reg_wdata[`UART_DATA_WIDTH-1:0];
`ifdef UART_16550_DPI_DEBUG
					$display("WRITE_UART_DLH %h-%h", reg_wdata, dlh);
`endif
				end else begin
					ier <= reg_wdata[`UART_DATA_WIDTH-1:0];
`ifdef UART_16550_DPI_DEBUG
					$display("WRITE_UART_IER %h-%h", reg_wdata, ier);
`endif
				end
			end
			`UART_THR : begin
				if (lcr_dlab) begin
					dll <= reg_wdata[`UART_DATA_WIDTH-1:0];
`ifdef UART_16550_DPI_DEBUG
					$display("WRITE_UART_DLL %h-%h", reg_wdata, dll);
`endif
				end else begin
					if (lsr_temt & fcr_fifoe & ~fcr_xfifor) begin
						c_con_write(reg_wdata[7:0]);
`ifdef UART_16550_DPI_DEBUG
						$display("WRITE_UART_THR %h", reg_wdata);
`endif
					end
				end
			end
			endcase
		end
	end
end

// Read address decoding
always_comb begin : combo_rdata_regfields_PROC
	if (apb_slv_ns == `APB_ENABLE && (~apb_write)) begin
		case (reg_addr)
		`UART_LCR : begin
			reg_rdata = {{APB_PAD_UART_DATA{1'b0}}, lcr};
`ifdef UART_16550_DPI_DEBUG
			$display("READ UART_LCR %h-%h", reg_rdata, lcr);
`endif
		end
		`UART_MCR : begin
			reg_rdata = {{APB_PAD_UART_DATA{1'b0}}, mcr};
`ifdef UART_16550_DPI_DEBUG
			$display("READ UART_MCR %h-%h", reg_rdata, mcr);
`endif
		end
		`UART_IIR : begin
			reg_rdata = {{APB_PAD_UART_DATA{1'b0}}, iir};
`ifdef UART_16550_DPI_DEBUG
			$display("READ UART_IIR %h-%h", reg_rdata, iir);
`endif
		end
		`UART_LSR : begin
			reg_rdata = {{APB_PAD_UART_DATA{1'b0}}, lsr};
`ifdef UART_16550_DPI_DEBUG
			$display("READ UART_LSR %h-%h", reg_rdata, lsr);
`endif
		end
		`UART_USR : begin
			reg_rdata = {{APB_PAD_UART_DATA{1'b0}}, usr};
`ifdef UART_16550_DPI_DEBUG
			$display("READ UART_USR %h-%h", reg_rdata, usr);
`endif
		end
		`UART_IER : begin
			if (lcr_dlab) begin
				reg_rdata = {{APB_PAD_UART_DATA{1'b0}}, dlh};
`ifdef UART_16550_DPI_DEBUG
				$display("READ UART_DLH %h-%h", reg_rdata, dlh);
`endif
			end else begin
				reg_rdata = {{APB_PAD_UART_DATA{1'b0}}, ier};
`ifdef UART_16550_DPI_DEBUG
				$display("READ UART_IER %h-%h", reg_rdata, ier);
`endif
			end
		end
		`UART_RBR : begin
			if (lcr_dlab) begin
				reg_rdata = {{APB_PAD_UART_DATA{1'b0}}, dll};
`ifdef UART_16550_DPI_DEBUG
				$display("READ UART_DLL %h-%h", reg_rdata, dll);
`endif
			end else begin
				if (fcr_fifoe & ~fcr_rfifor & c_con_readable()) begin
					reg_rdata = {{APB_PAD_UART_BITS{1'b0}}, {(`UART_DATA_BITS-8){1'b0}}, c_con_read()};
`ifdef UART_16550_DPI_DEBUG
					$display("READ UART_RBR %h", reg_rdata);
`endif
				end
			end
		end
		default : reg_data = {`APB_DATA_WIDTH{1'b0}};
		endcase
	end
end

assign prdata = reg_rdata;

initial begin
	c_con_init();
end

endmodule
