// alu.v - Arithmetic Logic Unit: the math core.
// This is the same circuit as your calculator, pulled out into its own module
// so the CPU can reuse it. Pure logic gates, no memory.

module alu (
    input  wire [2:0] op,
    input  wire [7:0] a,       // accumulator
    input  wire [7:0] b,       // the other number
    output reg  [7:0] result,
    output reg        carry
);

    localparam OP_LOAD = 3'd0;  // result = b
    localparam OP_ADD  = 3'd1;  // result = a + b
    localparam OP_SUB  = 3'd2;  // result = a - b
    localparam OP_AND  = 3'd3;
    localparam OP_OR   = 3'd4;
    localparam OP_XOR  = 3'd5;
    localparam OP_SHL  = 3'd6;  // result = a * 2
    localparam OP_SHR  = 3'd7;  // result = a / 2

    always @(*) begin
        case (op)
            OP_LOAD: {carry, result} = {1'b0, b};
            OP_ADD:  {carry, result} = {1'b0, a} + {1'b0, b};
            OP_SUB:  {carry, result} = {1'b0, a} - {1'b0, b};
            OP_AND:  {carry, result} = {1'b0, a & b};
            OP_OR:   {carry, result} = {1'b0, a | b};
            OP_XOR:  {carry, result} = {1'b0, a ^ b};
            OP_SHL:  {carry, result} = {a, 1'b0};
            OP_SHR:  {carry, result} = {a[0], 1'b0, a[7:1]};
        endcase
    end

endmodule
