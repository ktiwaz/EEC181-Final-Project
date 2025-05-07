module tb_edge_color_mask_merge;

  // Testbench parameters
  parameter WIDTH = 640;
  parameter HEIGHT = 480;
  parameter MEM_DEPTH = WIDTH * HEIGHT;
  parameter INDEX_WIDTH = 19;

  parameter DENOISE_WIDTH = 3;
  parameter MERGE_WIDTH = 11;
  parameter COLORS = 2;

  // Testbench signals
  reg clk;
  reg reset_n;
  reg [12:0] row = 0;
  reg [12:0] col = 0;
  wire [7:0] VGA_R;
  wire [7:0] VGA_G;
  wire [7:0] VGA_B;

  wire [7:0] oVGA_R;
  wire [7:0] oVGA_G;
  wire [7:0] oVGA_B;

  wire valid;

  reg [7:0] red_out, green_out;
  reg [7:0] blue_out;
  wire out_valid;


  // Instantiate the image_loader module
  image_loader #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .INDEX_WIDTH(INDEX_WIDTH)
  ) img_load_inst (
    .clk(clk),
    .reset_n(reset_n),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .valid(valid)
  );

reg [2:0] encoded_color_masked_img;
reg [1:0] edge_img, edge_img_buff;

always @(*) begin
  if (VGA_R == 8'hff) begin
    encoded_color_masked_img[1] = 1'b1;
  end else begin
    encoded_color_masked_img[1] = 1'b0;
  end

  if (VGA_G == 8'hff) begin
    encoded_color_masked_img[0] = 1'b1;
  end else begin
    encoded_color_masked_img[0] = 1'b0;
  end

  if (VGA_B == 8'hff) begin
    edge_img[0] = 1'b1;
  end else begin
    edge_img[0] = 1'b0;
  end

  encoded_color_masked_img[2] = valid;
  edge_img[1] = valid;
  
end


wire [COLORS:0] denoise_in [0:DENOISE_WIDTH-1][0:DENOISE_WIDTH-1];
wire [COLORS:0] denoise_out;
wire denoise_out_valid;



// DENOISER

sliding_window #(.NUMBER_OF_LINES(DENOISE_WIDTH), .WIDTH(WIDTH), .BUS_SIZE(COLORS+1)) buffer_inst(
	.clock(clk),
	.EN(valid),
	.data(encoded_color_masked_img),
	.dataout(denoise_in)
);

// no padding yet exists --> might double count edges in this unmodified sim
// should probably update the testbench to allow testing of logic over the porches
denoise_color_masked_image #(
	.N_SIZE(DENOISE_WIDTH),
  .COLORS(COLORS),
	.N_THRESHOLD(5)
) UUT_denoiser(
  .clk(clk),
	.in_img(denoise_in),
  .denoised_img(denoise_out),
	.out_valid(denoise_out_valid)
);


// EDGE (delay this)

simple_line_buffer #(
  .NUMBER_OF_LINES(DENOISE_WIDTH),
  .WIDTH(WIDTH),
  .BUS_SIZE(2)
) edgeBuff (
  .clock(clk),
  .EN(valid),
  .data(edge_img),
  .dataout(edge_img_buff)
);


// MERGE

wire [COLORS:0] merge_in [0:MERGE_WIDTH-1][0:MERGE_WIDTH-1];
wire merge_out, merge_out_valid;

sliding_window #(.NUMBER_OF_LINES(MERGE_WIDTH), .WIDTH(WIDTH), .BUS_SIZE(3)) color_merged_buff(
	.clock(clk),
	.EN(denoise_out_valid),
	.data(denoise_out),
	.dataout(merge_in)
);

// switch threshold to 2
edge_color_mask_merge #(.M_SIZE(MERGE_WIDTH), .COLORS(2), .M_THRESHOLD(5)) merge_inst(
	.color_masked_img(merge_in),
  .edgeDataIn(edge_img_buff),
	.edgeDataOut(merge_out),
	.out_valid(merge_out_valid)
);


always @(*) begin
  if (merge_out == 1'b1) begin
    red_out = 8'hff;
    blue_out = 8'hff;
    green_out = 8'hff;
  end else begin
    red_out = 8'h0;
    blue_out = 8'h0;
    green_out = 8'h0;
  end
  
end

  // Instantiate the image_dumper module
  image_dumper #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .INDEX_WIDTH(INDEX_WIDTH)
  ) img_dump_inst (
    .clk(clk),
    .reset_n(reset_n),
    .VGA_R(red_out),
    .VGA_G(green_out),
    .VGA_B(blue_out),
    .valid(merge_out_valid)
  );

  // Clock generation
  always begin
    #5 clk = ~clk; // 100 MHz clock, adjust timing as needed
  end



  // Testbench logic
  initial begin
    // Dump signals to VCD file
    $dumpfile("image_load_dump.vcd"); // Specify VCD file name
    $dumpvars(0, tb_edge_color_mask_merge);    // Dump all signals in this module
    // Initialize signals
    clk = 0;
    reset_n = 0;

    // Apply reset
    $display("Applying reset...");
    #15 reset_n = 1; // Deassert reset after 10 time units

    // Simulate enough until dump (finish should be called in dumper)
    #3800000;

    // Finish the simulation (timeout)
    $finish;
  end


  genvar ii, jj;

  // generate
  // for (ii = 0; ii < 3; ii = ii + 1) begin
  //     for (jj = 0; jj < 3; jj = jj + 1) begin
  //         initial $dumpvars(0, kernel[ii][jj]);
  //     end
  // end
  // endgenerate

// Increment row and column
always @(posedge clk) begin
  if (~reset_n) begin
    row <= 0;
    col <= 0;
  end else begin
    if (valid) begin
      if(col == WIDTH - 1) begin
        col <= 0;
        row <= row + 1;
        if(row == HEIGHT - 1) begin
          row <= 0;
        end
      end else begin
        col <= col + 1;
      end
    end
  end
end

endmodule
