

module RNG_tb;

  // Inputs
  reg clk;
  reg rst;
  reg frame;
  reg [9:0] seed_i;

  // Output
  wire [9:0] rand_o;

  // Instantiate the DUT
  RNG uut (
    .clk(clk),
    .rst(rst),
    .frame(frame),
    .seed_i(seed_i),
    .rand_o(rand_o)
  );

initial begin 
	clk = 1'b0;
	forever #10 clk = ~clk;
end

  initial begin
    // Initial values
    rst = 0;
    #20;
    rst = 1;
    seed_i = 10'b1010010101; // seed = 661

    // Apply reset
    #20;
    rst = 0;

    // Let the RNG run for a few cycles
    #20;
    $display("Time\tFrame\tRand_o (dec)\tRand_o (bin)");
    $display("-------------------------------------------");

    // Generate a few random numbers
    repeat (20) begin
      frame = 1;   // pulse frame
      #20;
      frame = 0;
      #800;

      $display("%4t\t%b\t%d\t\t%b", $time, frame, rand_o, rand_o);
    end

    
  end

endmodule
