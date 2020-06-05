
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
