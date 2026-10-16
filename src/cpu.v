// cpu.v - "Tiny8", an 8-bit CPU built around your calculator's ALU.
//
// The program lives in an external memory chip (like the TI-84's Z80 does):
// the CPU puts an address on mem_addr, the memory answers on mem_data.
//
// Registers (memory cells inside the CPU):
//   A       accumulator, the "display" - every math result lands here
//   R0..R3  four spare registers to keep variables in
//   PC      program counter - address of the next instruction byte
//   C, Z    flags: carry, and "A is zero"
//
// Instruction set. Each instruction is 1 byte: [opcode:4][operand:4].
// Instructions marked # are followed by a second byte (an immediate number or jump address).
//
//   0x  NOP          do nothing
//   1x  LDI  #       A = #
//   2x  ADDI #       A = A + #
//   3x  SUBI #       A = A - #
//   4x  ANDI #       A = A & #
//   5x  ORI  #       A = A | #
//   6x  XORI #       A = A ^ #
//   7x  JC   #       jump to # if C = 1
//   8r  LD   Rr      A = Rr
//   9r  ST   Rr      Rr = A
//   Ar  ADD  Rr      A = A + Rr
//   Br  SUB  Rr      A = A - Rr
//   Cx  JMP  #       jump to #
//   Dx  JZ   #       jump to # if Z = 1
//   Ex  JNZ  #       jump to # if Z = 0
//   F0  OUT          output port = A
//   F1  HALT         stop
//   F2  SHL          A = A * 2
//   F3  SHR          A = A / 2

module cpu (
    input  wire       clk,
    input  wire       rst,
    output wire [7:0] mem_addr,  // address bus: which byte we want
    input  wire [7:0] mem_data,  // data bus: the byte memory gives back
    output reg  [7:0] out_port,  // what the program has OUTput
    output reg        halted
);

    reg  [7:0] pc;
    reg  [7:0] ir;       // instruction register: holds a 2-byte instruction while we fetch byte 2
    reg  [7:0] a;
    reg        carry;
    reg        phase;    // 0 = reading an instruction, 1 = reading its second byte
    reg  [7:0] r [0:3];  // R0..R3

    assign mem_addr = pc;
    wire zero = (a == 8'd0);

    // --- Decoder: figure out what the current instruction means ----------
    wire [7:0] instr   = phase ? ir : mem_data;
    wire [3:0] opcode  = instr[7:4];
    wire [3:0] low     = instr[3:0];
    wire [1:0] rsel    = instr[1:0];
    wire       has_imm = (opcode >= 4'h1 && opcode <= 4'h7) || (opcode >= 4'hC && opcode <= 4'hE);

    // An instruction "executes" on its last byte
    wire execute = phase || !has_imm;

    // Pick the ALU operation (or none) for this instruction
    reg [2:0] alu_op;
    reg       alu_write;
    always @(*) begin
        alu_write = 1'b1;
        alu_op    = 3'd0;
        case (opcode)
            4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6: alu_op = opcode[2:0] - 3'd1;  // LDI..XORI -> LOAD..XOR
            4'h8: alu_op = 3'd0;  // LD  -> LOAD
            4'hA: alu_op = 3'd1;  // ADD
            4'hB: alu_op = 3'd2;  // SUB
            4'hF: begin
                if      (low == 4'h2) alu_op = 3'd6;  // SHL
                else if (low == 4'h3) alu_op = 3'd7;  // SHR
                else                  alu_write = 1'b0;
            end
            default: alu_write = 1'b0;
        endcase
    end

    // The ALU's second number is the immediate byte, or a register
    wire [7:0] operand = phase ? mem_data : r[rsel];
    wire [7:0] alu_result;
    wire       alu_carry;

    alu u_alu (.op(alu_op), .a(a), .b(operand), .result(alu_result), .carry(alu_carry));

    // Should a jump happen? (only meaningful on the second byte of a jump)
    reg take_jump;
    always @(*) begin
        case (opcode)
            4'h7:    take_jump = carry;
            4'hC:    take_jump = 1'b1;
            4'hD:    take_jump = zero;
            4'hE:    take_jump = !zero;
            default: take_jump = 1'b0;
        endcase
    end

    // --- Everything that changes on a clock tick -------------------------
    always @(posedge clk) begin
        if (rst) begin
            pc       <= 8'd0;
            ir       <= 8'd0;
            a        <= 8'd0;
            carry    <= 1'b0;
            phase    <= 1'b0;
            halted   <= 1'b0;
            out_port <= 8'd0;
            r[0] <= 8'd0; r[1] <= 8'd0; r[2] <= 8'd0; r[3] <= 8'd0;
        end else if (!halted) begin
            if (!execute) begin
                // first byte of a 2-byte instruction: remember it, go read the second byte
                ir    <= mem_data;
                phase <= 1'b1;
                pc    <= pc + 8'd1;
            end else begin
                phase <= 1'b0;
                pc    <= (phase && take_jump) ? mem_data : pc + 8'd1;

                if (alu_write) begin
                    a     <= alu_result;
                    carry <= alu_carry;
                end
                if (opcode == 4'h9) r[rsel] <= a;  // ST
                if (instr == 8'hF0) out_port <= a;  // OUT
                if (instr == 8'hF1) begin           // HALT
                    halted <= 1'b1;
                    pc     <= pc;
                end
            end
        end
    end

endmodule
