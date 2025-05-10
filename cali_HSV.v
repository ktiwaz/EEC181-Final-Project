module cali_HSV(
	input  [7:0] raw_R,
	input  [7:0] raw_G,
	input  [7:0] raw_B,
	input  clk,
	input  reset_n,
	input  start,
	input  [12:0] row,
	input  [12:0] col,
	input  [9:0] c_row,
	input  [9:0] c_col,
	input  rgb_HSV,
	output signed [13:0] H_out, //H
	output        [7:0] S_out,  //diff
	output        [7:0] V_out,  //max
	output        [4:0] Ctr
);

reg [7:0]  accum_counter, accum_counter_c;
reg [19:0] R_accum, R_accum_c;
reg [19:0] G_accum, G_accum_c;
reg [19:0] B_accum, B_accum_c;

reg signed [13:0] H,H_c;

reg [7:0] R,R_c;
reg [7:0] G,G_c;
reg [7:0] B,B_c;

assign H_out = (rgb_HSV == 1'b1) ? R : H[13:0];
assign S_out = (rgb_HSV == 1'b1) ? G : diff;
assign V_out = (rgb_HSV == 1'b1) ? B : max;

reg [2:0] S,next_S;
reg [4:0] C, C_c;
reg [7:0] max, max_c;
reg [7:0] min, min_c;
reg [7:0] diff, diff_c;

assign Ctr = C;

localparam START = 3'b000;
localparam ACCUMULATE = 3'b001;
localparam CALCULATE_AVERAGE = 3'b010;
localparam CALCULATE_MAXMIN = 3'b011;
localparam CALCULATE_HSV = 3'b100;

localparam c_size = 10'd9;

always@(posedge clk) begin
	if(~reset_n)begin
		C <= 5'b0;
		S <= 2'b00;
		R_accum <= 14'b0;
		G_accum <= 14'b0;
		B_accum <= 14'b0;
		accum_counter <= 8'b0;
		H <= 8'b0;
		R <= 8'b0;
		G <= 8'b0;
		B <= 8'b0;
		max <= 8'b0;
		min <= 8'b0;
		diff <= 8'b0;
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
		H <= H_c;
		max <= max_c;
		min <= min_c;
		diff <= diff_c;
	end
end

always@(*) begin
	R_c = R;
	G_c = G;
	B_c = B;
	max_c = max;
	min_c = min;
	diff_c = diff;
	H_c = H;
	case (S)
		START: begin
			C_c = C;
			R_accum_c = 14'b0;
			G_accum_c = 14'b0;
			B_accum_c = 14'b0;
			accum_counter_c = 8'b0;
			H_c = H;

			if (start) begin
				H_c = 8'b0;
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
			H_c = H;
			if ((row > c_row)&(row < (c_row + c_size))&(col > c_col)&(col < (c_col + c_size))) begin
				R_accum_c = R_accum + raw_R;
				G_accum_c = G_accum + raw_G;
				B_accum_c = B_accum + raw_B;
				accum_counter_c = accum_counter + 8'b1;
				if(accum_counter == 8'd63)begin
					next_S = CALCULATE_AVERAGE;
				end
			end 
		end
		
		CALCULATE_AVERAGE: begin
			C_c = C;
			R_accum_c = R_accum;
			G_accum_c = G_accum;
			B_accum_c = B_accum;
			accum_counter_c = 8'b0;
			H_c = H;
			
			R_c = R_accum >> 6;
			G_c = G_accum >> 6;
			B_c = B_accum >> 6;
			
			next_S = CALCULATE_MAXMIN;
		end
		
		CALCULATE_MAXMIN: begin
			next_S = CALCULATE_HSV;
			C_c = C;
			R_accum_c = R_accum;
			G_accum_c = G_accum;
			B_accum_c = B_accum;
			accum_counter_c = accum_counter;
			H_c = H;
			
			if (R > G) begin
				if (R > B) begin
					max_c = R;
				end
				else begin
					max_c = B;
				end
			end
			else begin
				if (G > B) begin
					max_c = G;
				end
				else begin
					max_c = B;
				end
			end
			
			if (R < G) begin
				if (R < B) begin
					min_c = R;
				end
				else begin
					min_c = B;
				end
			end
			else begin
				if (G < B) begin
					min_c = G;
				end
				else begin
					min_c = B;
				end
			end
		end
		
		CALCULATE_HSV: begin
			C_c = C;
			R_accum_c = R_accum;
			G_accum_c = G_accum;
			B_accum_c = B_accum;
			accum_counter_c = accum_counter;
			diff_c = max - min;
			
			if (max == R) 
				H_c = (G - B);
			else if (max == G) 
				H_c = (B - R) + ((max<<1) - (min<<1));
			else if (max == B)
				H_c = (R - G) + ((max<<2) - (min<<2));
				
			if(start)begin
				next_S = CALCULATE_HSV;
			end
			else begin
				next_S = START;
			end	
		end
				
	endcase
end

endmodule