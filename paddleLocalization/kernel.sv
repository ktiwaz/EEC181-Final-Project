module kernelLoad #(
	parameter SIZE = 3,         // Should be odd (I think)
    parameter KERNEL_WIDTH = 8   
)(
	output signed [KERNEL_WIDTH-1:0] kernel [0:SIZE-1] [0:SIZE-1]  // NxN convolutional kernel
);

// can write the kernel(s) manually in here for now

// a mif would be more flexible/high tech

assign kernel[0][0] = -1;
assign kernel[0][1] = -2;
assign kernel[0][2] = -1;
assign kernel[1][0] = 0;
assign kernel[1][1] = 0;
assign kernel[1][2] = 0;
assign kernel[2][0] = 1;
assign kernel[2][1] = 2;
assign kernel[2][2] = 1;


endmodule