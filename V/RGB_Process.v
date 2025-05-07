module RGB_Process(
	input  [7:0] raw_VGA_R,
	input  [7:0] raw_VGA_G,
	input  [7:0] raw_VGA_B,
	
	input  [12:0] row,
	input  [12:0] col,
	input         VGA_VS,
	
	input         clk,
	input         vga_clk,
	input         reset_n,
	
	input  [3:0]  direct,
	input         select,
	input  [5:0]  filter_SW,
	

	input         start_C1,
	input         start_C2,
	output reg [7:0] o_VGA_R,
	
	output reg [7:0] o_VGA_G,
	output reg [7:0] o_VGA_B,
	output [7:0] Y_out,
	
	output signed [8:0] U_out,
	output signed [8:0] V_out,
	output [4:0] Ctr,
	output [1:0] State
);

reg sync, sync_c;
reg state, nextstate;

localparam WAIT = 1'b0;
localparam SYNC = 1'b1;

reg [9:0] c1_row, c1_row_c;
reg [9:0] c1_col, c1_col_c;
reg [9:0] c2_row, c2_row_c;
reg [9:0] c2_col, c2_col_c;

localparam c1_size = 9;
localparam c2_size = 9;
localparam speed = 2;

// Grey Scalem
localparam red_code   = 8'd77;
localparam green_code = 8'd150;
localparam blue_code  = 8'd37;

// U，V
localparam U_code = 8'd126;
localparam V_code = 8'd225;

wire [19:0] Y;
wire signed [19:0] U_long,V_long;
wire signed [8:0] U,V;

assign Y = (((red_code * raw_VGA_R) + (green_code * raw_VGA_G) + (blue_code * raw_VGA_B))>>8);
assign U_long = ((U_code * (raw_VGA_B - Y)) >> 8);
assign V_long = ((V_code * (raw_VGA_R - Y)) >> 8);
assign U = U_long[8:0];
assign V = V_long[8:0];

wire        [1:0] State2;
wire        [3:0] Ctr2;
wire        [7:0] Y2_out;
wire signed [8:0] U2_out;
wire signed [8:0] V2_out;

//instantiation
calibration CB1(
	.raw_R   (raw_VGA_R),
	.raw_G   (raw_VGA_G),
	.raw_B   (raw_VGA_B),
	.clk     (vga_clk),
	.reset_n (reset_n),
	.start   (start_C1),
	.row     (row),
	.col     (col),
	.c2_row  (c1_row),
	.c2_col  (c1_col),
	.rgb_yuv (filter_SW[1]),
	.Y_out   (Y_out),
	.U_out   (U_out),
	.V_out   (V_out),
	.Ctr     (Ctr),
	.State   (State)
);

calibration CB2(
	.raw_R   (raw_VGA_R),
	.raw_G   (raw_VGA_G),
	.raw_B   (raw_VGA_B),
	.clk     (vga_clk),
	.reset_n (reset_n),
	.start   (start_C2),
	.row     (row),
	.col     (col),
	.c2_row  (c2_row),
	.c2_col  (c2_col),
	.rgb_yuv (filter_SW[1]),
	.Y_out   (Y2_out),
	.U_out   (U2_out),
	.V_out   (V2_out),
	.Ctr     (Ctr2),
	.State   (State2)
);


always @(*) begin
	sync_c = sync; 
	nextstate = state;
	
	case (state)
		WAIT: begin
			if (~VGA_VS) begin
				sync_c = 1'b1;
				nextstate = SYNC;
			end
		end
		
		SYNC: begin
			sync_c = 1'b0;
			if (VGA_VS) begin
				nextstate = WAIT;
			end
		end
	endcase
	
	if(~reset_n) begin
		sync_c = 1'b0;
		nextstate = WAIT;
	end
end




