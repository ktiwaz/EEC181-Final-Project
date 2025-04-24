module RGB_Process(
	input  [7:0] raw_VGA_R,
	input  [7:0] raw_VGA_G,
	input  [7:0] raw_VGA_B,
	input  [12:0] row,
	input  [12:0] col,
	input  [5:0]  filter_SW,

	output reg [7:0] o_VGA_R,
	output reg [7:0] o_VGA_G,
	output reg [7:0] o_VGA_B
);

localparam normal = 2'b00;
localparam half   = 2'b01;
localparam quarter = 2'b10;
localparam off     = 2'b11;

always @(*)begin
if (row >= 13'd0 && row <= 13'd479 && col>= 13'd0 && col < 13'd639) begin //bottom right - white
   case(filter_SW[1:0]) // Blue
       normal  : begin
           o_VGA_B = raw_VGA_B;
       end
       half    : begin
           o_VGA_B = raw_VGA_B>>1;
       end
       quarter : begin
           o_VGA_B = raw_VGA_B>>2;
       end
       off     : begin
           o_VGA_B = 8'b0;
       end
   endcase

   case(filter_SW[3:2]) // Green
       normal  : begin
           o_VGA_G = raw_VGA_G;
       end
       half    : begin
           o_VGA_G = raw_VGA_G>>1;
       end
       quarter : begin
           o_VGA_G = raw_VGA_G>>2;
       end
       off     : begin
           o_VGA_G = 8'b0;
       end
   endcase

   case(filter_SW[5:4]) // Red
       normal  : begin
           o_VGA_R = raw_VGA_R;
       end
       half    : begin
           o_VGA_R = raw_VGA_R>>1;
       end
       quarter : begin
           o_VGA_R = raw_VGA_R>>2;
       end
       off     : begin
           o_VGA_R = 8'b0;
       end
   endcase
end
else begin //camera out of the range should always be 0
   o_VGA_R = 8'b00000000;
   o_VGA_G = 8'b00000000;
   o_VGA_B = 8'b00000000;

   end
end

endmodule
