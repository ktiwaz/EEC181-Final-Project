module paddle_localization_demo #(
	parameter PIXEL_DEPTH = 8,
	parameter THRESH_WIDTH = 8,
	parameter LINE_WIDTH = 640
) (
  input clk,
  input [9:1] SW,

	input [PIXEL_DEPTH-1:0] input_R,
  input [PIXEL_DEPTH-1:0] input_G,
  input [PIXEL_DEPTH-1:0] input_B,
  input input_valid,

	input signed [THRESH_WIDTH-1:0] uTarget1,
	input signed [THRESH_WIDTH-1:0] vTarget1,
	input signed [THRESH_WIDTH-1:0] uTarget2,
	input signed [THRESH_WIDTH-1:0] vTarget2,

  input signed [THRESH_WIDTH-1:0] uThresh1,
	input signed [THRESH_WIDTH-1:0] vThresh1,
	input signed [THRESH_WIDTH-1:0] uThresh2,
	input signed [THRESH_WIDTH-1:0] vThresh2,


	input [12:0] row,
	input [12:0] col,

  output reg [PIXEL_DEPTH-1:0] output_R,
  output reg [PIXEL_DEPTH-1:0] output_G,
  output reg [PIXEL_DEPTH-1:0] output_B
);




//////////////////////////////////////////
// YUV Conversion
//////////////////////////////////////////

  wire [7:0] pixel_Y;
  wire signed [8:0] pixel_U;
  wire signed [8:0] pixel_V;


yuv_convert yuv_inst(
  .raw_VGA_R(input_R),
  .raw_VGA_G(input_G),
  .raw_VGA_B(input_B),
  .Y(pixel_Y),
  .U(pixel_U),
  .V(pixel_V)
);


//////////////////////////////////////////
// Two Color Masking
//////////////////////////////////////////

parameter YUV_TARGET_WIDTH = THRESH_WIDTH;
parameter YUV_THRESHOLD_WIDTH = THRESH_WIDTH;

wire [1:0] masked_out;
wire masked_out_valid;

two_color_mask #(
  .YUV_WIDTH(YUV_TARGET_WIDTH),
  .THRESH_WIDTH(YUV_THRESHOLD_WIDTH)
  )  mask_inst(
  .in_valid(in_valid), // from input
  .U(pixel_U),
  .V(pixel_V),
  .uTarget1(uTarget1),  // connect these to calibration inputs in actual demo
  .vTarget1(vTarget1), // connect these to calibration inputs in actual demo
  .uThresh1(uThresh1),
  .vThresh1(vThresh1),
  
  .uTarget2(uTarget2), // connect these to calibration inputs in actual demo
  .vTarget2(vTarget2), // connect these to calibration inputs in actual demo
  .uThresh2(uThresh2),
  .vThresh2(vThresh2),

  .colorEncoding(masked_out),
  .out_valid(masked_out_valid)
);


//////////////////////////////////////////
// Denoising
//////////////////////////////////////////

parameter DENOISE_WIDTH = 3;
localparam DENOISE_DELAY = (DENOISE_WIDTH / 2);
localparam COLORS = 2; // for potential multi color versions in the future

wire [1:0] masked_out_d;
wire input_valid_d;
wire [COLORS:0] denoise_in [0:DENOISE_WIDTH-1][0:DENOISE_WIDTH-1];
wire [COLORS:0] denoise_out;
wire denoise_out_valid;


// delays the masked_out & masked_out_valid signals by a few cycles to make delays 
// a full line
simple_line_buffer #(.NUMBER_OF_LINES(1), .WIDTH(DENOISE_DELAY), .BUS_SIZE(2)) denoise_in_buff(
  .clock(clk),
  .EN(1'b1),
  .data(masked_out),
  .dataout(masked_out_d)
);

simple_line_buffer #(.NUMBER_OF_LINES(1), .WIDTH(DENOISE_DELAY), .BUS_SIZE(1)) denoise_in_valid_regs(
  .clock(clk),
  .EN(1'b1),
  .data(input_valid),
  .dataout(input_valid_d)
);


sliding_window #(.NUMBER_OF_LINES(DENOISE_WIDTH), .WIDTH(LINE_WIDTH), .BUS_SIZE(COLORS+1)) denoise_window_inst(
	.clock(clk),
	.EN(input_valid_d),
	.data({input_valid_d, masked_out_d}),
	.dataout(denoise_in)
);


denoise_color_masked_image #(
	.N_SIZE(DENOISE_WIDTH),
  .COLORS(COLORS),
	.N_THRESHOLD(5)
) denoise_inst(
  .clk(clk),
	.in_img(denoise_in),
  .out_img(denoise_out),
	.out_valid(denoise_out_valid)
);


//////////////////////////////////////////
// Convolution
//////////////////////////////////////////

parameter KERNEL_SIZE = 3;
localparam KERNEL_DELAY = (KERNEL_SIZE / 2);

