module box(
	input               clk,
	input               reset,
	
	input               out_img, // from denoiser
	input        [12:0] row,
	input        [12:0] col,
	
	input               V_sync,
	
	output       [12:0]  T, //top
	output       [12:0]  B, //bottom
	output       [12:0]  L, //left
	output       [12:0]  R  //right
);

// 4 corner coordinates registers
// internal register for box position, update every clock cycle
reg [12:0] top,top_c;
reg [12:0] bot,bot_c;
reg [12:0] left,left_c;
reg [12:0] right,right_c;
// external register for box position, update every v sync signal
reg [12:0] To, To_c;
reg [12:0] Bo, Bo_c;
reg [12:0] Lo, Lo_c;
reg [12:0] Ro, Ro_c;

reg first_N,first_N_c; // first color pixel

assign T = To;
assign B = Bo;
assign L = Lo;
assign R = Ro;




always@(posedge clk)begin
	top   <= top_c;
	bot   <= bot_c;
	left  <= left_c;
	right <= right_c;
	first_N <= first_N_c;
	
	To <= To_c;
	Bo <= Bo_c;
	Lo <= Lo_c;
	Ro <= Ro_c;
end

always@(*) begin
	top_c   = top;
	bot_c   = bot;
	left_c  = left;
	right_c = right;
	
	To_c = To;
	Bo_c = Bo;
	Lo_c = Lo;
	Ro_c = Ro;
	
	first_N_c = first_N;
	
	if(out_img)begin // if the pixel is classified as required color.
		first_N_c = 1'b1;  
		
		if(first_N)begin  // is this the first pixels thats certain color? no then compare the coordinate with the box coordinates
			if (row < top) 
				top_c = row;
				
			if (row > bot)
				bot_c = row;
		
			if (col < left)
				left_c = col;
				
			if (col > right)
				right_c = col;
		end
		
		else begin  // if this is the first pixel, record the pixel coordinates as the box coordinates
			top_c = row;
			bot_c = row;
			left_c = col;
			right_c = col;
		end
	end
	
	if	(V_sync) begin // sync per frame, should update the corners captured this cycle, reset the internetal corener register
		top_c   = 12'd10;
		bot_c   = 12'd20;
		left_c  = 12'd10;
		right_c = 12'd20;
		first_N_c = 1'b0;
		
		To_c = top;
		Bo_c = bot;
		Lo_c = left;
		Ro_c = right;		
	end
	
	if (~reset) begin
		To_c = 12'd30;
		Bo_c = 12'd40;
		Lo_c = 12'd30;
		Ro_c = 12'd40;
		
		top_c   = 12'd30;
		bot_c   = 12'd40;
		left_c  = 12'd30;
		right_c = 12'd40;
		first_N_c  = 1'b0;
	end
end

endmodule