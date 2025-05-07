module edge_color_mask_merge #(
	parameter M_SIZE = 11,
	parameter M_THRESHOLD = 2,
	parameter EDGE_DATA_WIDTH = 1,
	parameter COLORS = 2
)(
	input clk,
	input [COLORS:0] color_masked_img [0:M_SIZE-1][0:M_SIZE-1],
	input [EDGE_DATA_WIDTH:0] in_edge_data,
	output reg out_edge_data,
	output out_valid
);

localparam SUM_WIDTH = $clog2(M_SIZE*M_SIZE);
localparam DELAY_AMOUNT = (M_SIZE / 2) + 1;

reg [SUM_WIDTH-1:0] neighborhood_count[COLORS-1:0];

reg [COLORS-1:0] pixel_count_achieved;

integer c, i, j;

always @(*) begin
	for (c = 0; c <= COLORS; c = c + 1) begin
		neighborhood_count[c] = 0;

		for (i = 0; i < M_SIZE; i = i + 1) begin
			for (j = 0; j < M_SIZE; j = j + 1) begin

				// Neighbor added to the count only if the pixel at the position is valid (otherwise, ignores it)
				if (color_masked_img[i][j][COLORS] == 1'b1) begin
					neighborhood_count[c] = neighborhood_count[c] + color_masked_img[i][j][c];
				end else begin
					neighborhood_count[c] = neighborhood_count[c];
				end

			end
		end
	
		if (neighborhood_count[c] >= M_THRESHOLD) begin
			pixel_count_achieved[c] = 1'b1;
		end else begin
			pixel_count_achieved[c] = 1'b0;
		end

	end

	if (&pixel_count_achieved == 1'b1) begin
		out_edge_data = in_edge_data;
	end else begin
		out_edge_data = 1'b0;
	end

end

endmodule