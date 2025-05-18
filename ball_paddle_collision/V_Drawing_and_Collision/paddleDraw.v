module paddleDraw (
	input [12:0] row, col, crow, ccol,
	input [12:0] height, width,
	output reg inPaddle, onBorder
);

wire signed [13:0]  lEdge, rEdge, tEdge, bEdge, signed_col, signed_row;

assign lEdge = ccol - (width>>1);  // still have sign issues
assign rEdge = ccol + ((width-1)>>1);
assign tEdge = crow - (height>>1);
assign bEdge = crow + ((height-1)>>1);

assign signed_col = col;
assign signed_row = row;

always @(*) begin
	inPaddle = 1'b0;
	onBorder = 1'b0;

	if (lEdge <= signed_col && signed_col <= rEdge && tEdge <= signed_row && signed_row <= bEdge) begin
		inPaddle = 1'b1;
	end

	if (((lEdge == signed_col || signed_col == rEdge) && tEdge <= signed_row && signed_row <= bEdge) ||
		(lEdge <= signed_col && signed_col <= rEdge && (tEdge == signed_row || signed_row == bEdge))) begin
		onBorder = 1'b1;
	end

end

endmodule