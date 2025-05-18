module ball_trajectory #(
	parameter [12:0] BALL_W = 10,
	parameter [12:0] BALL_H = 10
)(
	input clk, reset, pause, newFrame,
	input [12:0] paddleLeft, paddleRight, paddleTop, paddleBottom,
	input [12:0] wallLeft, wallRight, wallTop, wallBottom,
	output [12:0] ballXout, ballYout
);





wire signed [13:0] ball_edge_l, ball_edge_r, ball_edge_t, ball_edge_b;
wire signed [13:0] ball_edge_l_next, ball_edge_r_next, ball_edge_t_next, ball_edge_b_next;


reg signed [12:0] vX, vY, vX_n, vY_n;
reg signed [13:0] ballX, ballY, ballX_n, ballY_n;


// likely move ball position outside of this module for the true version --> game logic may need to set the position of the ball
always @(posedge clk) begin

	vX <= vX;
	vY <= vY;
	ballX <= ballX;
	ballY <= ballY;

	if (newFrame == 1'b1) begin
		vX <= vX_n;
		vY <= vY_n;
		ballX <= ballX_n;
		ballY <= ballY_n;
	end

	if (pause == 1'b1) begin
		vX <= vX;
		vY <= vY;
		ballX <= ballX;
		ballY <= ballY;
	end

	if (reset == 1'b1) begin
		vX <= 2;
		vY <= 2;
		ballX <= 200;
		ballY <= 300;
	end

end

// output signals
assign ballXout = ballX;
assign ballYout = ballY;


assign ball_edge_l = ballX - (BALL_W>>1);
assign ball_edge_r = ballX + (BALL_W-1)>>1;
assign ball_edge_t = ballY - (BALL_H)>>1;
assign ball_edge_b = ballY + (BALL_H-1)>>1;

assign ball_edge_l_next = ball_edge_l + vX;
assign ball_edge_r_next = ball_edge_b + vX;
assign ball_edge_t_next = ball_edge_t + vY;
assign ball_edge_b_next = ball_edge_b + vX;

always @(*) begin


	// hit left & right walls
	if (ball_edge_l + vX < wallLeft) begin
		vX_n = -vX;
		ballX_n = wallLeft + (wallLeft - ball_edge_l_next) + (BALL_W>>1);
	end 
	else if (ball_edge_r + vX > wallRight) begin
		vX_n = -vX;
		ballX_n = wallRight - (ball_edge_r_next - wallRight) - ((BALL_W-1)>>1);
	end
	else if ((ball_edge_l + vX > paddleRight) && (ball_edge_b + vY > paddleTop) && (ball_edge_t + vY < paddleBottom)) begin
		vX_n = -vX;
		ballX_n = paddleRight + (paddleRight - ball_edge_l_next) + (BALL_W>>1);
	end
	else if (ball_edge_r + vY < paddleLeft && (ball_edge_b + vY > paddleTop) && (ball_edge_t + vY < paddleBottom)) begin
		vX_n = -vX;
		ballX_n = paddleLeft - (ball_edge_r_next - paddleLeft) - ((BALL_W-1)>>1);
	end
	else begin
		vX_n = vX;
		ballX_n = ballY + vX;
	end
	

	if (ball_edge_t + vY < wallTop) begin
		vY_n = -vY;
		ballY_n = wallTop + (wallTop - ball_edge_t_next) + (BALL_H>>1);
	end 
	else if (ball_edge_b + vY > wallBottom) begin
		vY_n = -vY;
		ballY_n = wallBottom - (ball_edge_b_next - wallBottom) - ((BALL_H-1)>>1);
	end
	else if (ball_edge_b + vY > paddleTop && (ball_edge_l + vX > paddleRight) && (ball_edge_r + vX < paddleTop)) begin
		vY_n = -vY;
		ballY_n = paddleTop - (ball_edge_b_next - paddleTop) - ((BALL_H)>>1);	
	end
	else if (ball_edge_t + vY < paddleBottom && (ball_edge_l + vX > paddleRight) && (ball_edge_r + vX < paddleTop)) begin
		vY_n = -vY;
		ballY_n = paddleBottom + (paddleBottom - ball_edge_t_next) + ((BALL_H-1)>>1);	
	end
	else begin
		vY_n = vY;
		ballY_n = ballY + vY;
	end


end


endmodule