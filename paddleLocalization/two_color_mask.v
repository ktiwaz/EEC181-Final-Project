// Takes in the U & V values of a pixel. The pixel values are compared to 
// two different pairs of (U,V) target values. If the given coordinate is within
// a rounding threshold, that color's output bit is set to 1.

module two_color_mask #(
	parameter YUV_WIDTH = 8,
	parameter THRESH_WIDTH= 10
)(
	input signed [YUV_WIDTH-1:0] U,
	input signed [YUV_WIDTH-1:0] V,
	input in_valid,
	
	input signed [YUV_WIDTH-1:0] uTarget1,
	input signed [YUV_WIDTH-1:0] vTarget1,
	input signed [THRESH_WIDTH-1:0] uThresh1,
	input signed [THRESH_WIDTH-1:0] vThresh1,

	input signed [YUV_WIDTH-1:0] uTarget2,
	input signed [YUV_WIDTH-1:0] vTarget2,
	input signed [THRESH_WIDTH-1:0] uThresh2,
	input signed [THRESH_WIDTH-1:0] vThresh2,
	
	output reg [1:0] colorEncoding,
	output out_valid
);


// Wire Declarations
reg signed [THRESH_WIDTH:0] uThreshLow1, uThreshHigh1, vThreshLow1, vThreshHigh1;
reg signed [THRESH_WIDTH:0] uThreshLow2, uThreshHigh2, vThreshLow2, vThreshHigh2;


// Threshold Assignments

always @(*) begin
	
	uThreshLow1 = uTarget1 - uThresh1;
	uThreshHigh1 = uTarget1 + uThresh1;

	vThreshLow1 = vTarget1 - vThresh1;
	vThreshHigh1 = vTarget1 + vThresh1;

	uThreshLow2 = uTarget2 - uThresh2;
	uThreshHigh2 = uTarget2 + uThresh2;

	vThreshLow2 = vTarget2 - vThresh2;
	vThreshHigh2 = vTarget2 + vThresh2;


	if( (uThreshLow1 <= U) && (U <= uThreshHigh1) && (vThreshLow1 <= V) && (V <= vThreshHigh1)) begin
		colorEncoding[1] = 1'b1;
	end
	else begin
		colorEncoding[1] = 1'b0;
	end

	if( (uThreshLow2 <= U) && (U <= uThreshHigh2) && (vThreshLow2 <= V) && (V <= vThreshHigh2)) begin
		colorEncoding[0] = 1'b1;
	end
	else begin
		colorEncoding[0] = 1'b0;
	end

end

assign out_valid = in_valid;


endmodule