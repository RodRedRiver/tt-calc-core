"""Tiny8 assembler: turns human-readable assembly into machine code bytes.

Usage: python assembler.py program.asm            -> writes program.hex, prints a listing

Syntax:
    loop:            a label (a name for an address you can jump to)
    LDI 5            instruction + number (decimal, 0x hex, or 0b binary)
    ADD r1           instruction + register
    JMP loop         instruction + label
    ; comment
"""
import sys

# mnemonic: (opcode byte, kind)   kind: None = 1 byte, "imm" = 2 bytes, "reg" = register in low bits
INSTRUCTIONS = {
    "NOP":  (0x00, None),
    "LDI":  (0x10, "imm"), "ADDI": (0x20, "imm"), "SUBI": (0x30, "imm"),
    "ANDI": (0x40, "imm"), "ORI":  (0x50, "imm"), "XORI": (0x60, "imm"),
    "JC":   (0x70, "imm"),
    "LD":   (0x80, "reg"), "ST":   (0x90, "reg"), "ADD":  (0xA0, "reg"), "SUB": (0xB0, "reg"),
    "JMP":  (0xC0, "imm"), "JZ":   (0xD0, "imm"), "JNZ":  (0xE0, "imm"),
    "OUT":  (0xF0, None), "HALT": (0xF1, None), "SHL":  (0xF2, None), "SHR": (0xF3, None),
}


def parse(path):
    """Split the source into (line_number, label, mnemonic, argument) tuples."""
    lines = []
    for n, raw in enumerate(open(path), 1):
        text = raw.split(";")[0].strip()
        label = None
        if ":" in text:
            label, text = (s.strip() for s in text.split(":", 1))
        parts = text.split()
        lines.append((n, label, parts[0].upper() if parts else None, parts[1] if len(parts) > 1 else None, raw.rstrip()))
    return lines


def assemble(path):
    lines = parse(path)

    # Pass 1: walk through the program to learn the address of every label
    labels, addr = {}, 0
    for n, label, op, arg, _ in lines:
        if label:
            labels[label] = addr
        if op:
            if op not in INSTRUCTIONS:
                sys.exit(f"line {n}: unknown instruction {op}")
            addr += 2 if INSTRUCTIONS[op][1] == "imm" else 1

    # Pass 2: emit the bytes, now that every label is known
    out, listing = [], []
    for n, label, op, arg, raw in lines:
        if not op:
            listing.append(f"{'':12s}{raw}")
            continue
        code, kind = INSTRUCTIONS[op]
        start = len(out)
        if kind == "imm":
            if arg is None:
                sys.exit(f"line {n}: {op} needs a number or label")
            value = labels[arg] if arg in labels else int(arg, 0)
            if not 0 <= value <= 255:
                sys.exit(f"line {n}: {value} does not fit in 8 bits")
            out += [code, value]
        elif kind == "reg":
            if not arg or arg.lower() not in ("r0", "r1", "r2", "r3"):
                sys.exit(f"line {n}: {op} needs a register r0..r3")
            out.append(code | int(arg[1]))
        else:
            out.append(code)
        hexbytes = " ".join(f"{b:02X}" for b in out[start:])
        listing.append(f"{start:02X}: {hexbytes:7s} {raw}")

    if len(out) > 256:
        sys.exit(f"program is {len(out)} bytes, only 256 fit")
    return out, listing


if __name__ == "__main__":
    src = sys.argv[1]
    program, listing = assemble(src)
    hex_path = src.rsplit(".", 1)[0] + ".hex"
    with open(hex_path, "w") as f:
        f.write("\n".join(f"{b:02X}" for b in program) + "\n")
    print("\n".join(listing))
    print(f"\n{len(program)} bytes -> {hex_path}")
