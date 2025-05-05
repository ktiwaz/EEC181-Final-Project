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
    output valid_o,
    output reg [PIXEL_DEPTH-1:0] output_R,
    output reg [PIXEL_DEPTH-1:0] output_G,
    output reg [PIXEL_DEPTH-1:0] output_B
);

localparam LINE_BUFFER_BUS_SIZE = 3*PIXEL_DEPTH + 1; // Extra bit for valid``
localparam SUM_WIDTH = KERNEL_WIDTH + PIXEL_DEPTH + $clog2(SIZE*SIZE);
localparam THRESHOLD = 50;

wire [LINE_BUFFER_BUS_SIZE-1:0] window [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire signed[PIXEL_DEPTH:0] window_R [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_G [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_B [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

integer i, j;

genvar iii, jjj;

// Manual sign extension
generate
    for(iii = 0; iii < SIZE; iii++) begin
        for(jjj=0; jjj < SIZE; jjj++) begin
            assign window_R[iii][jjj] = {1'b0, window[iii][jjj][3*PIXEL_DEPTH-1:2*PIXEL_DEPTH]};
            assign window_G[iii][jjj] = {1'b0, window[iii][jjj][2*PIXEL_DEPTH-1:PIXEL_DEPTH]};
            assign window_B[iii][jjj] = {1'b0, window[iii][jjj][PIXEL_DEPTH-1:0]};
        end
    end
endgenerate



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
            sum_R = sum_R + (window_R[i][j] * kernel[i][j]);
            sum_G = sum_G + (window_G[i][j] * kernel[i][j]);
            sum_B = sum_B + (window_B[i][j] * kernel[i][j]);    
        end
    end


    if (valid_out) begin
        if (sum_R > -THRESHOLD && sum_R < 0) begin
            output_R = 8'd0;
        end else if (sum_R > THRESHOLD || sum_R < -THRESHOLD) begin
            output_R = 8'hff;
        end else begin
            output_R = 8'd0;
        end

        if (sum_G > -THRESHOLD && sum_G < 0) begin
            output_G = 8'd0;
        end else if (sum_G > THRESHOLD || sum_G < -THRESHOLD) begin
            output_G = 8'hff;
        end else begin
            output_G = 8'd0;
        end

        if (sum_B > -THRESHOLD && sum_B < 0) begin
            output_B = 8'd0;
        end else if (sum_B > THRESHOLD || sum_B < -THRESHOLD) begin
            output_B = 8'hff;
        end else begin
            output_B = 8'd0;
        end
    end

end
endmodule
