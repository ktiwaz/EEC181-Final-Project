module camera
	(
		////////////////////	Clock Input	 	////////////////////	 
		CLOCK_50,						//	50 MHz
		////////////////////	Push Button		////////////////////
		KEY,							//	Pushbutton[3:0]
		////////////////////	DPDT Switch		////////////////////
		SW,								//	Toggle Switch[17:0]
		////////////////////	7-SEG Dispaly	////////////////////
		HEX0,							//	Seven Segment Digit 0
		HEX1,							//	Seven Segment Digit 1
		HEX2,							//	Seven Segment Digit 2
		HEX3,							//	Seven Segment Digit 3
		////////////////////////	LED		////////////////////////
		LEDR,							//	LED Red[9:0]
		/////////////////////	SDRAM Interface		////////////////
		DRAM_DQ,						//	SDRAM Data bus 16 Bits
		DRAM_ADDR,						//	SDRAM Address bus 12 Bits
		DRAM_LDQM,						//	SDRAM Low-byte Data Mask 
		DRAM_UDQM,						//	SDRAM High-byte Data Mask
		DRAM_WE_N,						//	SDRAM Write Enable
		DRAM_CAS_N,						//	SDRAM Column Address Strobe
		DRAM_RAS_N,						//	SDRAM Row Address Strobe
		DRAM_CS_N,						//	SDRAM Chip Select
		DRAM_BA,						//	SDRAM Bank Address 0
		DRAM_CLK,						//	SDRAM Clock
		DRAM_CKE,						//	SDRAM Clock Enable

		VGA_CLK,                 // VGA clock
   	VGA_HS,                  // VGA H_SYNC
   	VGA_VS,                  // VGA V_SYNC
		VGA_BLANK_N,             // VGA BLANK
		VGA_SYNC_N,              // VGA SYNC
		VGA_R,                   // VGA Red[9:0]
		VGA_G,                   // VGA Green[9:0]
		VGA_B                    // VGA Blue[9:0]
	);

////////////////////////	Clock Input	 	////////////////////////
input		    	CLOCK_50;				//	50 MHz
////////////////////////	Push Button		////////////////////////
input  	[3:0]	KEY;					//	Pushbutton[3:0]
////////////////////////	DPDT Switch		////////////////////////
input	   [9:0]	SW;						//	Toggle Switch[9:0]
////////////////////////	7-SEG Dispaly	////////////////////////
output	[6:0]	HEX0;					//	Seven Segment Digit 0
output	[6:0]	HEX1;					//	Seven Segment Digit 1
output	[6:0]	HEX2;					//	Seven Segment Digit 2
output	[6:0]	HEX3;					//	Seven Segment Digit 3
////////////////////////////	LED		////////////////////////////
output	[9:0]	 LEDR;					//	LED Red[17:0]
///////////////////////		SDRAM Interface	////////////////////////
inout	   [15:0] DRAM_DQ;				//	SDRAM Data bus 16 Bits
output	[11:0] DRAM_ADDR;				//	SDRAM Address bus 12 Bits
output			DRAM_LDQM;				//	SDRAM Low-byte Data Mask 
output			DRAM_UDQM;				//	SDRAM High-byte Data Mask
output			DRAM_WE_N;				//	SDRAM Write Enable
output			DRAM_CAS_N;				//	SDRAM Column Address Strobe
output			DRAM_RAS_N;				//	SDRAM Row Address Strobe
output			DRAM_CS_N;				//	SDRAM Chip Select
output	[1:0]	DRAM_BA;				//	SDRAM Bank Address 0
output			DRAM_CLK;				//	SDRAM Clock
output			DRAM_CKE;				//	SDRAM Clock Enable

output         VGA_CLK;      // VGA clock
output         VGA_HS;       // VGA H_SYNC
output         VGA_VS;       // VGA V_SYNC
output         VGA_BLANK_N;  // VGA BLANK
output         VGA_SYNC_N;   // VGA SYNC
output   [7:0] VGA_R;        // VGA Red[9:0]
output   [7:0] VGA_G;        // VGA Green[9:0]
output   [7:0] VGA_B;        // VGA Blue[9:0]
///////////////////////////////////////////////////////////////////
//=============================================================================
// REG/WIRE declarations
//=============================================================================
wire	[15:0]	Read_DATA1;
wire	[15:0]	Read_DATA2;
wire           VGA_CTRL_CLK;
wire           DLY_RST_0;
wire           DLY_RST_1;
wire           DLY_RST_2;
wire           RD_ENABLE;
wire	[15:0]	WR1_DATA;
wire  [15:0]	WR2_DATA;
wire				WR_ENABLE;
wire	[7:0]		VGA_R;   				//	VGA Red[9:0]
wire	[7:0]		VGA_G;	 				//	VGA Green[9:0]
wire	[7:0]		VGA_B;   				//	VGA Blue[9:0]
wire				sdram_ctrl_clk;
wire  [22:0] 	rWR1_ADDR,rWR2_ADDR;
wire  [22:0] 	rRD1_ADDR,rRD2_ADDR;
reg 	[2:0] 	A;

//=============================================================================
// Structural coding
//=============================================================================

assign VGA_CLK = VGA_CTRL_CLK;

// reset and clock signals
Reset_Delay	u1	(
   .iCLK(CLOCK_50),
	.iRST(KEY[0]),
	.oRST_0(DLY_RST_0),
);
						
pll2_125 u2(
  .refclk(CLOCK_50),   //  refclk.clk
  .outclk_0(sdram_ctrl_clk), // 125MHz
  .outclk_1(DRAM_CLK) // 125MHz
);

