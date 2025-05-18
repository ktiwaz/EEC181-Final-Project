module RGB_Process(
	input  [7:0] raw_VGA_R,
	input  [7:0] raw_VGA_G,
	input  [7:0] raw_VGA_B,
	input  [12:0] row,
	input  [12:0] col,

	output reg [7:0] o_VGA_R,
	output reg [7:0] o_VGA_G,
	output reg [7:0] o_VGA_B
);

always @(*)begin
if (row >= 13'd0 && row < 13'd5 && col>=13'd0 && col < 13'd5) begin ///up left - red 
	o_VGA_R = 8'b11111111;
	o_VGA_G = 8'b00000000;
	o_VGA_B = 8'b00000000;
end

else if (row >= 13'd0 && row < 13'd5 && col>=13'd621 && col < 13'd625) begin //up right - Green 
	o_VGA_R = 8'b00000000;
	o_VGA_G = 8'b11111111;
	o_VGA_B = 8'b00000000;

end

else if (row >= 13'd474 && row < 13'd478 && col>=13'd0 && col < 13'd5) begin //bottom left - Blue
	o_VGA_R = 8'b00000000;
	o_VGA_G = 8'b00000000;
	o_VGA_B = 8'b11111111;

end

else if (row < 13'd478 && col < 13'd625) begin //bottom right - white
	o_VGA_R = raw_VGA_R;
	o_VGA_G = raw_VGA_G;
	o_VGA_B = raw_VGA_B;
end
else begin //camera out of the range should always be 0
	o_VGA_R = 8'b000000000;
	o_VGA_G = 8'b000000000;
	o_VGA_B = 8'b000000000;

	end
end

endmodule
