module conv_kernel #(
    parameter SIZE = 3,         // Should be odd (I think)
    parameter LINE_WIDTH = 640,
    parameter PIXEL_DEPTH = 8,
    parameter KERNEL_WIDTH = 8
) (

    input clk,
    input valid_i,

    input [PIXEL_DEPTH-1:0] input_R,
    input [PIXEL_DEPTH-1:0] input_G,
    input [PIXEL_DEPTH-1:0] input_B,

    input signed [KERNEL_WIDTH-1:0] kernel [0:SIZE-1] [0:SIZE-1],  // NxN convolutional kernel
    input [KERNEL_WIDTH-1:0] normalizing_factor,

    output valid_o,
    output reg [PIXEL_DEPTH-1:0] output_R,
    output reg [PIXEL_DEPTH-1:0] output_G,
    output reg [PIXEL_DEPTH-1:0] output_B
);

localparam LINE_BUFFER_BUS_SIZE = 3*PIXEL_DEPTH + 1; // Extra bit for valid``
localparam SUM_WIDTH = KERNEL_WIDTH + PIXEL_DEPTH + $clog2(SIZE*SIZE);

wire [LINE_BUFFER_BUS_SIZE-1:0] window [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

reg signed [SUM_WIDTH-1:0] sum_R, sum_G, sum_B;

wire valid_out;

assign valid_out = window[0][0][LINE_BUFFER_BUS_SIZE-1]; 
assign valid_o = valid_out;

sliding_window # (
    .NUMBER_OF_LINES(SIZE),
    .WIDTH(LINE_WIDTH),
    .BUS_SIZE(LINE_BUFFER_BUS_SIZE)
  )
  sliding_window_inst (
    .clock(clk),
    .EN(valid_i),
    .data({valid_i, input_R, input_G, input_B}),
    .dataout(window)
  );

  integer i, j;

  always @(*) begin
    // Initialize sums to 0 for each color channel
    sum_R = 0;
    sum_G = 0;
    sum_B = 0;
    output_R = 0;
    output_G = 0;
    output_B = 0;
    
    // Apply the kernel to the window
    for (i = 0; i < SIZE; i = i + 1) begin
        for (j = 0; j < SIZE; j = j + 1) begin
            // Apply kernel for red channel

            if (kernel[i][j] < 0) begin
                sum_R = sum_R - (window[i][j][3*PIXEL_DEPTH-1:2*PIXEL_DEPTH] * kernel[i][j]);
                sum_G = sum_G - (window[i][j][2*PIXEL_DEPTH-1:PIXEL_DEPTH] * kernel[i][j]);
                sum_B = sum_B - (window[i][j][PIXEL_DEPTH-1:0] * kernel[i][j]);    

            end else begin
                sum_R = sum_R + (window[i][j][3*PIXEL_DEPTH-1:2*PIXEL_DEPTH] * kernel[i][j]);
                sum_G = sum_G + (window[i][j][2*PIXEL_DEPTH-1:PIXEL_DEPTH] * kernel[i][j]);
                sum_B = sum_B + (window[i][j][PIXEL_DEPTH-1:0] * kernel[i][j]);
            end
        end
    end

    sum_R = sum_R / normalizing_factor;
    sum_G = sum_G / normalizing_factor;
    sum_B = sum_B / normalizing_factor;


    if (valid_out) begin
        if (sum_R > -255 && sum_R < 0) begin
            output_R = -sum_R;
        end else if (sum_R > 255 || sum_R < -255) begin
            output_R = 8'd255;
        end else begin
            output_R = sum_R;
        end

        if (sum_G > -255 && sum_G < 0) begin
            output_G = -sum_G;
        end else if (sum_G > 255 || sum_G < -255) begin
            output_G = 8'd255;
        end else begin
            output_G = sum_G;
        end

        if (sum_B > -255 && sum_B < 0) begin
            output_B = -sum_B;
        end else if (sum_B > 255 || sum_B < -255) begin
            output_B = 8'd255;
        end else begin
            output_B = sum_B;
        end
    end

end
endmodule
