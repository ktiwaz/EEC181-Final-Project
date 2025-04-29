module calibration(
	input  [7:0] raw_R,
	input  [7:0] raw_G,
	input  [7:0] raw_B,
	input  clk,
	input  reset_n,
	input  start,
	input  [12:0] row,
	input  [12:0] col,
	input  [9:0] c2_row,
	input  [9:0] c2_col,
	input  rgb_yuv,
	output [7:0] Y_out,
	output signed [8:0] U_out,
	output signed [8:0] V_out,
	output [4:0] Ctr
);

reg [7:0]  accum_counter, accum_counter_c;
reg [19:0] R_accum, R_accum_c;
reg [19:0] G_accum, G_accum_c;
reg [19:0] B_accum, B_accum_c;

reg [19:0] Y,Y_c;
reg signed [16:0] U,U_c;
reg signed [16:0] V,V_c;

reg [7:0] R,R_c;
reg [7:0] G,G_c;
reg [7:0] B,B_c;

assign Y_out = (rgb_yuv == 1'b1) ? R : Y[7:0];
assign U_out = (rgb_yuv == 1'b1) ? G : U[8:0];
assign V_out = (rgb_yuv == 1'b1) ? B : V[8:0];

reg [1:0] S,next_S;
reg [4:0] C, C_c;

assign Ctr = C;

//Grey Scale
localparam red_code   = 8'd77;
localparam green_code = 8'd150;
localparam blue_code  = 8'd37;

// U，V
localparam U_code = 8'd126;
localparam V_code = 8'd225;

localparam START = 2'b00;
localparam ACCUMULATE = 2'b01;
localparam CALCULATE_Y = 2'b10;
localparam CALCULATE_UV = 2'b11;

localparam c2_size = 10'd9;
 
always@(posedge clk) begin
	if(~reset_n)begin
		C <= 1'b0;
		S <= START;
		R_accum <= 14'b0;
		G_accum <= 14'b0;
		B_accum <= 14'b0;
		accum_counter <= 8'b0;
		Y <= 8'b0;
		U <= 9'b0;
		V <= 9'b0;
		R <= 8'b0;
		G <= 8'b0;
		B <= 8'b0;
	end
	else begin
		C <= C_c;
		S <= next_S;
		R_accum <= R_accum_c;
		G_accum <= G_accum_c;
		B_accum <= B_accum_c;
		accum_counter <= accum_counter_c;
		R <= R_c;
		G <= G_c;
		B <= B_c;
		Y <= Y_c;
		U <= U_c;
		V <= V_c;
	end
end

always@(*) begin
	R_c = R;
	G_c = G;
	B_c = B;
	case (S)
		START: begin
			C_c = C;
			R_accum_c = 14'b0;
			G_accum_c = 14'b0;
			B_accum_c = 14'b0;
			accum_counter_c = 8'b0;
			Y_c = Y;
			U_c = U;
			V_c = V;
			
			if (start) begin
				Y_c = 8'b0;
				U_c = 9'b0;
				V_c = 9'b0;
				next_S = ACCUMULATE;
			end
			else begin
				next_S = START;
			end
		end
		ACCUMULATE: begin
			C_c = C;
			next_S = ACCUMULATE;
			R_accum_c = R_accum;
			G_accum_c = G_accum;
			B_accum_c = B_accum;
			accum_counter_c = accum_counter;
			Y_c = Y;
			U_c = U;
			V_c = V;
			if ((row > c2_row)&(row < (c2_row + c2_size))&(col > c2_col)&(col < (c2_col + c2_size))) begin
				R_accum_c = R_accum + raw_R;
				G_accum_c = G_accum + raw_G;
				B_accum_c = B_accum + raw_B;
				accum_counter_c = accum_counter + 1;
				if(accum_counter == 8'd63)begin
					next_S = CALCULATE_Y;
				end
			end 
		end
		CALCULATE_Y: begin
			C_c = C;
			next_S = ACCUMULATE;
			R_accum_c = R_accum;
			G_accum_c = G_accum;
			B_accum_c = B_accum;
			accum_counter_c = accum_counter;
			Y_c = Y;
			U_c = U;
			V_c = V;
			
			R_c = R_accum >> 6;
			G_c = G_accum >> 6;
			B_c = B_accum >> 6;
			
			Y_c = (red_code * (R_accum >> 6) + green_code * (G_accum >> 6) + blue_code * (B_accum >> 6))>>8;
			next_S = CALCULATE_UV;
		end
		
		CALCULATE_UV: begin
			C_c = C + 1;
			next_S = ACCUMULATE;
			R_accum_c = R_accum;
			G_accum_c = G_accum;
			B_accum_c = B_accum;
			accum_counter_c = accum_counter;
			Y_c = Y;
			U_c = U;
			V_c = V;

			U_c = (U_code * ((B_accum >> 6) - Y))>>8;
			V_c = (V_code * ((R_accum >> 6) - Y))>>8;

			next_S = START;
		end
	endcase
end

endmodule