// Takes in color data of a pixel and those within its "neighborhood" of size N
// where the neighborhood is the NxN box with the pixel at its center. If there
// are less than LIMIT number of pixels of the same color within this range, the 
// pixel is cleared

module denoise_color_masked_image #(
	parameter N_SIZE = 5,
	parameter COLORS = 2,
	parameter N_THRESHOLD = 5
)(
	input [COLORS:0] in_img [0:N_SIZE-1][0:N_SIZE-1],
	input clk,
	output [COLORS:0] out_img,
	output reg out_valid
);

localparam SUM_WIDTH = $clog2(N_SIZE*N_SIZE);

reg [SUM_WIDTH-1:0] neighborhood_count[COLORS-1:0]; 

localparam IN_IMG_CENTER = N_SIZE / 2;

wire [COLORS:0] in_img_center;
assign in_img_center = in_img[IN_IMG_CENTER][IN_IMG_CENTER];

reg [COLORS:0] denoised_img;

integer i, j;
//genvar c;
integer c;
/*
always @(posedge clk) begin
	for (i = 0; i < N_SIZE; i = i + 1) begin
		for (j = 0; j < N_SIZE; j = j + 1) begin
			r_in_img[i][j] <= in_img[i][j];
		end
	end
end*/

// For each color, generate a circuit that looks at its "neighborhood" for other pixels with that same color 
//for (c = 0; c < COLORS; c = c + 1) begin
	
always @(*) begin
	for (c = 0; c <= COLORS; c = c + 1) begin
		neighborhood_count[c] = 0;

		for (i = 0; i < N_SIZE; i = i + 1) begin
			for (j = 0; j < N_SIZE; j = j + 1) begin

				// Neighbor added to the count only if the pixel at the position is valid (otherwise, ignores it)
				if (in_img[i][j][COLORS] == 1'b1) begin
					neighborhood_count[c] = neighborhood_count[c] + in_img[i][j][c];
				end else begin
					neighborhood_count[c] = neighborhood_count[c];
				end

				//neighborhood_count[c] = neighborhood_count[c] + (r_in_img[i][j][c] && r_in_img[i][j][COLORS]);			
			end
		end

		// if the count exceeds the threshold and the image has a pixel of the given color --> write it
		if (neighborhood_count[c] >= N_THRESHOLD && in_img_center[c] == 1'b1) begin
			denoised_img[c] = 1'b1;
		end else begin
			denoised_img[c] = 1'b0;
		end
	end

	denoised_img[COLORS] = in_img_center[COLORS];
	out_valid = in_img_center[COLORS];
end

assign out_img = denoised_img;


endmodule