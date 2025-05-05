// Converts RGB pixel values into YUV values (with integer precision)

module yuv_convert(
	input  [7:0] raw_VGA_R,
	input  [7:0] raw_VGA_G,
	input  [7:0] raw_VGA_B,
	output reg [7:0] Y,
	output signed [8:0] U,
	output signed [8:0] V
);

	// Grey Scale
	localparam red_code   = 8'd77;
	localparam green_code = 8'd150;
	localparam blue_code  = 8'd37;

	// U，V
	localparam U_code = 8'd126;
	localparam V_code = 8'd225;

	wire [19:0] Y_long;
	wire signed [19:0] U_long,V_long;

	assign Y_long = (((red_code * raw_VGA_R) + (green_code * raw_VGA_G) + (blue_code * raw_VGA_B))>>8);

	always @(*) begin
		if (Y_long >= 20'd256) begin
			Y = 8'hff;
		end else begin
			Y = Y_long[7:0];
		end
	end

	assign U_long = ((U_code * (raw_VGA_B - Y)) >> 8);
	assign V_long = ((V_code * (raw_VGA_R - Y)) >> 8);
	assign U = U_long[8:0];
	assign V = V_long[8:0];

endmodule