wire [3:0] kernel [0:2] [0:2]; // should be replaced later (if not now)
wire [7:0] edge_conv_out;
wire edge_conv_out_1b, edge_conv_out_valid;


assign kernel[0][0] = -1;
assign kernel[0][1] = -2;
assign kernel[0][2] = -1;
assign kernel[1][0] = 0;
assign kernel[1][1] = 0;
assign kernel[1][2] = 0;
assign kernel[2][0] = 1;
assign kernel[2][1] = 2;
assign kernel[2][2] = 1;


conv_kernel_sobel # (
  .SIZE(KERNEL_SIZE),
  .LINE_WIDTH(LINE_WIDTH),
  .PIXEL_DEPTH(PIXEL_DEPTH),
  .KERNEL_WIDTH(4)
)
sobel_conv_inst (
  .clk(clk),
  .valid_i(input_valid),
  .inputLUM(pixel_Y),
  .kernel(kernel),
  .valid_o(edge_conv_out_valid),
  .outputEdge(edge_conv_out)
);

assign edge_conv_out_1b = edge_conv_out[7]; // probably also should refactor

//////////////////////////////////////////
// Edge Buffer
//////////////////////////////////////////

parameter MERGE_WIDTH = 11;
localparam MERGE_DELAY = MERGE_WIDTH / 2; 

localparam EDGE_BUFFER_LINES = MERGE_DELAY + DENOISE_DELAY - KERNEL_DELAY;

wire [1:0] edge_data_d;
wire edge_conv_out_d, edge_conv_out_valid_d;

simple_line_buffer #(
  .NUMBER_OF_LINES(EDGE_BUFFER_LINES),
  .WIDTH(LINE_WIDTH),
  .BUS_SIZE(2)
) edge_line_buffer (
  .clock(clk),
  .EN(1'b1),
  .data({edge_conv_out_valid, edge_conv_out_1b}),
  .dataout(edge_data_d)
);

assign edge_conv_out_d = edge_data_d[0];
assign edge_conv_out_valid_d = edge_data_d[1];

//////////////////////////////////////////
// Merge
//////////////////////////////////////////

// Params in above section


wire [COLORS:0] denoise_out_d;
wire denoise_out_valid_d;

wire [COLORS:0] merge_in [0:MERGE_WIDTH-1][0:MERGE_WIDTH-1];
wire merge_out, merge_out_valid;


simple_line_buffer #(.NUMBER_OF_LINES(1), .WIDTH(MERGE_DELAY), .BUS_SIZE(COLORS+1)) merge_in_regs(
  .clock(clk),
  .EN(1'b1),
  .data(denoise_out),
  .dataout(denoise_out_d)
);

simple_line_buffer #(.NUMBER_OF_LINES(1), .WIDTH(MERGE_DELAY), .BUS_SIZE(1)) merge_in_valid_regs(
  .clock(clk),
  .EN(1'b1),
  .data(denoise_out_valid),
  .dataout(denoise_out_valid_d)
);


sliding_window #(.NUMBER_OF_LINES(MERGE_WIDTH), .WIDTH(LINE_WIDTH), .BUS_SIZE(3)) merge_window_inst(
	.clock(clk),
	.EN(denoise_out_valid_d),
	.data(denoise_out_d),
	.dataout(merge_in)
);

// switch threshold to 2
edge_color_mask_merge #(.M_SIZE(MERGE_WIDTH), .M_THRESHOLD(2), .COLORS(COLORS), .EDGE_DATA_WIDTH(1)) merge_inst(
	.clk(clk),
  .color_masked_img(merge_in),
  .in_edge_data({edge_conv_out_valid_d, edge_conv_out_d}),
	.out_edge_data(merge_out),
	.out_valid(merge_out_valid)
);



//////////////////////////////////////////
// Output Logic (for debugging)  // check valid rows & cols in outside module
//////////////////////////////////////////
always @(*) begin
  if (SW[9] == 1'b1) begin  // display based on color masking
      if (masked_out[1] == 1'b1) begin
          output_R = 8'hff;
      end
      if (masked_out[0] == 1'b1) begin
          output_G = 8'hff;
      end

      output_B = 8'h0;
  end 

  if (SW[8] == 1'b1) begin // display denoised data
      if (denoise_out[1] == 1'b1) begin
          output_R = 8'hff;
      end
      if (denoise_out[0] == 1'b1) begin
          output_G = 8'hff;
      end

      output_B = 8'h0;
  end

  if (SW[7] == 1'b1) begin // display convolution data
      output_R = edge_conv_out;
      output_G = edge_conv_out;
      output_B = edge_conv_out;
  end
  if (SW[6] == 1'b1) begin  // display masked edge data
    if (merge_out == 1'b1) begin
      output_R = 8'hff;
      output_G = 8'hff;
      output_B = 8'hff;
    end else begin
      output_R = 8'h0;
      output_G = 8'h0;
      output_B = 8'h0;
    end
  end

  else begin
    output_R = input_R;
    output_G = input_G;
    output_B = input_B;
  end
end

endmodule