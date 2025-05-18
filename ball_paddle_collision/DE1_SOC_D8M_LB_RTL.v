//=============================================================================
// This module is the top-level template module for hardware to control a
// camera and VGA video interface.
// 
// 2022/04/09  Written [Ziyuan Dong]
// 2022/04/29  LED, HEX, SW, KEY, VGA added; Cleaned up the code [Ziyuan Dong]
//=============================================================================

module DE1_SOC_D8M_LB_RTL (

   //--- 50 MHz clock from DE1-SoC board
   input          CLOCK_50,

   //--- 10 Switches
   input    [9:0] SW,

   //--- 4 Push buttons
   input    [3:0] KEY,
 
   //--- 10 LEDs
   output   [9:0] LEDR,

   //--- 6 7-segment hexadecimal displays
   output   [7:0] HEX0,                 // seven segment digit 0
   output   [7:0] HEX1,                 // seven segment digit 1
   output   [7:0] HEX2,                 // seven segment digit 2
   output   [7:0] HEX3,                 // seven segment digit 3
   output   [7:0] HEX4,                 // seven segment digit 4
   output   [7:0] HEX5,                 // seven segment digit 5

   //--- GPIO_1, GPIO_1 connect to D8M-GPIO 
   inout          CAMERA_I2C_SCL,
   inout          CAMERA_I2C_SDA,
   output         CAMERA_PWDN_n,
   output         MIPI_CS_n,
   inout          MIPI_I2C_SCL,
   inout          MIPI_I2C_SDA,
   output         MIPI_MCLK,            // unknown use
   input          MIPI_PIXEL_CLK,       // 25 MHz clock from camera
   input   [9:0]  MIPI_PIXEL_D,
   input          MIPI_PIXEL_HS,   
   input          MIPI_PIXEL_VS,
   output         MIPI_REFCLK,          // 20 MHz from video_pll.v
   output         MIPI_RESET_n,
   
   //---  VGA 
   output         VGA_CLK,              // VGA clock
   output reg     VGA_HS,               // VGA H_SYNC
   output reg     VGA_VS,               // VGA V_SYNC
   output         VGA_BLANK_N,          // VGA BLANK
   output         VGA_SYNC_N,           // VGA SYNC
   output reg  [7:0] VGA_R,                // VGA Red[7:0]
   output reg  [7:0] VGA_G,                // VGA Green[7:0]
   output reg  [7:0] VGA_B                 // VGA Blue[7:0]

);

//=============================================================================
// reg and wire declarations
//=============================================================================
   wire    [7:0]  cam_red;
   wire    [7:0]  cam_green;
   wire    [7:0]  cam_blue;
   wire           reset_n; 
   wire   [12:0]  cam_xcont, cam_col; 
   wire   [12:0]  cam_ycont, cam_row; 
   wire           I2C_RELEASE ;  
   wire           CAMERA_I2C_SCL_MIPI; 
   wire           CAMERA_I2C_SCL_AF;
   wire           CAMERA_MIPI_RELAESE;
   wire           MIPI_BRIDGE_RELEASE;
	wire           cam_valid;
   wire           LUT_MIPI_PIXEL_HS;
   wire           LUT_MIPI_PIXEL_VS;
   wire    [9:0]  LUT_MIPI_PIXEL_D;
	wire           clock_25;
   wire    [7:0]  o_red;
   wire    [7:0]  o_green;
   wire    [7:0]  o_blue;
//=======================================================
// Main body of code
//=======================================================

assign  LUT_MIPI_PIXEL_HS = MIPI_PIXEL_HS;
assign  LUT_MIPI_PIXEL_VS = MIPI_PIXEL_VS;
assign  LUT_MIPI_PIXEL_D  = MIPI_PIXEL_D ;

assign reset_n= ~SW[0]; 

assign MIPI_RESET_n   = reset_n;
assign CAMERA_PWDN_n  = reset_n; 
assign MIPI_CS_n      = 1'b0; 


