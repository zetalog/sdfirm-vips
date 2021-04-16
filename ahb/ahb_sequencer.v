`define AHB_ADDR_WIDTH		20
`define AHB_DATA_WIDTH		32
`define AHB_SIZE_WIDTH		3
`define AHB_TRANS_WIDTH		2
`define AHB_RESP_WIDTH		2

module sdfirm_ahb(
);

reg hclk;
reg hresetn;
reg hsel;
reg [`AHB_ADDR_WIDTH-1:0] haddr;
reg [`AHB_SIZE_WIDTH-1:0] hsize;
reg [`AHB_TRANS_WIDTH-1:0] htrans;
reg hwrite;
reg hready;
reg [`AHB_DATA_WIDTH-1:0] hwdata;
wire [`AHB_DATA_WIDTH-1:0] hrdata;
wire [`AHB_RESP_WIDTH-1:0] hresp;
wire hready_resp;

localparam TRANS_IDLE		= 2'b00;
localparam TRANS_BUSY		= 2'b01;
localparam TRANS_NON_SEQ	= 2'b10;
localparam TRANS_SEQ		= 2'b11;

localparam SIZE_BYTE		= 3'b000;
localparam SIZE_HALFWORD	= 3'b001;
localparam SIZE_WORD		= 3'b010;

localparam BURST_SINGLE		= 3'b000;
localparam BURST_INCR		= 3'b001;
localparam BURST_WRAP4		= 3'b010;
localparam BURST_INCR4		= 3'b011;
localparam BURST_WRAP8		= 3'b100;
localparam BURST_INCR8		= 3'b101;
localparam BURST_WRAP16		= 3'b110;
localparam BURST_INCR16		= 3'b111;

localparam RESP_OKAY		= 2'b00;
localparam RESP_ERROR		= 2'b01;

parameter HCLK_CYCLE = 8;
parameter HALF_HCLK_CYCLE = HCLK_CYCLE/2;

reg [63:0] hcount = 0;

always @(posedge hclk) begin
	hcount <= hcount + 1'h1;
end

export "DPI-C" task ahb_count;
task ahb_count(output int rcount); begin
`ifdef AHB_COUNTER_DEBUG
	$display("TSC: %08h", hcount);
`endif
	#HCLK_CYCLE;
	#HCLK_CYCLE;
	rcount = hcount[31:0];
	#HCLK_CYCLE;
	#HCLK_CYCLE;
end endtask

export "DPI-C" task ahb_write;
task ahb_write(input int t_addr, t_size, t_wdata); begin
	#HCLK_CYCLE
	haddr = t_addr;
	hwrite = 1'b1;
	hsize = t_size;
	htrans = TRANS_NON_SEQ;
	#HCLK_CYCLE;
	if (t_size == 0) begin
`ifdef AHB_SEQUENCER_DEBUG
	$display("CTL W: %08h %02h", t_addr, t_wdata);
`endif
		if (t_addr[1:0] == 3) begin
			hwdata[31:24] = t_wdata;
		end else if (t_addr[1:0] == 2) begin
			hwdata[23:16] = t_wdata;
		end else if (t_addr[1:0] == 1) begin
			hwdata[15:8] = t_wdata;
		end else begin
			hwdata[7:0] = t_wdata;
		end
	end else if (t_size == 1) begin
`ifdef AHB_SEQUENCER_DEBUG
	$display("W: %08h %04h", t_addr, t_wdata);
`endif
		if (t_addr[1] == 1) begin
			hwdata[31:16] = t_wdata;
		end else begin
			hwdata[15:0] = t_wdata;
		end
	end else if (t_size == 2) begin
`ifdef AHB_SEQUENCER_DEBUG
		$display("W: %08h %02h", t_addr, t_wdata);
`endif
		hwdata[31:0] = t_wdata;
	end
	hwrite = 1'b0;
	htrans = TRANS_IDLE;
	while (hready_resp == 1'b0) begin
		#HCLK_CYCLE;
	end
end endtask

export "DPI-C" task ahb_read;
task ahb_read(input int t_addr, t_size, output int t_rdata); begin
	#HCLK_CYCLE
	haddr = t_addr;
	hwrite = 1'b0;
	hsize = t_size;
	htrans = TRANS_NON_SEQ;
	#HCLK_CYCLE;
	htrans = TRANS_IDLE;
	while (hready_resp == 1'b0) begin
		#HCLK_CYCLE;
	end
	if (t_size == 0) begin
		if (t_addr[1:0] == 3) begin
			t_rdata = hrdata[31:24];
		end else if (t_addr[1:0] == 2) begin
			t_rdata = hrdata[23:16];
		end else if (t_addr[1:0] == 1) begin
			t_rdata = hrdata[15:8];
		end else begin
			t_rdata = hrdata[7:0];
		end
`ifdef AHB_SEQUENCER_DEBUG
		$display("R: %08h %02h", t_addr, t_rdata);
`endif
	end else if (t_size == 1) begin
		if (t_addr[1] == 1) begin
			t_rdata = hrdata[31:16];
		end else begin
			t_rdata = hrdata[15:0];
		end
`ifdef AHB_SEQUENCER_DEBUG
		$display("R: %08h %04h", t_addr, t_rdata);
`endif
	end else if (t_size == 2) begin
		if (t_addr[15:12] = 4'hF) begin
			t_rdata = hcount;
		end else begin
			t_rdata = hrdata[31:0];
		end
`ifdef AHB_SEQUENCER_DEBUG
		$display("R: %08h %08h", t_addr, t_rdata);
`endif
	end
end endtask

export "DPI-C" task ahb_finish;
task ahb_finish(); begin
	$finish();
end endtask

import "DPI-C" context task sdfirm_dpi_init();
initial begin
	hclk = 1'b0;
	hresetn = 1;
	haddr = 32:'b0;
	htrans = TRANS_IDLE;
	hsize = SIZE_BYTE;
	hsel = 1'b0;
	hwrite = 1'b0;
	hready = 1'b1;
	#HCLK_CYCLE
	hresetn = 0;
	hwrite = 1'b0;
	htrans = TRANS_IDLE;
	hsel = 1'b1;
	#HCLK_CYCLE;
	#(HCLK_CYCLE+1)
	hresetn = 1;
	#HCLK_CYCLE;
	#HCLK_CYCLE
	sdfirm_dpi_init();
	#HCLK_CYCLE;
	htrans = TRANS_IDLE;
end

always begin
	#HALF_HCLK_CYCLE hclk = ~hclk;
end

endmodule
