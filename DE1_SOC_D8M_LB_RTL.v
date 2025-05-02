//=============================================================================
// This module is the top-level template module for hardware to control a
// camera and VGA video interface.
// 
// 2022/03/02  Written [Ziyuan Dong]
// 2022/05/03  Added HEX ports; Added LED, KEY, SW and HEX logic [Ziyuan Dong]
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

   //--- VGA    
   output         VGA_BLANK_N,
   output  [7:0]  VGA_B,
   output         VGA_CLK,              // 25 MHz derived from MIPI_PIXEL_CLK
   output  [7:0]  VGA_G,
   output  reg    VGA_HS,
   output  [7:0]  VGA_R,
   output         VGA_SYNC_N,
   output  reg    VGA_VS,

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
   output         MIPI_RESET_n
);

//=============================================================================
// reg and wire declarations
//=============================================================================
   wire           orequest;
   wire    [7:0]  raw_VGA_R;
   wire    [7:0]  raw_VGA_G;
   wire    [7:0]  raw_VGA_B;
   wire           VGA_CLK_25M;
   wire           RESET_N; 
   wire    [7:0]  sCCD_R;
   wire    [7:0]  sCCD_G;
   wire    [7:0]  sCCD_B; 
   wire   [12:0]  x_count,col; 
   wire   [12:0]  y_count,row; 
   wire           I2C_RELEASE ;  
   wire           CAMERA_I2C_SCL_MIPI; 
   wire           CAMERA_I2C_SCL_AF;
   wire           CAMERA_MIPI_RELAESE;
   wire           MIPI_BRIDGE_RELEASE;
  
   wire           LUT_MIPI_PIXEL_HS;
   wire           LUT_MIPI_PIXEL_VS;
   wire    [9:0]  LUT_MIPI_PIXEL_D;
	
	wire [9:0] rand;
	wire sync;
	
	wire [7:0] Y_out;
	wire [8:0] U_out;
	wire [8:0] V_out;
	wire [4:0] Ctr;

//=======================================================
// Main body of code
//=======================================================

assign  LUT_MIPI_PIXEL_HS = MIPI_PIXEL_HS;
assign  LUT_MIPI_PIXEL_VS = MIPI_PIXEL_VS;
assign  LUT_MIPI_PIXEL_D  = MIPI_PIXEL_D ;

assign RESET_N= ~SW[0]; 

assign MIPI_RESET_n   = RESET_N;
assign CAMERA_PWDN_n  = RESET_N; 
assign MIPI_CS_n      = 1'b0; 


//------ MIPI BRIDGE  I2C SETTING--------------- 
MIPI_BRIDGE_CAMERA_Config cfin(
   .RESET_N           ( RESET_N ), 
   .CLK_50            ( CLOCK_50), 
   .MIPI_I2C_SCL      ( MIPI_I2C_SCL ), 
   .MIPI_I2C_SDA      ( MIPI_I2C_SDA ), 
   .MIPI_I2C_RELEASE  ( MIPI_BRIDGE_RELEASE ),
   .CAMERA_I2C_SCL    ( CAMERA_I2C_SCL ),
   .CAMERA_I2C_SDA    ( CAMERA_I2C_SDA ),
   .CAMERA_I2C_RELAESE( CAMERA_MIPI_RELAESE )
);
 
//-- Video PLL --- 
video_pll MIPI_clk(
   .refclk   ( CLOCK_50 ),                    // 50MHz clock 
   .rst      ( 1'b0 ),     
   .outclk_0 ( MIPI_REFCLK )                  // 20MHz clock
);

//--- D8M RAWDATA to RGB ---
D8M_SET   ccd (
   .RESET_SYS_N  ( RESET_N ),
   .CLOCK_50     ( CLOCK_50 ),
   .CCD_DATA     ( LUT_MIPI_PIXEL_D [9:0]),
   .CCD_FVAL     ( LUT_MIPI_PIXEL_VS ),       // 60HZ
   .CCD_LVAL     ( LUT_MIPI_PIXEL_HS ),        
   .CCD_PIXCLK   ( MIPI_PIXEL_CLK),           // 25MHZ from camera
   .READ_EN      (orequest),
   .VGA_HS       ( VGA_HS ),
   .VGA_VS       ( VGA_VS ),
   .X_Cont       ( x_count),
   .Y_Cont       ( y_count), 
   .sCCD_R       ( raw_VGA_R ),
   .sCCD_G       ( raw_VGA_G ),
   .sCCD_B       ( raw_VGA_B )
);

wire BLANK_N;
reg VS;
reg HS;

//--- Processes the raw RGB pixel data
RGB_Process p1 (
   .raw_VGA_R (raw_VGA_R),
   .raw_VGA_G (raw_VGA_G),
   .raw_VGA_B (raw_VGA_B),
	.select (SW[1]),
	.direct   (KEY[3:0]),
	.clk   (CLOCK_50),
	.vga_clk (VGA_CLK),
	.VGA_VS    (VGA_VS),
   .row       (row),
   .col       (col),
	.reset_n   (RESET_N),
	.filter_SW (SW[7:2]),
	.grey      (SW[8]),
   .o_VGA_R   (VGA_R),
   .o_VGA_G   (VGA_G),
   .o_VGA_B   (VGA_B),
	.Y_out     (Y_out),
	.U_out     (U_out),
	.V_out     (V_out),
	.start     (SW[9]),
	.Ctr       (Ctr)
);

assign LEDR[4:0] = Ctr;
assign LEDR[8] = U_out[8];
assign LEDR[9] = V_out[8];

wire [7:0] HEX_0, HEX_1, HEX_2, HEX_3, HEX_4, HEX_5;

assign HEX0 = HEX_0[6:0];
assign HEX1 = HEX_1[6:0];
assign HEX2 = HEX_2[6:0];
assign HEX3 = HEX_3[6:0];
assign HEX4 = HEX_4[6:0];
assign HEX5 = HEX_5[6:0];

Hex27Seg H0(
	.HEX(HEX_0),
	.num(Y_out[3:0])
);
Hex27Seg H1(
	.HEX(HEX_1),
	.num(Y_out[7:4])
);

Hex27Seg H2(
	.HEX(HEX_2),
	.num(U_out[3:0])
);
Hex27Seg H3(
	.HEX(HEX_3),
	.num(U_out[7:4])
);

Hex27Seg H4(
	.HEX(HEX_4),
	.num(V_out[3:0])
);
Hex27Seg H5(
	.HEX(HEX_5),
	.num(V_out[7:4])
);

//--- VGA interface signals ---
assign VGA_CLK    = MIPI_PIXEL_CLK;           // GPIO clk
assign VGA_SYNC_N = 1'b0;

// orequest signals when an output from the camera is needed
assign orequest = ((x_count > 13'd0160 && x_count < 13'd0800 ) &&
                  ( y_count > 13'd0045 && y_count < 13'd0525));

// this blanking signal is active low
assign VGA_BLANK_N = ~((x_count < 13'd0160 ) || ( y_count < 13'd0045 ));

// generate the horizontal and vertical sync signals
always @(*) begin
   if ((x_count >= 13'd0002 ) && ( x_count <= 13'd0097))
      VGA_HS = 1'b0;
   else
      VGA_HS = 1'b1;
   if ((y_count >= 13'd0013 ) && ( y_count <= 13'd0014))
      VGA_VS = 1'b0;
   else
      VGA_VS = 1'b1;
end

// calculate col and row as an offset from the x and y counter values
assign col = x_count - 13'd0164;
assign row = y_count - 13'd0047;

endmodule
