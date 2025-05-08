module fixed_point_divider #(
    parameter NUM_WIDTH = 17,  // 9 integer + 8 fraction
    parameter DEN_WIDTH = 9,
    parameter OUT_WIDTH = 17  
)(
    input clk,
    input start,
    input reset,
    input signed [NUM_WIDTH-1:0] numerator,
    input signed [DEN_WIDTH-1:0] denominator,
    output reg signed [OUT_WIDTH-1:0] quotient,
    output reg done
);

    // State Machine
    localparam IDLE   = 2'd0;
    localparam PREP   = 2'd1;
    localparam DIVIDE = 2'd2;
    localparam FINISH = 2'd3;

    reg [1:0] state = IDLE;

    reg [NUM_WIDTH-1:0] abs_num;
    reg [DEN_WIDTH-1:0] abs_den;
    reg [NUM_WIDTH*2-1:0] dividend;
    reg [DEN_WIDTH-1:0] divisor;
    reg [OUT_WIDTH-1:0] quotient_temp;
    reg [5:0] count;

    reg result_sign;

    reg [NUM_WIDTH*2-1:0] dividend_next;
    reg [OUT_WIDTH-1:0] quotient_temp_next;

    // Next-state logic block
    always @(*) begin
        // Default shift values
        dividend_next = dividend << 1;
        quotient_temp_next = quotient_temp << 1;
    
        // Conditionally override if subtraction succeeds
        if (dividend_next[NUM_WIDTH*2-1:NUM_WIDTH] >= divisor) begin
            dividend_next[NUM_WIDTH*2-1:NUM_WIDTH] =
                dividend_next[NUM_WIDTH*2-1:NUM_WIDTH] - divisor;
            quotient_temp_next[0] = 1'b1; // only set bit 0, not entire word
        end
    end
    
    always @(posedge clk) begin
        quotient <= quotient;
        quotient_temp <= quotient_temp;
        abs_num <= abs_num;
        abs_den <= abs_den;
        dividend <= dividend;
        divisor <= divisor;

        if (reset) begin
            quotient <= 0;
            quotient_temp <= 0;
            abs_num <= 0;
            abs_den <= 0;
            dividend <= 0;
            divisor <= 0;

        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        if (denominator == 0) begin
                            quotient <= 0;
                            done <= 1;
                            state <= IDLE;
                        end else begin
                            state <= PREP;
                        end                    
                    end
                end

                PREP: begin
                    abs_num <= numerator[NUM_WIDTH-1] ? -numerator : numerator;
                    abs_den <= denominator[DEN_WIDTH-1] ? -denominator : denominator;
                    result_sign <= numerator[NUM_WIDTH-1] ^ denominator[DEN_WIDTH-1];
                    dividend <= 0;
                    dividend <= {{(NUM_WIDTH){1'b0}}, numerator[NUM_WIDTH-1] ? -numerator : numerator}; 
                    divisor <= denominator[DEN_WIDTH-1] ? -denominator : denominator;
                    quotient_temp <= 0;
                    count <= OUT_WIDTH;
                    state <= DIVIDE;
                end

                DIVIDE: begin
                    dividend <= dividend_next;
                    quotient_temp <= quotient_temp_next;

                    count <= count - 1;
                    if (count == 1)
                        state <= FINISH;
                end

                FINISH: begin
                    quotient <= result_sign ? -quotient_temp : quotient_temp;
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
