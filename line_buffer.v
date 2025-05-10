// --------------------------------------------------------------------
//
// Major Functions:	3 Line Buffer, for Image Kernels
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Holguer A Becerra :| 17/15/02  :| Initial Revision
// --------------------------------------------------------------------


module line_buffer(
	data,
	EN, 
	clock, 
	row,
	col,
	U_thres,
	V_thres,
	VS,
	HS,
	BLANK_N,
	R,
	G,
	B,

	dataout_x0y0,
	dataout_x1y0,
	dataout_x2y0,
	dataout_x0y1,
	dataout_x1y1,
	dataout_x2y1,
	dataout_x0y2,
	dataout_x1y2,
	dataout_x2y2
);

parameter LINES=3;
parameter WIDTH=617;
parameter PIXEL=LINES*WIDTH;
parameter BUS_SIZE=28;

input clock;
input EN;
input [BUS_SIZE-1:0] data;
input [12:0] row;
input [12:0] col;
input signed [8:0] U_thres;
input signed [8:0] V_thres;

input VS;
input HS;
input BLANK_N;

input [7:0] R;
input [7:0] G;
input [7:0] B;

//output [BUS_SIZE-1:0]average_color;

output [BUS_SIZE-1:0] dataout_x0y0;
output [BUS_SIZE-1:0] dataout_x1y0;
output [BUS_SIZE-1:0] dataout_x2y0;
output [BUS_SIZE-1:0] dataout_x0y1;
output [BUS_SIZE-1:0] dataout_x1y1;
output [BUS_SIZE-1:0] dataout_x2y1;
output [BUS_SIZE-1:0] dataout_x0y2;
output [BUS_SIZE-1:0] dataout_x1y2;
output [BUS_SIZE-1:0] dataout_x2y2;

// 26 bits 26:4 rgb, 3 blank, 2 vs, 1 hs, 0 decision
reg [BUS_SIZE-1:0] fp_delay [0:PIXEL-1];

localparam thres_range = 9'sd5;

wire signed [8:0] U,V;

assign U = data[17:9];
assign V = data[8:0];

// the line buffer
always@(posedge clock)
begin
	if(EN)
		if ((U>(U_thres+thres_range)) || (U<(U_thres-thres_range)) || (V>(V_thres+thres_range)) || (V<(V_thres-thres_range))) begin
			fp_delay[0][BUS_SIZE-1:0] <= {R,G,B,BLANK_N,VS,HS,1'b1};
		end
		else begin
			fp_delay[0][BUS_SIZE-1:0] <= {R,G,B,BLANK_N,VS,HS,1'b0};
		end
	else 
		fp_delay[0][BUS_SIZE-1:0]<=fp_delay[0][BUS_SIZE-1:0];
end

genvar index;
generate

for (index=PIXEL-1; index >= 1; index=index-1)
	begin: delay_generate
			always@(posedge clock)
				begin
					if(EN)
						fp_delay[index][BUS_SIZE-1:0]<=fp_delay[index-1][BUS_SIZE-1:0];
					else 
						fp_delay[index][BUS_SIZE-1:0]<=fp_delay[index][BUS_SIZE-1:0];
				end
	end
endgenerate

// output values
assign dataout_x0y0[BUS_SIZE-1:0]=fp_delay[(PIXEL-1)][BUS_SIZE-1:0];
assign dataout_x1y0[BUS_SIZE-1:0]=fp_delay[(PIXEL-2)][BUS_SIZE-1:0];
assign dataout_x2y0[BUS_SIZE-1:0]=fp_delay[(PIXEL-3)][BUS_SIZE-1:0];
assign dataout_x0y1[BUS_SIZE-1:0]=fp_delay[(PIXEL-WIDTH-1)][BUS_SIZE-1:0];
assign dataout_x1y1[BUS_SIZE-1:0]=fp_delay[(PIXEL-WIDTH-2)][BUS_SIZE-1:0];
assign dataout_x2y1[BUS_SIZE-1:0]=fp_delay[(PIXEL-WIDTH-3)][BUS_SIZE-1:0];
assign dataout_x0y2[BUS_SIZE-1:0]=fp_delay[(PIXEL-(2*WIDTH)-1)][BUS_SIZE-1:0];
assign dataout_x1y2[BUS_SIZE-1:0]=fp_delay[(PIXEL-(2*WIDTH)-2)][BUS_SIZE-1:0];
assign dataout_x2y2[BUS_SIZE-1:0]=fp_delay[(PIXEL-(2*WIDTH)-3)][BUS_SIZE-1:0];

endmodule	