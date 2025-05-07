module paddle_localization #(
	parameter PIXEL_DEPTH = 8,
	parameter THRESH_WIDTH = 6
) (
	input [PIXEL_DEPTH-1:0] input_R,
    input [PIXEL_DEPTH-1:0] input_G,
    input [PIXEL_DEPTH-1:0] input_B,

	input [THRESH_WIDTH-1:0] uTarget1,
	input [THRESH_WIDTH-1:0] vTarget1,
	input [THRESH_WIDTH-1:0] uTarget2,
	input [THRESH_WIDTH-1:0] vTarget2,

	input [10:0] row,
	input [11:0] col

);

// Parameter Definitions
localparam U_THRESH = 3'd5; // doesn't do anything right now
localparam V_THRESH = 3'd5;


// Wire Declarations
wire [7:0] Y;  // this might be scuffed (maybe not anymore)
wire signed [8:0] U, V;

wire [THRESH_WIDTH-1:0] uThresh, vThresh;
wire [1:0] cEncoded;
wire cEncodedValid;


// Wire Assignments
assign uThresh = U_THRESH;
assign vThresh = V_THRESH;


yuv_convert yuv(.raw_VGA_R(input_R), .raw_VGA_G(input_G), .raw_VGA_B(input_B),
				.Y(Y), .U(U), .V(V));

// TODO: Define img_in_valid (should be based on the row number coming in)

two_color_mask c_mask(.U(U), .V(V), .in_valid(img_in_valid),
						.uTarget1(uTarget1), .vTarget1(vTarget1), .uThresh1(5), .vThresh1(5),
									.uTarget2(uTarget2), .vTarget2(vTarget2), .uThresh2(5), .vThresh2(5),
									.colorEncoding(cEncoded), .outValid(cEncodedValid));


localparam DENOISE_WIDTH = 5;
wire [2:0] denoise_in [0:DENOISE_WIDTH-1][0:DENOISE_WIDTH-1];
wire frameCode; // toggles between 0 and 1 to denote the arrival of a new frame (should function as a valid bit)

wire [2:0] denoise_out;
wire denoise_out_valid;

sliding_window #(.NUMBER_OF_LINES(DENOISE_WIDTH), .WIDTH(LINE_WIDTH), .BUS_SIZE(3)) two_color_pre_noise_inst(
	.clock(clk),
	.EN(cEncodedValid),
	.data({frameCode, cEncoded}),
	.dataout(denoise_in)
);

denoise_color_masked_image #(.N_SIZE(DENOISE_WIDTH), .COLORS(2), .N_THRESHOLD(5)) denoiser_inst(
	.in_img(denoise_in),
	.denoised_img(denoise_out),
	.out_valid(denoise_out_valid)
);

//////////////////////
// Sobel component

localparam KERNEL_WIDTH = 8;
localparam K_SIZE = 3;

wire signed [KERNEL_WIDTH-1:0] w_kernel [0:K_SIZE-1] [0:K_SIZE-1];
reg conv_valid_i;
wire conv_valid_o;
wire [7:0] edgeData;


kernelLoad #(.SIZE(K_SIZE)) k_load(.kernel(w_kernel));


always @(*) begin
	if (row >= 0 && row < 480 && col >= 0 && col < 640) begin
		conv_valid_i = 1'b1;
	end else begin
		conv_valid_i = 1'b0;
	end
	
end

conv_kernel_sobel #(.SIZE(K_SIZE), .LINE_WIDTH(640), .PIXEL_DEPTH(8), .KERNEL_WIDTH(KERNEL_WIDTH)) edge_convolve (.clk(clk),
 					.valid_i(conv_valid_i), .inputLUM(Y), .kernel(w_kernel), .valid_o(conv_valid_o), .outputE(edgeData));







	
endmodule