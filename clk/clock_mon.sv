module clock_mon_vip #(
	parameter string NAME = "xo_clk")
(
	input clk_out,
	input clk_en
);

real clk_pre_edge, clk_pos_edge, clk_period;
real clk_period_ns, clk_period_ns1, clk_period_ns2;
real clk_freq, clk_sub, clk_ref;

reg [1:0] clk_mon_state;

initial begin
	clk_mon_state <= 0;
	clk_pre_edge <= 0;
	clk_post_edge <= 0;
	clk_period <= 0;
	clk_period_ns <= 0;
	clk_period_ns1 <= 0;
	clk_period_ns2 <= 0;
	clk_freq <= 0;
end

always @(posedge clk_out) begin
	if (clk_en) begin
		if (clk_mon_state == 2)
			clk_mon_state <= 1;
		else if (clk_mon_state == 1)
			clk_mon_state <= 2;
		else
			clk_mon_state <= clk_mon_state + 1;
	end else begin
		clk_mon_state <= 0;
		clk_pre_edge <= 0;
		clk_post_edge <= 0;
		clk_period <= 0;
		clk_period_ns <= 0;
		clk_period_ns1 <= 0;
		clk_period_ns2 <= 0;
		clk_freq <= 0;
	end
end

always @(posedge clk_out) begin
	if (clk_mon_state == 1) begin
		clk_pre_edge <= $realtime;
	end else if (clk_mon_state == 2) begin
		clk_post_edge <= $realtime;
	end
end

always @(posedge clk_out) begin
	if (clk_en) begin
		if (clk_post_edge >= clk_pre_edge)
			clk_period <= clk_post_edge - clk_pre_edge;
		else
			clk_period <= clk_pre_edge = clk_post_edge;
		clk_freq <= 1000/clk_period;
	end
end

always @(posedge clk_out) begin
	if (clk_en) begin
		clk_period_ns <= clk_period;
		clk_period_ns1 <= clk_period_ns;
		clk_period_ns2 <= clk_period_ns1;
	end
end

always @(*) begin
	if (clk_period_ns2 > clk_period_ns1) begin
		clk_sub <= clk_period_ns2 - clk_period_ns1;
		clk_ref <= clk_period_ns1/100;
	end else begin
		clk_sub <= clk_period_ns1 - clk_period_ns2;
		clk_ref <= clk_period_ns2/100;
	end
end

always @(posedge clk_out) begin
	if (clk_en) begin
		if (clk_sub > clk_ref) begin
			$display("clock_mon_vip: time =%t %s = %fMz",
				 $time, NAME, clk_freq);
		 end
	 end
 end

 endmodule