always @(*) begin
    c1_row_c = c1_row;
    c1_col_c = c1_col;
    c2_row_c = c2_row;
    c2_col_c = c2_col;
	 

	if(sync) begin
		if (~select)begin //first cursor
            if(~direct[0])begin
                c1_row_c = c1_row - speed;
                if (c1_row < speed) begin
                    c1_row_c = 10'b0;
                end
            end
            else if(~direct[1])begin
                c1_row_c = c1_row + speed;
                if ((c1_row + c1_size + speed) > 13'd477) begin
                    c1_row_c = 10'd477 - c1_size;
                end
            end
            else if(~direct[2])begin
                c1_col_c = c1_col - speed;
                if (c1_col < speed) begin
                    c1_col_c = 10'b0;
                end
            end
            else if(~direct[3])begin
                c1_col_c = c1_col + speed;
                if ((c1_col + c1_size + speed) > 13'd613) begin
                    c1_col_c = 10'd613 - c1_size;
                end 
            end 
            else begin
                c1_row_c = c1_row;
                c1_col_c = c1_col;
            end
        end
        else begin // second cursor
            if(~direct[0])begin
                c2_row_c = c2_row - speed;
                if (c2_row < speed) begin
                    c2_row_c = 10'b0;
                end
            end
            else if(~direct[1])begin
                c2_row_c = c2_row + speed;
                if ((c2_row + c2_size + speed) >= 13'd477) begin
                    c2_row_c = 10'd477 - c2_size;
                end
            end
            else if(~direct[2])begin
                c2_col_c = c2_col - speed;
                if (c2_col < speed) begin
                    c2_col_c = 10'b0;
                end
            end
            else if(~direct[3])begin
                c2_col_c = c2_col + speed;
                if ((c2_col + c2_size + speed) >= 13'd613) begin
                    c2_col_c = 10'd613 - c2_size;
                end
            end
            else begin
                c2_row_c = c2_row;
                c2_col_c = c2_col;
            end
        end
	end

	if(~reset_n) begin
	   c1_row_c = 10'd0;
	   c1_col_c = 10'd630;
	   c2_row_c = 10'd0;
	   c2_col_c = 10'd630;
	end
 end

always @(posedge vga_clk) begin
	sync      <= sync_c;
	state     <= nextstate;
	c1_col    <= c1_col_c;
	c1_row    <= c1_row_c;
	c2_col    <= c2_col_c;
	c2_row    <= c2_row_c;
end

wire [15:0] lum;
assign lum = red_code * raw_VGA_R + green_code * raw_VGA_G + blue_code * raw_VGA_B;

always @(*)begin
		if (row <= 13'd479 && col <= 13'd639) begin
			o_VGA_R = raw_VGA_R;
			o_VGA_B = raw_VGA_B;
			o_VGA_G = raw_VGA_G;
			if (filter_SW[0]) begin  // does filtering
			
				if(~filter_SW[2]) begin   
					if((V>(V_out+9'sd10)) || (V<(V_out-9'sd10)) || (U>(U_out+9'sd10)) || (U<U_out-9'sd10) || (Y>(Y_out+20'sd10)) || (Y<(Y_out-20'sd10))) begin
						o_VGA_R = 8'd255;
						o_VGA_B = 8'd255;
						o_VGA_G = 8'd255;
					end
				end
				
				else begin
					if((V>(V2_out+9'sd10)) || (V<(V2_out-9'sd10))) begin
						o_VGA_R = 8'd255;
						o_VGA_B = 8'd255;
						o_VGA_G = 8'd255;
					end
				end
				
			end
			
			
			
			if  ((((row == c2_row) || ( row == c2_row + c2_size))&&((col >= c2_col) && (col <= c2_col + c2_size))) 
				|| (((col == c2_col) || ( col == c2_col + c2_size))&&((row >= c2_row) && (row <= c2_row + c2_size)))) begin
				o_VGA_R = 8'b00000000;
				o_VGA_G = 8'b00000000;
				o_VGA_B = 8'b11111111;
			end
			// color logic C1
			if (((row >= c1_row) && (row<= (c1_row + c1_size)) && (col >= c1_col) && (col <= c1_col + c1_size))) begin
				o_VGA_R = 8'b000000000;
				o_VGA_G = 8'b111111111;
				o_VGA_B = 8'b000000000;
			end
		end	  
		else begin // Out of range
			o_VGA_R = 8'd0;
			o_VGA_G = 8'd0;
			o_VGA_B = 8'd0;
		end
end

endmodule