pll_25mhz u3(
  .refclk(CLOCK_50),   //  refclk.clk
  .outclk_0(CCD_PIXCLK), // 25MHz
  .outclk_1(VGA_CTRL_CLK) // 25MHz
);


wire [12:0] col;
wire [12:0] row;

wire       clk_vga;
wire       orequest;
wire       reset_n; 

reg  [7:0] red_c;
reg  [7:0] blue_c;
reg  [7:0] green_c;

reg  [7:0] red;
reg  [7:0] green;
reg  [7:0] blue;

reg  [22:0] WR1_addr, WR1_addr_c;
reg  [22:0] WR2_addr, WR2_addr_c;
reg  [22:0] RD1_addr, RD1_addr_c;
reg  [22:0] RD2_addr, RD2_addr_c;

always @(VGA_CTRL_CLK)begin
	if(KEY[0])begin
		red   <= 8'b0;
		green <= 8'b0;
		blue  <= 8'b0;
		WR1_addr <= 23'b0;
		WR2_addr <= 23'b0 + 22'h100000;
		RD1_addr <= 23'b0;
		RD2_addr <= 23'b0 + 22'h100000;
	end
	else begin
		red     <= red_c;
		green   <= green_c;
		blue    <= blue_c;
		WR1_addr <= WR1_addr_c;
		WR2_addr <= WR2_addr_c;
		RD1_addr <= RD1_addr_c;
		RD2_addr <= RD2_addr_c;
	end
end

always @(*) begin
	red_c   = red;
	green_c = green;
	blue_c  = blue;
	WR1_addr_c = WR1_addr + 1;
	WR2_addr_c = WR2_addr + 1;
	RD1_addr_c = WR1_addr;
	RD2_addr_c = WR2_addr;
	if (WR1_addr == 23'd307199) begin
		WR1_addr_c = 23'b0;
	end
	if (WR2_addr == 23'h14B000) begin
		WR2_addr_c = 23'b0 + 22'h100000;
	end	

	
end

assign WR_ENABLE = 1'b1;
assign RD_ENABLE = 1'b1;

assign WR1_DATA = {red,green};
assign WR2_DATA = {blue,8'b0};

Sdram_Control_4Port	u4	(	//	HOST Side						
	.REF_CLK(CLOCK_50),     // Not connected to anything
	.RESET_N(1'b1),
	.CLK(sdram_ctrl_clk),

	//	FIFO Write Side 1
	.WR1_DATA(WR1_DATA),    //16 bits
	.WR1(WR_ENABLE),
	.WR1_ADDR(WR1_addr),
	.WR1_MAX_ADDR(640*480),
	.WR1_LENGTH(256),
	.WR1_LOAD(!DLY_RST_0),
	.WR1_CLK(~CCD_PIXCLK),
	.rWR1_ADDR(rWR1_ADDR),  //current WR1 address

	//	FIFO Write Side 2
	.WR2_DATA(WR2_DATA),    //16 bits
	.WR2(WR_ENABLE),
	.WR2_ADDR(WR2_addr),
	.WR2_MAX_ADDR(22'h100000+640*480),
	.WR2_LENGTH(256),
	.WR2_LOAD(!DLY_RST_0),
	.WR2_CLK(~CCD_PIXCLK),
   .rWR2_ADDR(rWR2_ADDR),  //current WR2 address
	
	//	FIFO Read Side 1
	.RD1_DATA(Read_DATA1), //16 bits
	.RD1(RD_ENABLE), //enable
	.RD1_ADDR(RD1_addr),
	.RD1_MAX_ADDR(640*480),
	.RD1_LENGTH(256),
	.RD1_LOAD(!DLY_RST_0),
	.RD1_CLK(~VGA_CTRL_CLK),
	.rRD1_ADDR(rRD1_ADDR),//current RD1 address
	
	//	FIFO Read Side 2
	.RD2_DATA(Read_DATA2), //16 bits
	.RD2(RD_ENABLE),
	.RD2_ADDR(RD2_addr),
	.RD2_MAX_ADDR(22'h100000+640*480),
	.RD2_LENGTH(256),
	.RD2_LOAD(!DLY_RST_0),
	.RD2_CLK(~VGA_CTRL_CLK),
	.rRD2_ADDR(rRD2_ADDR),//current RD2 address
	
	//	SDRAM Side
	.SA(DRAM_ADDR),
    .BA(DRAM_BA),
	.CS_N(DRAM_CS_N),
	.CKE(DRAM_CKE),
	.RAS_N(DRAM_RAS_N),
	.CAS_N(DRAM_CAS_N),
	.WE_N(DRAM_WE_N),
	.DQ(DRAM_DQ),
	.DQM({DRAM_UDQM,DRAM_LDQM})
);




VGA_controller vga_control ( 
   // Host Side
   .orequest(orequest),
   .ired({2'b00,Read_DATA1[15:8]}),
   .igreen({2'b00,Read_DATA1[7:0]}),
   .iblue({2'b00,Read_DATA2[15:8]}),

   // VGA Side
   .ored(VGA_R),
   .ogreen(VGA_G),
   .oblue(VGA_B),
   .ovga_h_sync(VGA_HS),
   .ovga_v_sync(VGA_VS),
   .ovga_sync(VGA_SYNC_N),
   .ovga_blank(VGA_BLANK_N),
   .col(col),
   .row(row),

   // Control signals
   .clk_vga(VGA_CTRL_CLK),
   .reset_n(DLY_RST_0),
);


endmodule