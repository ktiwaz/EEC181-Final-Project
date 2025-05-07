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
	output reg [COLORS:0] out_img,
	output out_valid
);

localparam SUM_WIDTH = $clog2(N_SIZE*N_SIZE);

reg [SUM_WIDTH-1:0] neighborhood_count[COLORS-1:0]; 


wire [COLORS:0] in_img_center;
assign in_img_center = in_img[N_SIZE/2][N_SIZE/2];

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
end

// Delays output so that the results from a pixel occurs exactly SIZE/2 + 1 rows after the center pixel enters
// must be used in conjunction with a sliding window instantiation to work (will integrate here later)
localparam OUT_DELAY_CYCLES = (N_SIZE / 2) + 1;

reg [COLORS:0] r_denoised_img[0:OUT_DELAY_CYCLES-1];
reg r_denoised_img_valid[0:OUT_DELAY_CYCLES-1];


always @(posedge clk) begin
	r_denoised_img[0] <= denoised_img;
	r_denoised_img_valid[0] <= in_img_center[COLORS];
end


genvar d;
generate
for (d = 1; d < OUT_DELAY_CYCLES - 1; d = d + 1) begin : delay_reg
	always @(posedge clk) begin
		r_denoised_img[d] <= r_denoised_img[d-1];
		r_denoised_img_valid[d] <= r_denoised_img_valid[d-1];
	end
end
endgenerate

assign img_out = r_denoised_img[OUT_DELAY_CYCLES - 1];
assign out_valid = r_denoised_img_valid[OUT_DELAY_CYCLES - 1];


endmodule