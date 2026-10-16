# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge

from assembler import INSTRUCTIONS, assemble

PROGRAMS = os.path.join(os.path.dirname(__file__), "programs")
TWO_BYTE = {code >> 4 for code, kind in INSTRUCTIONS.values() if kind == "imm"}


def instruction_addresses(rom, opcode_byte):
    """Addresses where a given 1-byte instruction starts (skipping over immediates)."""
    found, addr = set(), 0
    while addr < len(rom):
        if rom[addr] == opcode_byte:
            found.add(addr)
        addr += 2 if rom[addr] >> 4 in TWO_BYTE else 1
    return found


async def run_program(dut, name):
    """Act as the program memory chip: answer every address with the right byte."""
    rom, _ = assemble(os.path.join(PROGRAMS, name))
    out_at, halt_at = instruction_addresses(rom, 0xF0), instruction_addresses(rom, 0xF1)
    memory = rom + [0] * (256 - len(rom))

    dut.rst_n.value = 0
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    outputs, pending_out = [], False
    for _ in range(5000):
        await FallingEdge(dut.clk)
        if pending_out:
            outputs.append(int(dut.uio_out.value))
            pending_out = False
        addr = int(dut.uo_out.value)
        if addr in halt_at:
            break
        dut.ui_in.value = memory[addr]
        await RisingEdge(dut.clk)
        pending_out = addr in out_at
    else:
        assert False, f"{name} never halted"

    dut._log.info(f"{name}: {outputs}")
    return outputs


@cocotb.test()
async def test_programs(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())
    dut.ena.value = 1
    dut.uio_in.value = 0

    assert await run_program(dut, "fibonacci.asm") == [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233]
    assert await run_program(dut, "multiply.asm") == [42]
    assert await run_program(dut, "countdown.asm") == list(range(10, -1, -1))
