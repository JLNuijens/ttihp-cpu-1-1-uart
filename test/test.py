# SPDX-FileCopyrightText: © 2026 Joshua Luke Nuijens / Axiom 1 Technology, LLC
# SPDX-License-Identifier: Apache-2.0
"""CPU 1.1 UART — RX and TX. Clock is the oscillator. 1 clock = 1 bit."""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

CPB = 1


def tx_bit(dut):
    return int(dut.uo_out.value) & 1


def tx_busy(dut):
    return (int(dut.uo_out.value) >> 1) & 1


def ones_ok(dut):
    return (int(dut.uo_out.value) >> 2) & 1


def rx_live(dut):
    return (int(dut.uo_out.value) >> 3) & 1


def set_rx(dut, bit):
    v = int(dut.ui_in.value)
    if bit:
        v |= 0x04
    else:
        v &= ~0x04
    dut.ui_in.value = v


async def fire_byte(dut, byte):
    dut.uio_in.value = byte
    await RisingEdge(dut.clk)
    v = int(dut.ui_in.value) & ~0x01
    dut.ui_in.value = v | 0x01
    await RisingEdge(dut.clk)
    dut.ui_in.value = v


async def sample_frame(dut):
    assert tx_bit(dut) == 0, "start"
    got = 0
    for i in range(8):
        await ClockCycles(dut.clk, CPB)
        got |= tx_bit(dut) << i
    await ClockCycles(dut.clk, CPB)
    assert tx_bit(dut) == 1, "stop"
    return got


async def drive_rx(dut, byte):
    set_rx(dut, 0)
    await ClockCycles(dut.clk, CPB)
    for i in range(8):
        set_rx(dut, (byte >> i) & 1)
        await ClockCycles(dut.clk, CPB)
    set_rx(dut, 1)
    await ClockCycles(dut.clk, CPB)


async def reset_dut(dut):
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())
    dut.ena.value = 1
    dut.ui_in.value = 0x04  # RX idle high
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 8)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 4)


@cocotb.test()
async def test_idle_ones(dut):
    await reset_dut(dut)
    assert ones_ok(dut) == 1, "ONES_OK after reset"
    assert tx_bit(dut) == 1, "TX idle high"
    assert tx_busy(dut) == 0, "idle not busy"


@cocotb.test()
async def test_fire_0x55(dut):
    await reset_dut(dut)
    await fire_byte(dut, 0x55)
    got = await sample_frame(dut)
    assert got == 0x55, f"data {got:#x}"
    for _ in range(16):
        await RisingEdge(dut.clk)
        if tx_busy(dut) == 0:
            break
    assert ones_ok(dut) == 1, "ONES_OK held"


@cocotb.test()
async def test_fire_ones_low(dut):
    await reset_dut(dut)
    await fire_byte(dut, 0x53)
    got = await sample_frame(dut)
    assert got == 0x53, f"ONES low byte {got:#x}"
    assert ones_ok(dut) == 1


@cocotb.test()
async def test_rx_0x55(dut):
    await reset_dut(dut)
    await drive_rx(dut, 0x55)
    await ClockCycles(dut.clk, 4)
    assert rx_live(dut) == 1, "RX got a byte"
    assert ones_ok(dut) == 1
