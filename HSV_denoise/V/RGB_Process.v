module RGB_Process(
	input  [7:0] raw_VGA_R,
	input  [7:0] raw_VGA_G,
	input  [7:0] raw_VGA_B,
	
	input  [12:0] row,
	input  [12:0] col,

	output reg [7:0] o_VGA_R,
	
	output reg [7:0] o_VGA_G,
	output reg [7:0] o_VGA_B,
	output reg o_color
);

wire signed [13:0] H_o;
wire        [7:0] S_o;
wire        [7:0] V_o;
wire        [7:0] V_thresh;

HSV pixel_HSV(
	.R   (raw_VGA_R),
	.G   (raw_VGA_G),
	.B   (raw_VGA_B),
	.H_o (H_o),
	.S_o (S_o),
	.V_o (V_o)
);

wire [13:0] H_u,H_d;

// H, S=diff, V=max

assign H_u = {6'b0,S_o<<1} + {6'b0,S_o>>2}; //3.5
assign H_d = {6'b0,S_o} + {6'b0,S_o>>1} + {6'b0,S_o>>2}; //0.75
assign V_thresh = V_o>>2;

					// else begin
					// 	if ((H_o<(H_out - 14'sd20)) || (H_o>(H_out + 14'sd20)) || (S_o<(S_out - 8'd20)) || (S_o>(S_out + 8'd20)) || (V_o<(V_out - 8'd20)) || (V_o > (V_out + 8'd20))) begin
					// 		o_VGA_R = 8'hFF;
					// 		o_VGA_B = 8'hFF;
					// 		o_VGA_G = 8'hFF;
					// 	end
					// end

always @(*)begin
		if (row <= 13'd477 && col <= 13'd617) begin
			o_VGA_R = raw_VGA_R;
			o_VGA_B = raw_VGA_B;
			o_VGA_G = raw_VGA_G;

			if((H_o<H_d)||(H_o>H_u)||(S_o < V_thresh))begin
				o_color = 1'b0;

			end	else begin
				o_color = 1'b1;
			end

		end else begin // Out of range
			o_VGA_R = 8'd0;
			o_VGA_G = 8'd0;
			o_VGA_B = 8'd0;
			o_color = 1'b0;
		end
end
endmodule
