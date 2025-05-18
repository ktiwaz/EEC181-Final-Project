module camera_out (
   input       CLOCK_50,	
	input       RESET_SYS_N ,	
	output	   SCLK ,
	inout 	   SDATA,
	
	input [9:0] CCD_DATA  ,
	input       CCD_FVAL  ,//frame valid
	input	      CCD_LVAL	 ,
	input	      CCD_PIXCLK,

	output  [7:0]  cam_red,
	output  [7:0]  cam_green,
	output  [7:0]  cam_blue,
	output	   	sCCD_DVAL,
	output  [12:0] READ_Cont,
   output  [12:0] cam_xcont,	
   output  [12:0] cam_ycont,
   output  [12:0] cam_row,	
   output  [12:0] cam_col,
   output         cam_valid,
   output  [12:0] X_WR_CNT	
 );

 
//=============================================================================
// REG/WIRE declarations
//=============================================================================
wire[9:0]  mCCD_DATA;
reg       HS;
//-------CCD CA--- 
D8M_WRITE_COUNTER u3	(	
	.iCLK       ( CCD_PIXCLK ),
	.iRST       ( RESET_SYS_N ),
	.iFVAL      ( CCD_FVAL ),
	.iLVAL      ( CCD_LVAL ),
	.X_Cont     ( cam_xcont ),
	.Y_Cont     ( cam_ycont ),
	.X_WR_CNT   (X_WR_CNT)
			
);
						
//--READ Counter --- 	
READ_COUNTER   cnt(
	.CLK   ( CCD_PIXCLK),
	.CLR_n ( HS ),
	.EN    ( 1'b1),
	.CNT   ( READ_Cont)
);

//--RAW TO RGB --- 							
RAW2RGB_L				u4	(	
	.RST          ( RESET_SYS_N ),
	.CCD_PIXCLK   ( CCD_PIXCLK ),
	.CCD_DATA     ( CCD_DATA ),
	.CCD_FVAL     ( CCD_FVAL ),
	.CCD_LVAL     ( CCD_LVAL ),
	.X_Cont       ( X_WR_CNT ),
	.Y_Cont       ( cam_ycont ),
	//-----------------------------------
	.READ_EN      ( 1'b1),
	.READ_Cont    ( READ_Cont) , 
	.V_Cont       ( cam_ycont ), 
				
	.oRed         ( cam_red),
	.oGreen       ( cam_green),
	.oBlue        ( cam_blue),
	.oDVAL        ( sCCD_DVAL)
);


assign cam_col = cam_xcont - 13'd0160;
assign cam_row = cam_ycont - 13'd0045;

assign cam_valid = ((cam_xcont > 13'd0160 && cam_xcont < 13'd0800 ) &&
                   ( cam_ycont > 13'd0045 && cam_ycont < 13'd0525));

always @(*) begin
	if ((cam_xcont >= 13'd0002) && (cam_xcont <= 13'd0097))
		HS = 1'b0;
	else
		HS = 1'b1;
end
						 
						 
endmodule
