// --------------------------------------------------------------------
// Copyright (c) 2007 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	VGA_Controller
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny FAN        :| 07/07/09  :| Initial Revision
// --------------------------------------------------------------------

module	VGA_controller(	//	Host Side
						ired,
						igreen,
						iblue,
						orequest,
						//	VGA Side
						ored,
						ogreen,
						oblue,
						ovga_h_sync,
						ovga_v_sync,
						ovga_sync,
						ovga_blank,
						col,
						row,
						//	Control Signal
						clk_vga,
						reset_n
						);

`include "VGA_Param.h"

//	Host Side
input		[9:0]	ired;
input		[9:0]	igreen;
input		[9:0]	iblue;
output	reg			orequest;
//	VGA Side
output	reg	[9:0]	ored;
output	reg	[9:0]	ogreen;
output	reg	[9:0]	oblue;
output	reg			ovga_h_sync;
output	reg			ovga_v_sync;
output	reg			ovga_sync;
output	reg			ovga_blank;
output  reg		[12:0]		col;
output  reg		[12:0]		row;

reg		[12:0]		h_cont;
reg		[12:0]		V_Cont;


wire		[9:0]	mvga_r;
wire		[9:0]	mVGA_G;
wire		[9:0]	mVGA_B;
reg					mVGA_H_SYNC;
reg					mVGA_V_SYNC;
wire				mVGA_SYNC;
wire				mVGA_BLANK;
wire     [12:0]	Hcont_w;
wire		[12:0]	Vcont_w;
//	Control Signal
input				clk_vga;
input				reset_n;
//input 				iZOOM_MODE_SW;


wire	[12:0]		v_mask;

assign v_mask = 13'd0;

////////////////////////////////////////////////////////
assign   Hcont_w    = h_cont;
assign   Vcont_w    = V_Cont;

assign	mVGA_BLANK	=	mVGA_H_SYNC & mVGA_V_SYNC;
assign	mVGA_SYNC	=	1'b0;

assign	mvga_r	=	(	h_cont>=X_START 	&& h_cont<X_START+H_SYNC_ACT &&
						V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
						?	ired	:	0;
assign	mVGA_G	=	(	h_cont>=X_START 	&& h_cont<X_START+H_SYNC_ACT &&
						V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
						?	igreen	:	0;
assign	mVGA_B	=	(	h_cont>=X_START 	&& h_cont<X_START+H_SYNC_ACT &&
						V_Cont>=Y_START+v_mask 	&& V_Cont<Y_START+V_SYNC_ACT )
						?	iblue	:	0;

always@(posedge clk_vga)
	begin
		col <= Hcont_w -141;
		row <= Vcont_w -35;
	end

	
always@(posedge clk_vga or negedge reset_n)
	begin
		if (!reset_n)
			begin
				ored <= 0;
				ogreen <= 0;
                oblue <= 0;
				ovga_blank <= 0;
				ovga_sync <= 0;
				ovga_h_sync <= 0;
				ovga_v_sync <= 0; 
			end
		else
			begin
				ored <= mvga_r;
				ogreen <= mVGA_G;
            oblue <= mVGA_B;
				ovga_blank <= mVGA_BLANK;
				ovga_sync <= mVGA_SYNC;
				ovga_h_sync <= mVGA_H_SYNC;
				ovga_v_sync <= mVGA_V_SYNC;				
			end               
	end



//	Pixel LUT Address Generator
always@(posedge clk_vga or negedge reset_n)
begin
	if(!reset_n)
	orequest	<=	0;
	else
	begin
		if(	h_cont>=X_START-2 && h_cont<X_START+H_SYNC_ACT-2 &&
			V_Cont>=Y_START && V_Cont<Y_START+V_SYNC_ACT )
		orequest	<=	1;
		else
		orequest	<=	0;
	end
end

//	H_Sync Generator, Ref. 25.175 MHz Clock
always@(posedge clk_vga or negedge reset_n)
begin
	if(!reset_n)
	begin
		h_cont		<=	0;
		mVGA_H_SYNC	<=	0;
	end
	else
	begin
		//	H_Sync Counter
		if( h_cont < H_SYNC_TOTAL )
		h_cont	<=	h_cont+1;
		else
		h_cont	<=	0;
		//	H_Sync Generator
		if( h_cont < H_SYNC_CYC )
		mVGA_H_SYNC	<=	0;
		else
		mVGA_H_SYNC	<=	1;
	end
end

//	V_Sync Generator, Ref. H_Sync
always@(posedge clk_vga or negedge reset_n)
begin
	if(!reset_n)
	begin
		V_Cont		<=	0;
		mVGA_V_SYNC	<=	0;
	end
	else
	begin
		//	When H_Sync Re-start
		if(h_cont==0)
		begin
			//	V_Sync Counter
			if( V_Cont < V_SYNC_TOTAL )
			V_Cont	<=	V_Cont+1;
			else
			V_Cont	<=	0;
			//	V_Sync Generator
			if(	V_Cont < V_SYNC_CYC )
			mVGA_V_SYNC	<=	0;
			else
			mVGA_V_SYNC	<=	1;
		end
	end
end

endmodule