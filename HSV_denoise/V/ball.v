module ball(
	input        clk,
	input        reset_n,
	input        sync,
	input [12:0] T,
	input [12:0] B,
	input [12:0] L,
	input [12:0] R,
	output [12:0] row,
	output [12:0] col
);

// drawing the ball
// define ball size
localparam radius = 5'd5;

// ball movement
localparam c_speed = 5'd1;// define the speed for column and row
localparam r_speed = 5'd1;

// define ball position
reg [12:0] c_ball, c_ball_c;
reg [12:0] r_ball, r_ball_c;

// define velocity
reg UD, UD_c;
reg LR, LR_c;

assign row = r_ball;
assign col = c_ball;

always@(posedge clk)begin
	UD <= UD_c;
	LR <= LR_c;
	c_ball <= c_ball_c;
	r_ball <= r_ball_c;
end

// checking ball's position with in the box (T,B,L,R) and with the 4 sides based on the sync signal

always@(*)begin
	
	UD_c = UD;
	LR_c = LR;
	
	c_ball_c = c_ball;
	r_ball_c = r_ball;
	
	if(sync)begin // one frame check position
		// default ball row, col movement
		if (LR) begin                    
			c_ball_c = c_ball + c_speed;
		end
		else begin
			c_ball_c = c_ball - c_speed;
		end
		if (UD) begin
			r_ball_c = r_ball + r_speed;
		end
		else begin
			r_ball_c = r_ball - r_speed;
		end
		
		// collision checking
		// horizontal logic
		if (LR) begin // right moving logic
			if ((c_ball + c_speed + radius) >= 10'd616) begin // right wall
				c_ball_c = 10'd616 + 10'd616 - c_ball - radius - radius - c_speed;
				LR_c = 1'b0;
			end
			
			if (((c_ball+radius) < L)&&((c_ball + c_speed + radius) >= L) && (r_ball>=T) && (r_ball<=B)) begin // paddle - L
				c_ball_c = L + L - c_ball - radius - radius - c_speed;
				LR_c = 1'b0;
			end
		end
		
		else begin // left moving logic
			if (c_ball < (c_speed + radius)) begin // left wall
				c_ball_c = c_speed - c_ball + (radius << 1);
				LR_c = 1'b1;
			end
			
			if (((c_ball-radius) > R)&&((c_ball - c_speed - radius) <= R) && (r_ball>=T) && (r_ball<=B)) begin // paddle - R
				c_ball_c = (R << 1) + c_speed - c_ball + (radius << 1);
				LR_c = 1'b1;
			end
		end
		
		
		
		
		// vertical logic
		if	(UD) begin // dowm moving logic
			if ((r_ball + r_speed + radius) >= 10'd477) begin // bot wall
				r_ball_c = 10'd477 + 10'd477 - r_ball - radius - radius - r_speed;
				UD_c = 1'b0;
			end
			
			if (((r_ball+radius) < T)&&((r_ball + r_speed + radius) >= T) && (c_ball >= L) && (c_ball <= R)) begin // paddle - T
				r_ball_c = T + T - r_ball - radius - radius - r_speed;
				UD_c = 1'b0;
			end
		end
		else begin // up moving logic
			if (r_ball < (r_speed + radius)) begin // top wall
				r_ball_c = r_speed - r_ball + (radius << 1);
				UD_c = 1'b1;
			end
			
			if (((r_ball-radius) > B)&&((r_ball - r_speed - radius) <= B) && (c_ball >= L) && (c_ball <= R)) begin // paddle - B
				r_ball_c = (B << 1) + r_speed - r_ball + (radius << 1);
				UD_c = 1'b1;
			end

		end
		
	end
	
	if(~reset_n)begin
		UD_c = 1'b1;
		LR_c = 1'b1;
		c_ball_c = 10'd20;
		r_ball_c = 10'd20;
	end
end

endmodule