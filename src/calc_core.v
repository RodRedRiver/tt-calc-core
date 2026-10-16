// calc_core.v - a tiny 8-bit calculator core
//
// Think of "acc" (the accumulator) as the calculator's display.
// Every clock tick, if "go" is 1, we do:   acc = acc <op> b
//
// This is NOT a program that runs line by line. Every line here describes
// real hardware (wires and gates) that all exist at the same time.

module calc_core (
    input  wire       clk,    // clock: the heartbeat, everything updates on its rising edge
    input  wire       rst,    // reset: 1 = clear the display to 0
    input  wire       go,     // 1 = do the operation this tick
    input  wire [2:0] op,     // which operation (3 bits = 8 choices)
    input  wire [7:0] b,      // the number you "type in" (0..255)
    output reg  [7:0] acc,    // the result / display
    output reg        carry,  // 1 if the last add overflowed past 255 (or a subtract went below 0)
    output wire       zero    // 1 if the display shows 0
);

    // Operation codes (like the buttons on a calculator)
    localparam OP_LOAD = 3'd0;  // acc = b
    localparam OP_ADD  = 3'd1;  // acc = acc + b
    localparam OP_SUB  = 3'd2;  // acc = acc - b
    localparam OP_AND  = 3'd3;  // acc = acc AND b   (bit by bit)
    localparam OP_OR   = 3'd4;  // acc = acc OR  b
    localparam OP_XOR  = 3'd5;  // acc = acc XOR b
    localparam OP_SHL  = 3'd6;  // acc = acc * 2     (shift bits left)
    localparam OP_SHR  = 3'd7;  // acc = acc / 2     (shift bits right)

    // --- The ALU: pure logic gates, no memory ---------------------------
    // "always @(*)" means: this is combinational logic, the output changes
    // instantly whenever any input changes.
    reg [8:0] result;  // 9 bits: 8 for the answer + 1 extra for the carry

    always @(*) begin
        case (op)
            OP_LOAD: result = {1'b0, b};
            OP_ADD:  result = {1'b0, acc} + {1'b0, b};
            OP_SUB:  result = {1'b0, acc} - {1'b0, b};
            OP_AND:  result = {1'b0, acc & b};
            OP_OR:   result = {1'b0, acc | b};
            OP_XOR:  result = {1'b0, acc ^ b};
            OP_SHL:  result = {acc, 1'b0};             // top bit falls into carry
            OP_SHR:  result = {acc[0], 1'b0, acc[7:1]}; // bottom bit falls into carry
        endcase
    end

    // --- The register: flip-flops that REMEMBER the value ---------------
    // "always @(posedge clk)" means: only update on the rising clock edge.
    // These become 9 flip-flops on the chip (8 for acc, 1 for carry).
    always @(posedge clk) begin
        if (rst) begin
            acc   <= 8'd0;
            carry <= 1'b0;
        end else if (go) begin
            acc   <= result[7:0];
            carry <= result[8];
        end
    end

    assign zero = (acc == 8'd0);

endmodule
