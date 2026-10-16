## How it works

Tiny8 is an 8-bit CPU. Like the Z80 in a TI-84, it reads its program from an external memory:
it puts an address on `A[7:0]` (uo_out) and expects the program byte at that address on `D[7:0]` (ui_in).
The `OUT` instruction copies the accumulator to the output port `OUT[7:0]` (uio).

Registers: accumulator `A`, four general registers `R0`-`R3`, an 8-bit program counter, and carry/zero flags.

| Byte | Instruction | Effect               |
|------|-------------|----------------------|
| 00   | NOP         |                      |
| 10 # | LDI #       | A = #                |
| 20 # | ADDI #      | A = A + #            |
| 30 # | SUBI #      | A = A - #            |
| 40 # | ANDI #      | A = A & #            |
| 50 # | ORI #       | A = A \| #           |
| 60 # | XORI #      | A = A ^ #            |
| 70 # | JC #        | jump if carry        |
| 8r   | LD Rr       | A = Rr               |
| 9r   | ST Rr       | Rr = A               |
| Ar   | ADD Rr      | A = A + Rr           |
| Br   | SUB Rr      | A = A - Rr           |
| C0 # | JMP #       | jump                 |
| D0 # | JZ #        | jump if A == 0       |
| E0 # | JNZ #       | jump if A != 0       |
| F0   | OUT         | output port = A      |
| F1   | HALT        | stop                 |
| F2   | SHL         | A = A << 1           |
| F3   | SHR         | A = A >> 1           |

## How to test

Use the RP2040 on the demo board as the program memory: on every clock, read the address on `uo_out`
and drive the byte at that address onto `ui_in`. Assemble programs with `test/assembler.py`;
examples are in `test/programs/` (Fibonacci, multiply, countdown).

## External hardware

None. The demo board's RP2040 acts as the program memory.
