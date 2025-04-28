module tb_image_load_and_dump;

  // Testbench parameters
  parameter WIDTH = 640;
  parameter HEIGHT = 480;
  parameter MEM_DEPTH = WIDTH * HEIGHT;
  parameter INDEX_WIDTH = 19;

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

  wire [7:0] red_out, green_out, blue_out;
  wire out_valid;

//   assign out_valid = dataout[0][0][24];

//   wire [11:0] red_sum;
//   wire [11:0] green_sum;
//   wire [11:0] blue_sum;

//   wire [24:0] dataout [0:2][0:2]; // 3D array output
  
// // Red, Green, and Blue channel summations
// assign red_sum = dataout[0][0][23:16] + dataout[1][0][23:16] + dataout[2][0][23:16] +
//                  dataout[0][1][23:16] + dataout[1][1][23:16] + dataout[2][1][23:16] +
//                  dataout[0][2][23:16] + dataout[1][2][23:16] + dataout[2][2][23:16];

// assign green_sum = dataout[0][0][15:8] + dataout[1][0][15:8] + dataout[2][0][15:8] +
//                    dataout[0][1][15:8] + dataout[1][1][15:8] + dataout[2][1][15:8] +
//                    dataout[0][2][15:8] + dataout[1][2][15:8] + dataout[2][2][15:8];

// assign blue_sum = dataout[0][0][7:0] + dataout[1][0][7:0] + dataout[2][0][7:0] +
//                   dataout[0][1][7:0] + dataout[1][1][7:0] + dataout[2][1][7:0] +
//                   dataout[0][2][7:0] + dataout[1][2][7:0] + dataout[2][2][7:0];

// // Output assignments for the Red, Green, and Blue channels
// assign red_out   = (out_valid) ? (red_sum   / 9) : 8'd0;
// assign green_out = (out_valid) ? (green_sum / 9) : 8'd0;
// assign blue_out  = (out_valid) ? (blue_sum  / 9) : 8'd0;

  reg signed [6:0] kernel [0:10][0:10];
  

  // Instantiate the image_loader module
  image_loader #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .INDEX_WIDTH(INDEX_WIDTH)
  ) uut (
    .clk(clk),
    .reset_n(reset_n),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .valid(valid)
  );

  conv_kernel # (
    .SIZE(11),
    .LINE_WIDTH(640),
    .PIXEL_DEPTH(8),
    .KERNEL_WIDTH(7)
  )
  conv_kernel_inst (
    .clk(clk),
    .valid_i(valid),
    .input_R(VGA_R),
    .input_G(VGA_G),
    .input_B(VGA_B),
    .kernel(kernel),
    .normalizing_factor(7'd121),
    .valid_o(out_valid),
    .output_R(red_out),
    .output_G(green_out),
    .output_B(blue_out)
  );

  RGB_Process  RGB_Process_inst (
    .raw_VGA_R(red_out),
    .raw_VGA_G(green_out),
    .raw_VGA_B(blue_out),
    .row(row),
    .col(col),
    .filter_SW(6'b000000),
    .o_VGA_R(oVGA_R),
    .o_VGA_G(oVGA_G),
    .o_VGA_B(oVGA_B)
  );



  // Instantiate the image_dumper module
  image_dumper #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .INDEX_WIDTH(INDEX_WIDTH)
  ) uut1 (
    .clk(clk),
    .reset_n(reset_n),
    .VGA_R(red_out),
    .VGA_G(green_out),
    .VGA_B(blue_out),
    .valid(out_valid)
  );

  // Clock generation
  always begin
    #5 clk = ~clk; // 100 MHz clock, adjust timing as needed
  end



  // Testbench logic
  initial begin
    // Dump signals to VCD file
    $dumpfile("image_load_dump.vcd"); // Specify VCD file name
    $dumpvars(0, tb_image_load_and_dump);    // Dump all signals in this module
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

      // Initializing the kernel to all ones using a for loop (box blur)
  integer i, j;
  initial begin
      for (i = 0; i < 11; i = i + 1) begin
          for (j = 0; j < 11; j = j + 1) begin
              kernel[i][j] = 7'd1;
          end
      end
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
