# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

LOAD, ADD, SUB, AND, OR, XOR, SHL, SHR = range(8)
GO = 1 << 3


async def press(dut, op, b, want, want_carry):
    """Set an operation and number, tick the clock once, check the display."""
    dut.ui_in.value = b
    dut.uio_in.value = GO | op
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0  # release "go" so nothing changes until the next press
    await ClockCycles(dut.clk, 1)
    acc = int(dut.uo_out.value)
    carry = (int(dut.uio_out.value) >> 4) & 1
    zero = (int(dut.uio_out.value) >> 5) & 1
    dut._log.info(f"op={op} b={b:3d} -> acc={acc:3d} carry={carry} zero={zero}")
    assert acc == want, f"acc={acc}, expected {want}"
    assert carry == want_carry, f"carry={carry}, expected {want_carry}"
    assert zero == (want == 0)


@cocotb.test()
async def test_project(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    await press(dut, LOAD, 3, 3, 0)
    await press(dut, ADD, 5, 8, 0)
    await press(dut, SUB, 2, 6, 0)
    await press(dut, SHL, 0, 12, 0)
    await press(dut, SHR, 0, 6, 0)
    await press(dut, AND, 12, 4, 0)
    await press(dut, OR, 1, 5, 0)
    await press(dut, XOR, 5, 0, 0)
    await press(dut, LOAD, 250, 250, 0)
    await press(dut, ADD, 10, 4, 1)    # 260 wraps to 4, carry out
    await press(dut, SUB, 5, 255, 1)   # 4 - 5 wraps to 255, borrow
