module conv_kernel_1channel #(
    parameter SIZE = 3,         // Should be odd (I think)
    parameter LINE_WIDTH = 640,
    parameter PIXEL_DEPTH = 8,   // pixels on the input
    parameter O_PIXEL_DEPTH = 12,   // pixels on the input
    parameter KERNEL_WIDTH = 8   // width of the kernel values
) (

    input clk,
    input valid_i,

    input [PIXEL_DEPTH-1:0] inputG,

    input signed [KERNEL_WIDTH-1:0] kernel [0:SIZE-1] [0:SIZE-1],  // NxN convolutional kernel
    output valid_o,
    output reg [O_PIXEL_DEPTH-1:0] outputG
);

localparam LINE_BUFFER_BUS_SIZE = PIXEL_DEPTH + 1; // Extra bit for valid``
localparam SUM_WIDTH = KERNEL_WIDTH + PIXEL_DEPTH + $clog2(SIZE*SIZE);
localparam THRESHOLD = 50;

wire [LINE_BUFFER_BUS_SIZE-1:0] window [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire signed[PIXEL_DEPTH:0] windowG [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

integer i, j;

genvar iii, jjj;

// Manual sign extension
generate
    for(iii = 0; iii < SIZE; iii++) begin
        for(jjj=0; jjj < SIZE; jjj++) begin
            assign windowG[iii][jjj] = {1'b0, window[iii][jjj][PIXEL_DEPTH-1:0]};
        end
    end
endgenerate



reg signed [SUM_WIDTH-1:0] sumG;

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
    .data({valid_i, inputG}),
    .dataout(windowG)
  );

  always @(*) begin
    // Initialize sums to 0 for each color channel
    sumG = 0;
    outputG = 0;
    
    // Apply the kernel to the window
    for (i = 0; i < SIZE; i = i + 1) begin
        for (j = 0; j < SIZE; j = j + 1) begin
            // Apply kernel for red channel
            sumG = sumG + (windowG[i][j] * kernel[i][j]); 
        end
    end


    if (valid_out) begin
        if (sumG > -THRESHOLD && sumG < 0) begin
            outputG = 12'd0;
        end else if (sumG > THRESHOLD || sumG < -THRESHOLD) begin
            outputG = 12'hfff;
        end else begin
            outputG = sumG;
        end
    end

end
endmodule
