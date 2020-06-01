`include "SD_defines.v"

module CLOCK_DIVIDER (
	input wire      CLK,
	input      [7:0]DIVIDER,
	input wire      RST,
	output          SD_CLK 
);
  
	reg [7:0]ClockDiv;
	reg      SD_CLK_O;
`ifdef SYN
	CLKINT CLKINT0
	(.A (SD_CLK_O),
	 .Y (SD_CLK) 
	);
`endif
 
`ifdef SIM
assign SD_CLK = SD_CLK_O;
`endif 
 
always @ (posedge CLK or posedge RST) begin
	if (RST) begin
		ClockDiv <= 8'b0000_0000;
		SD_CLK_O <= 0;
	end else if (ClockDiv == DIVIDER) begin
		ClockDiv <= 0;
		SD_CLK_O <= ~SD_CLK_O;
	end else begin
		ClockDiv <= ClockDiv + 1;
		SD_CLK_O <= SD_CLK_O;
	end
end
endmodule