//--- Turn on LED[0] when SW[9] up
assign LEDR[0] = SW[9];

//--- Turn on HEX0[0] when KEY[3] pressed
assign  HEX0[0] = KEY[3];
 
//------ MIPI BRIDGE  I2C SETTING--------------- 
MIPI_BRIDGE_CAMERA_Config u1(
   .RESET_N           ( reset_n ), 
   .CLK_50            ( CLOCK_50), 
   .MIPI_I2C_SCL      ( MIPI_I2C_SCL ), 
   .MIPI_I2C_SDA      ( MIPI_I2C_SDA ), 
   .MIPI_I2C_RELEASE  ( MIPI_BRIDGE_RELEASE ),
   .CAMERA_I2C_SCL    ( CAMERA_I2C_SCL ),
   .CAMERA_I2C_SDA    ( CAMERA_I2C_SDA ),
   .CAMERA_I2C_RELAESE( CAMERA_MIPI_RELAESE )
);
 
//-- Video PLL --- 
video_pll u2(
   .refclk    ( CLOCK_50 ),                    // 50MHz clock 
   .rst       ( 1'b0 ),     
   .outclk_0  ( MIPI_REFCLK )                  // 20MHz clock
);

//-- pll_main25 ---
pll_main25 u3(
   .refclk    ( CLOCK_50 ),                    // 50MHz clock 
   .rst       ( 1'b0 ),     
   .outclk_0  ( clock_25 )                     // 25MHz clock
);

//--- VGA interface signals ---
assign VGA_CLK    = MIPI_PIXEL_CLK;           // GPIO clk
assign VGA_SYNC_N = 1'b0;

// this blanking signal is active low
assign VGA_BLANK_N = VGA_HS & VGA_VS;

//--- D8M RAWDATA to RGB ---

camera_out u4(
   .RESET_SYS_N  ( reset_n ),
   .CLOCK_50     ( CLOCK_50 ),
   .CCD_DATA     ( LUT_MIPI_PIXEL_D [9:0] ),
   .CCD_FVAL     ( LUT_MIPI_PIXEL_VS ),       
   .CCD_LVAL     ( LUT_MIPI_PIXEL_HS ),        
   .CCD_PIXCLK   ( MIPI_PIXEL_CLK ),           // 25MHZ

   .cam_valid    ( cam_valid ),
   .cam_xcont    ( cam_xcont ),
   .cam_ycont    ( cam_ycont ), 
   .cam_row      ( cam_row ),
   .cam_col      ( cam_col ), 
   .cam_red      ( cam_red ),                 // Red Pixel data in RGB format
   .cam_green    ( cam_green ),
   .cam_blue     ( cam_blue )
);


// generate the horizontal and vertical sync signals
always @(*) begin
   if ((cam_xcont >= 13'd02 ) && ( cam_xcont<= 13'd97))
      VGA_HS = 1'b0;
   else
      VGA_HS = 1'b1;

   if ((cam_ycont >= 13'd0012 ) && ( cam_ycont <= 13'd0013))
      VGA_VS = 1'b0;
   else
      VGA_VS = 1'b1;
end


always @(*) begin
	if (cam_valid) begin
		VGA_R = o_R;
		VGA_G = o_G;
		VGA_B = o_B;
	end else begin
		VGA_R = 8'd0;
		VGA_G = 8'd0;
		VGA_B = 8'd0;
	end
end

collisionDemo #(
	.ROWS_D8M(640),
	.COLS_D8M (480),
	.BUTTON_DELAY(160000)
) collisions(
	.SW(SW),
	.KEY(~KEY),

	.clk(CLOCK_50), .reset_n(reset_n), .verticalSync(VGA_VS),
	.row(cam_row), .col(cam_col),

	.o_VGA_R(o_R),
	.o_VGA_G(o_G),
	.o_VGA_B(o_B)
);



endmodule
