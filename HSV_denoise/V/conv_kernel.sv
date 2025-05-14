module conv_kernel #(
    parameter LINE_WIDTH = 640,
    parameter PIXEL_DEPTH = 8
) (

    input clk,
    input vs_ni,
    input hs_ni,
    input blank_ni,
    input color_i,
    input en_i,
    input filter_en,
    input [3:0] threshold_sw,

    input [PIXEL_DEPTH-1:0] input_R,
    input [PIXEL_DEPTH-1:0] input_G,
    input [PIXEL_DEPTH-1:0] input_B,
    output vs_no,
    output hs_no,
    output blank_no,
    output reg [PIXEL_DEPTH-1:0] output_R,
    output reg [PIXEL_DEPTH-1:0] output_G,
    output reg [PIXEL_DEPTH-1:0] output_B
);

localparam SIZE = 3;
localparam KERNEL_WIDTH = 4;
localparam LINE_BUFFER_BUS_SIZE = 3*PIXEL_DEPTH + 4; // Extra bits for vs, hs, blank, color

wire [LINE_BUFFER_BUS_SIZE-1:0] window [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

wire signed[PIXEL_DEPTH:0] window_R [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_G [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels
wire signed[PIXEL_DEPTH:0] window_B [0:SIZE-1][0:SIZE-1]; // Sliding window of pixels

integer i, j;

genvar iii, jjj;

// Manual sign extension
generate
    for(iii = 0; iii < SIZE; iii++) begin : window_x
        for(jjj=0; jjj < SIZE; jjj++) begin : window_y
            assign window_R[iii][jjj] = {1'b0, window[iii][jjj][3*PIXEL_DEPTH-1:2*PIXEL_DEPTH]};
            assign window_G[iii][jjj] = {1'b0, window[iii][jjj][2*PIXEL_DEPTH-1:PIXEL_DEPTH]};
            assign window_B[iii][jjj] = {1'b0, window[iii][jjj][PIXEL_DEPTH-1:0]};
        end
    end
endgenerate

wire in_img [0:2][0:2];
wire out_img;
generate
    for (iii = 0; iii < 3; iii = iii + 1) begin : row_loop
        for (jjj = 0; jjj < 3; jjj = jjj + 1) begin : col_loop
            assign in_img[iii][jjj] = window[iii][jjj][LINE_BUFFER_BUS_SIZE-1];
        end
    end
endgenerate

// Assign VS, HS, blank based on middle of buffer
assign vs_no = window[1][1][LINE_BUFFER_BUS_SIZE-2]; 
assign hs_no = window[1][1][LINE_BUFFER_BUS_SIZE-3]; 
assign blank_no = window[1][1][LINE_BUFFER_BUS_SIZE-4]; 

sliding_window # (
    .NUMBER_OF_LINES(SIZE),
    .WIDTH(LINE_WIDTH),
    .BUS_SIZE(LINE_BUFFER_BUS_SIZE)
  )
  sliding_window_inst (
    .clock(clk),
    .EN(en_i),
    .data({color_i, vs_ni, hs_ni, blank_ni, input_R, input_G, input_B}),
    .dataout(window)
  );

  denoise # (
    .N_SIZE(SIZE),
    .COLORS(1)
  )

  denoise_inst (
    .in_img(in_img),
    .out_img(out_img),
    .n_threshold(threshold_sw)
  );

  always @(*) begin
    if(filter_en) begin
        if(out_img) begin
            output_R = 8'hff;
            output_G = 8'hff;
            output_B = 8'hff;
        end else begin
            output_R = 8'h00;
            output_G = 8'h00;
            output_B = 8'h00;
        end
    end else begin
        output_R = window_R[1][1][7:0];
        output_G = window_G[1][1][7:0];
        output_B = window_B[1][1][7:0];
    end
    
end
endmodule
