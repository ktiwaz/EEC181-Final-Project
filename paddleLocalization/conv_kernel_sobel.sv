module conv_kernel_sobel #(
    parameter SIZE = 3,         // Should be odd (I think)
    parameter LINE_WIDTH = 640,
    parameter PIXEL_DEPTH = 8,
    parameter KERNEL_WIDTH = 8
) (

    input clk,
    input valid_i,

    input [PIXEL_DEPTH-1:0] inputLUM,

    input signed [KERNEL_WIDTH-1:0] kernel [0:SIZE-1] [0:SIZE-1],  // NxN convolutional kernel
    
    output valid_o,
    output reg [PIXEL_DEPTH-1:0] outputEdge
);

localparam LINE_BUFFER_BUS_SIZE = PIXEL_DEPTH + 1; // Extra bit for valid``
localparam SUM_WIDTH = KERNEL_WIDTH + PIXEL_DEPTH + $clog2(SIZE*SIZE);
localparam THRESHOLD = 2500; // likely need to adjust

wire [LINE_BUFFER_BUS_SIZE-1:0] window [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire signed[PIXEL_DEPTH:0] windowY [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

integer i, j;

genvar iii, jjj;

// Manual sign extension
generate
    for(iii = 0; iii < SIZE; iii++) begin
        for(jjj=0; jjj < SIZE; jjj++) begin
            assign windowY[iii][jjj] = {1'b0, window[iii][jjj][PIXEL_DEPTH-1:0]};
        end
    end
endgenerate


reg signed [SUM_WIDTH-1:0] sum_X, sum_Y, output_X, output_Y;
reg signed [2*SUM_WIDTH-1:0] xSquared, ySquared;
reg signed [2*SUM_WIDTH:0] magSquared;

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
    .data({valid_i, inputLUM}),
    .dataout(window)
  );

  always @(*) begin
    // Initialize sums to 0 for each color channel
    sum_X = 0;
    sum_Y = 0;
    output_X = 0;
    output_Y = 0;
    
    // Apply the kernel to the window
    for (i = 0; i < SIZE; i = i + 1) begin
        for (j = 0; j < SIZE; j = j + 1) begin
            // Apply kernel for red channel
            sum_X = sum_X + (windowY[i][j] * kernel[i][j]);
            sum_Y = sum_Y + (windowY[i][j] * kernel[j][i]);
        end
    end


    if (valid_out) begin

        xSquared = (sum_X * sum_X);  // might need to instantiate some built in multipliers to get this to work
        ySquared = (sum_Y * sum_Y);
        magSquared = xSquared + ySquared;

        if (magSquared > -THRESHOLD && magSquared < 0) begin
            outputEdge = 8'd0;
        end else if (magSquared > THRESHOLD || magSquared < -THRESHOLD) begin
            outputEdge = 8'hff;
        end else begin
            outputEdge = 8'd0;
        end
    end

end
endmodule
