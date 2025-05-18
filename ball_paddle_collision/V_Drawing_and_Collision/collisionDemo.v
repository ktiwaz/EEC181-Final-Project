module collisionDemo #(
	parameter [12:0] ROWS_D8M = 640,
	parameter [12:0] COLS_D8M = 480,
	parameter BUTTON_DELAY = 160000
)(
	input [9:0] SW,
	input [3:0] KEY,


	input clk, reset_n, verticalSync,
	input [12:0] row, col,

	output reg [7:0] o_VGA_R,
	output reg [7:0] o_VGA_G,
	output reg [7:0] o_VGA_B
);


wire [12:0] cH0, cH1, cW0, cW1;
wire [12:0] paddleRow0, paddleCol0, paddleSize0, paddleRow1, paddleCol1, paddleSize1;
wire [12:0] paddleL, paddleR, paddleU, paddleD;
wire [12:0] ball_pos_x, ball_pos_y;
wire inPaddle0, inPaddle1, onBorder0, onBorder1, inBall, onBallBorder, newFrame;

// Detects a new frame
newFrameDetect nf(.clk(clk), .reset_n(reset_n), .verticalSync(verticalSync),
				.newFrame(newFrame));


localparam PADDLE_H = 50;
localparam PADDLE_W = 20;

//------ paddle Modules  --------------- 
// paddle 0

movingPaddle #(.COLS(COLS_D8M), .ROWS(ROWS_D8M), .BUTTON_DELAY(BUTTON_DELAY), .WIDTH(PADDLE_W), .HEIGHT(PADDLE_H)) imagePaddle0(
	.clk(clk), .reset_n(reset_n), .active(~SW[8]), .newFrame(newFrame),
	.move(~KEY[3:0]),
	.cRow(paddleRow0), .cCol(paddleCol0), .cH(cH0), .cW(cW0)
);

// paddle 1
movingPaddle #(.COLS(COLS_D8M), .ROWS(ROWS_D8M), .BUTTON_DELAY(BUTTON_DELAY), .WIDTH(PADDLE_W), .HEIGHT(PADDLE_H)) imagePaddle1(
	.clk(clk), .reset_n(reset_n), .active(SW[8]), .newFrame(newFrame),
	.move(~KEY[3:0]),
	.cRow(paddleRow1), .cCol(paddleCol1), .cH(cH1), .cW(cW1)
);

// Paddle Drawing --> outputs whether the given pixel is in a paddle or not
paddleDraw cDraw0(.row(row), .col(col), .crow(paddleRow0), .ccol(paddleCol0), .height(cH0), .width(cW0),
				.inPaddle(inPaddle0), .onBorder(onBorder0));

// need to replace for demo to take in boundaries instead
paddleDraw cDraw1(.row(row), .col(col), .crow(paddleRow1), .ccol(paddleCol1), .height(cH1), .width(cW1),
				 .inPaddle(inPaddle1), .onBorder(onBorder1));


// Ball Position/Collision Logic
localparam BALL_SIZE = 10;


assign paddleL = paddleCol1 - PADDLE_W>>1;
assign paddleR = paddleCol1 + (PADDLE_W-1)>>1;
assign paddleU = paddleRow1 - (PADDLE_H>>1);
assign paddleD = paddleRow1 + (PADDLE_H-1)>>1;


ball_trajectory #(.BALL_W(BALL_SIZE), .BALL_H(BALL_SIZE)) ball(.clk(clk), .reset(!reset_n), .pause(SW[9]), .newFrame(newFrame),
	.paddleLeft(paddleL), .paddleRight(paddleR), .paddleTop(paddleT), .paddleBottom(paddleB),
	.wallLeft(13'd0), .wallRight(13'd640), .wallTop(13'd0), .wallBottom(13'd480),
	.ballXout(ball_pos_x), .ballYout(ball_pos_y));



paddleDraw ballDraw(.row(row), .col(col), .crow(ball_pos_x), .ccol(ball_pos_y), .height(BALL_SIZE), .width(BALL_SIZE),
				 .inPaddle(inBall), .onBorder(onBallBorder));



//------ Draw Logic --------------- 
// Draw Arbitter (not sure what a proper name for this would be)
always @(*)begin
if (inPaddle0 == 1'b1) begin
	o_VGA_R = 8'h00;
	o_VGA_G = 8'h00;
	o_VGA_B = 8'hff;
end

else if (onBorder0 == 1'b1) begin
	o_VGA_R = 8'h0;
	o_VGA_G = 8'h0;
	o_VGA_B = 8'h0;
end

else if (inPaddle1 == 1'b1) begin
	o_VGA_R = 8'hff;
	o_VGA_G = 8'h00;
	o_VGA_B = 8'h00;
end

else if (onBorder1 == 1'b1) begin
	o_VGA_R = 8'h0;
	o_VGA_G = 8'h0;
	o_VGA_B = 8'h0;
end

else if (inBall == 1'b1) begin
	o_VGA_R = 8'hff;
	o_VGA_G = 8'hff;
	o_VGA_B = 8'h0;
end

else if (row >= 13'd0 && row < ROWS_D8M && col>=13'd0 && col < COLS_D8M) begin /// in frame and not paddle? --> save values
	o_VGA_R = 8'hff;
	o_VGA_G = 8'hff;
	o_VGA_B = 8'hff;
end

else begin //camera out of the range should always be 0
	o_VGA_R = 8'h00;
	o_VGA_G = 8'h00;
	o_VGA_B = 8'h00;
	end
end




endmodule