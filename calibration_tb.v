module calibration_tb;

    // Testbench signals
    reg [7:0] raw_R, raw_G, raw_B;
    reg clk, reset_n, start;
    reg [12:0] row, col;
    reg [9:0] c2_row, c2_col;
    wire [7:0] Y_out;
    wire signed [8:0] U_out, V_out;
    wire [4:0] Ctr;

    // Instantiate the calibration module
    calibration uut (
        .raw_R(raw_R),
        .raw_G(raw_G),
        .raw_B(raw_B),
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .row(row),
        .col(col),
        .c2_row(c2_row),
        .c2_col(c2_col),
        .Y_out(Y_out),
        .U_out(U_out),
        .V_out(V_out),
        .Ctr(Ctr)
    );

initial begin 
	clk = 1'b0;
	forever #10 clk = ~clk;
end

    // Test procedure
    initial begin
        // Initialize signals
        clk = 0;
        reset_n = 0;
        start = 0;
        raw_R = 8'd0;
        raw_G = 8'd0;
        raw_B = 8'd0;
        row = 13'd0;
        col = 13'd0;
        c2_row = 10'd5;
        c2_col = 10'd5;
		
		
		  #20 reset_n = 0;
        // Apply reset
		  
        #20 reset_n = 1;

        // Start the accumulation process
        #40 start = 1;

        // Test 1: Feed inputs and check accumulation state
        #20 raw_R = 8'd50; 
				raw_G = 8'd150; 
				raw_B = 8'd250;
            row = 13'd6; 
				col = 13'd6; // Within accumulation range
				start = 0;

        #20 raw_R = 8'd40; 
				raw_G = 8'd140; 
				raw_B = 8'd240;
            row = 13'd7; 
				col = 13'd7; // Within accumulation range
				
        #20 raw_R = 8'd40; 
				raw_G = 8'd140; 
				raw_B = 8'd240;
            row = 13'd8; 
				col = 13'd8; // Within accumulation range

        // Test 2: Feed inputs outside accumulation range
        #20 raw_R = 8'd30; 
				raw_G = 8'd130; 
				raw_B = 8'd230;
            row = 13'd9;
				col = 13'd9; // Outside accumulation range

        // Allow some cycles to pass and observe output values
        #20000;
        start = 0;
        // #2000;
        // start = 1;
        // #200;
        // start = 0;
        // #2000;
        // Display accumulated results
        $display("Accumulated R: %d, G: %d, B: %d", uut.R_accum, uut.G_accum, uut.B_accum);
        $display("U_out: %d, V_out: %d, Ctr: %d", U_out, V_out, Ctr);
    end

endmodule
