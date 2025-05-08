`timescale 1ns/1ps

module tb_fixed_point_divider;

    parameter NUM_WIDTH = 17;
    parameter DEN_WIDTH = 9;
    parameter OUT_WIDTH = 17;

    reg clk;
    reg reset;
    reg start;
    reg signed [NUM_WIDTH-1:0] numerator;
    reg signed [DEN_WIDTH-1:0] denominator;
    wire signed [OUT_WIDTH-1:0] quotient;
    wire done;

    // Instantiate the DUT
    fixed_point_divider #(
        .NUM_WIDTH(NUM_WIDTH),
        .DEN_WIDTH(DEN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .numerator(numerator),
        .denominator(denominator),
        .quotient(quotient),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    task run_test;
        input signed [NUM_WIDTH-1:0] num;
        input signed [DEN_WIDTH-1:0] den;
        begin
            // Wait for IDLE
            @(posedge clk);
            numerator <= num;
            denominator <= den;
            start <= 1;
            @(posedge clk);
            start <= 0;

            wait (done);
            @(posedge clk);

            $display("-------------------------------------------------");
            $display("Numerator   = %0d (0x%0h), as float = %f", num, num, $itor(num) / 256.0);
            $display("Denominator = %0d (0x%0h)", den, den);  // just signed integer
            $display("Quotient    = %0d (0x%0h), as float = %f", quotient, quotient, $itor(quotient) / 256.0);
        end
    endtask



    // Stimulus
    initial begin
        $dumpfile("divider_q98.vcd");
        $dumpvars(0, tb_fixed_point_divider);

        clk = 0;
        reset = 1;
        start = 0;
        numerator = 0;
        denominator = 0;

        #20 reset = 0;

        // Q9.8 fixed-point values (multiply real values by 256)
        // run_test(17'sd5120, 9'sd10);   // 20.0 / 10 => 2.0
        // run_test(-17'sd7680, 9'sd10);  // -30.0 / 10 => -3.0
        // run_test(17'sd3840, -9'sd8);   // 15.0 / -8 => -1.875
        // run_test(-17'sd1024, -9'sd2);  // -4.0 / -2 => 2.0
        // run_test(17'sd2048, 9'sd0);    // 8.0 / 0 => divide by zero

        run_test(17'sd65280, 9'sd7);    // 255 / 7 ≈ 36.42857
        run_test(17'sd38400, 9'sd7);    // 150 / 7 ≈ 21.42857
        run_test(17'sd25600, 9'sd3);    // 100 / 3 ≈ 33.33333
        run_test(17'sd8448,  9'sd4);    // 33 / 4 ≈ 8.25
        run_test(17'sd1280,  9'sd2);    // 5 / 2 = 2.5
        run_test(-17'sd38400, 9'sd7);   // -150 / 7 ≈ -21.42857


        $display("All tests completed.");
        #20 $finish;
    end

endmodule
