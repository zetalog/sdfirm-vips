
module sdfirm_apb(
};

wire pclk;
wire presetn;
reg [31:0] paddr;
reg [31:0] pwdata;
reg pwrite;
reg penable;
wire pready;
wire [31:0] prdata;
wire pslverr;

localparam PCLK_CYCLE = 8000;	// 125MHz
parameter HALF_PCLK_CYCLE = PCLK_CYCLE/2;

reg [63:0] pcount = 0;

always @(posedge pclk) begin
	pcount <= pcount + 1'h1;
end

export "DPI-C" task apb_count;
task apb_count(output int rcount); begin
`ifdef APB_COUNTER_DEBUG
	$display("APB V: TSC: %08h", pcount);
`endif
	#PCLK_CYCLE;
	#PCLK_CYCLE;
	rcount = pcount[31:0];
	#PCLK_CYCLE;
	#PCLK_CYCLE;
end endtask

export "DPI-C" task apb_write;
task apb_write(input int addr, input int wdata); begin
`ifdef APB_SEQUENCER_DEBUG
	$display("CTL V: W: %08h %08h", addr, wdata);
`endif

	#PCLK_CYCLE
	paddr = addr;
	pwdata = wdata;
	pwrite = 1'b1;
	psel = 1'b1;
	#PCLK_CYCLE
	penable = 1'b1;
	@(negedge pready);
	penable = 1'b0;
	pwrite = 1'b0;
	psel = 1'b0;
end endtask

export "DPI-C" task apb_read;
task apb_read(input int addr, output int rdata); begin
	#PCLK_CYCLE
	paddr = addr;
	pwrite = 1'b0;
	psel = 1'b1;
	@(negedge pready);
	rdata = prdata;
	penable = 1'b0;
	psel = 1'b0;
`ifdef APB_SEQUENCER_DEBUG
	$display("APB V: R: %08h %08h", addr, rdata);
`endif
end endtask

export "DPI-C" task apb_finish;
task apb_finish(); begin
	$finish();
end endtask

import "DPI-C" context task sdfirm_dpi_init();
initial begin
	pclk = 1'b0;
	presetn = 1'b0;
	paddr = 32'b0;
	penable = 1'b0;
	pwrite = 1'b0;
	psel = 1'b0;
	pwdata = 32'b0;

	#(700 * PCLK_CYCLE)
	presetn = 1'b1;

	#(HALF_PCLK_CYCLE);

	sdfirm_dpi_init();

	#PCLK_CYCLE;
end

always begin
	#HALF_PCLK_CYCLE pclk = ~pclk;
end

endmodule
