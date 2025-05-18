module movingPaddle #(
	parameter [12:0] WIDTH = 20,
	parameter [12:0] HEIGHT = 50,
	parameter [12:0] COLS = 640,
	parameter [12:0] ROWS = 480,
	parameter BUTTON_DELAY = 160000
)(
	input clk, reset_n, active, newFrame,
	input [3:0] move,
	output reg [12:0] cRow, cCol,
	output [12:0] cH, cW
);

reg [31:0] delayCtr, delayCtr_n;
wire [12:0] cRow_n, cCol_n;
wire U, D, L, R;
reg signed [12:0] dVertical, dHorizontal, dVertical_n, dHorizontal_n;


assign cH = HEIGHT;
assign cW = WIDTH;

always @(posedge clk) begin

	delayCtr <= #1 delayCtr_n;
	dVertical <= #1 dVertical_n;
	dHorizontal <= #1 dHorizontal_n;

	cRow <= #1 cRow;
	cCol <= #1 cCol;


	// on the new frame, the new row and col are saved to the register
	// in frame values reset to 0
	if (newFrame == 1'b1) begin
		cRow <= #1 cRow_n;
		cCol <= #1 cCol_n;

		dVertical <= #1 13'd0000;
		dHorizontal <= #1 13'd0000;
	end


	if (reset_n == 1'b0) begin
		cRow <= #1 ROWS/2;
		cCol <= #1 COLS/2;

		dVertical <= #1 13'd0000;
		dHorizontal <= #1 13'd0000;
	end
end

always @(*) begin
	delayCtr_n = delayCtr + 1;

	if (reset_n == 1'b0 || delayCtr == BUTTON_DELAY || newFrame == 1'b1) begin
		delayCtr_n = 13'd0001;
	end
end


assign U = move[3];
assign D = move[2];
assign L = move[1];
assign R = move[0];

// When the counter reaches BUTTON_DELAY, the buttons are sampled, allowed to alter
// dVertical and dHorizontal
always @(*) begin
	if (delayCtr == BUTTON_DELAY && active == 1'b1) begin
		case({U,D})
			2'b01 : dVertical_n = dVertical + 2'b01;
			2'b10 : dVertical_n = dVertical - 2'b01;
			default: dVertical_n = dVertical;
		endcase

		case({L,R})
			2'b01 : dHorizontal_n = dHorizontal + 2'b01;
			2'b10 : dHorizontal_n = dHorizontal - 2'b01;
			default: dHorizontal_n = dHorizontal;
		endcase
	end

	else begin
		dHorizontal_n = dHorizontal;
		dVertical_n = dVertical;
	end

end


// evaluates the new position of the cursor given its current location, and its attributes during the next frame
cursorControl #(.COLS(COLS), .ROWS(ROWS)) c(.centerC(cCol), .centerR(cRow),
				.centerC_n(cCol_n), .centerR_n(cRow_n),
				.dH(dHorizontal), .dV(dVertical),
				.width(WIDTH), .height(HEIGHT));

endmodule



module cursorControl #(
	parameter [12:0] COLS = 640,
	parameter [12:0] ROWS = 480
)(
	input [12:0] centerC, centerR,
	input signed [12:0] width, height,
	input signed [12:0] dH, dV,
	output [12:0] centerC_n, centerR_n   // indexed top, right, bottom, left 
);

reg signed [13:0]  lEdge, rEdge, tEdge, bEdge, s_centerC_n, s_centerR_n;
wire signed [13:0] s_size, s_centerC, s_centerR;


assign s_centerC = centerC;
assign s_centerR = centerR;
assign centerC_n = s_centerC_n;
assign centerR_n = s_centerR_n;


always @(*) begin
	// calculate edges if square moves on current trajectory
	tEdge = s_centerR + dV - (height>>1);
	bEdge = s_centerR + dV  + ((height-1)>>1);
	lEdge = s_centerC + dH - (width>>1);
	rEdge = s_centerC + dH  + ((width-1)>>1);


	// default case: move according to the velocity, direction does not change
	s_centerC_n = s_centerC + dH;
	s_centerR_n = s_centerR + dV;

	
	if (lEdge < 0) begin
		s_centerC_n = (width>>1);
	end

	else if (rEdge >= COLS) begin
		s_centerC_n = (COLS - 1) - ((width-1)>>1);
	end

	if (tEdge < 0) begin
		s_centerR_n = (height>>1);
	end

	else if (bEdge >= ROWS) begin
		s_centerR_n = (ROWS - 1) - ((height-1)>>1);
	end
	
end

endmodule