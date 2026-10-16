## How it works

An 8-bit accumulator calculator. The accumulator (`ACC`, on `uo_out`) acts like a calculator display.
On each rising clock edge where `GO` is high, it applies the operation selected by `OP[2:0]`
to the accumulator and the input number `B` (on `ui_in`):

| OP | Operation | Result          |
|----|-----------|-----------------|
| 0  | LOAD      | ACC = B         |
| 1  | ADD       | ACC = ACC + B   |
| 2  | SUB       | ACC = ACC - B   |
| 3  | AND       | ACC = ACC & B   |
| 4  | OR        | ACC = ACC \| B  |
| 5  | XOR       | ACC = ACC ^ B   |
| 6  | SHL       | ACC = ACC << 1  |
| 7  | SHR       | ACC = ACC >> 1  |

`CARRY` is set on add overflow, subtract borrow, or the bit shifted out. `ZERO` is high when ACC is 0.

## How to test

Reset, then set `B` on the input switches, choose `OP` on uio[2:0], and pulse `GO` (uio[3]) for one clock.
Read the result on the output LEDs.

## External hardware

None, the demo board switches and LEDs are enough.
