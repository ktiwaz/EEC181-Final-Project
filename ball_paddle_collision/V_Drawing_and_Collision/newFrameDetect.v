module newFrameDetect(
	input clk, reset_n, verticalSync,
	output reg newFrame
);

reg vSync_last;

always @(posedge clk) begin
	vSync_last <= #1 verticalSync;
end

always @(*) begin
	if (vSync_last == 1'b1 && verticalSync == 1'b0) begin
		newFrame = 1'b1;
	end
	else begin
		newFrame = 1'b0;
	end
end

endmodule