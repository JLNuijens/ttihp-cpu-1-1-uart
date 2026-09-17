# SPDX-FileCopyrightText: © 2026 Joshua Luke Nuijens / Axiom 1 Technology, LLC
# SPDX-License-Identifier: Apache-2.0
"""CPU 1.1 UART — RX and TX. Clock is the oscillator. 1 clock = 1 bit."""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer

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
    dut.ui_in.value = 0x05  # FIRE + RX idle high
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0x04
    await Timer(1, unit="ns")


async def sample_frame(dut):
    for _ in range(20):
        if tx_bit(dut) == 0:
            break
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")
    else:
        raise AssertionError("no start bit on TX")
    got = 0
    for i in range(8):
        await ClockCycles(dut.clk, CPB)
        await Timer(1, unit="ns")
        got |= tx_bit(dut) << i
    await ClockCycles(dut.clk, CPB)
    await Timer(1, unit="ns")
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
    task = cocotb.start_soon(clock.start())
    dut.ena.value = 1
    dut.ui_in.value = 0x04  # RX idle high
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 8)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 4)
    return task


@cocotb.test()
async def test_idle_ones(dut):
    task = await reset_dut(dut)
    try:
        assert ones_ok(dut) == 1, "ONES_OK after reset"
        assert tx_bit(dut) == 1, "TX idle high"
        assert tx_busy(dut) == 0, "idle not busy"
    finally:
        task.cancel()


@cocotb.test()
async def test_fire_0x55(dut):
    task = await reset_dut(dut)
    try:
        await fire_byte(dut, 0x55)
        got = await sample_frame(dut)
        assert got == 0x55, f"data {got:#x}"
        for _ in range(16):
            await RisingEdge(dut.clk)
            if tx_busy(dut) == 0:
                break
        assert ones_ok(dut) == 1, "ONES_OK held"
    finally:
        task.cancel()


@cocotb.test()
async def test_fire_ones_low(dut):
    task = await reset_dut(dut)
    try:
        await fire_byte(dut, 0x53)
        got = await sample_frame(dut)
        assert got == 0x53, f"ONES low byte {got:#x}"
        assert ones_ok(dut) == 1
    finally:
        task.cancel()


@cocotb.test()
async def test_rx_0x55(dut):
    task = await reset_dut(dut)
    try:
        await drive_rx(dut, 0x55)
        await ClockCycles(dut.clk, 4)
        assert rx_live(dut) == 1, "RX got a byte"
        assert ones_ok(dut) == 1
    finally:
        task.cancel()


def csn(dut):
    return (int(dut.uo_out.value) >> 6) & 1


def mosi(dut):
    return (int(dut.uo_out.value) >> 4) & 1


async def fire_map(dut, byte, map_bits, range_bits=0):
    dut.uio_in.value = byte
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0x01 | map_bits | (range_bits << 5)
    await RisingEdge(dut.clk)
    dut.ui_in.value = map_bits | (range_bits << 5)
    await Timer(1, unit="ns")


@cocotb.test()
async def test_spi_0xa5(dut):
    task = await reset_dut(dut)
    try:
        await fire_map(dut, 0xA5, 0x08)
        await Timer(1, unit="ns")
        assert csn(dut) == 0, "CS low"
        assert mosi(dut) == 1, "MSB of 0xA5"
        for _ in range(64):
            await RisingEdge(dut.clk)
            if tx_busy(dut) == 0 and csn(dut) == 1:
                break
        assert csn(dut) == 1, "CS back high"
        assert ones_ok(dut) == 1
    finally:
        task.cancel()


@cocotb.test()
async def test_i2c_start_stop(dut):
    task = await reset_dut(dut)
    try:
        await fire_map(dut, 0xA0, 0x10)
        saw_low = False
        for _ in range(80):
            await RisingEdge(dut.clk)
            if mosi(dut) == 0:
                saw_low = True
            if tx_busy(dut) == 0 and saw_low:
                break
        assert saw_low, "SCL dropped"
        assert ones_ok(dut) == 1
    finally:
        task.cancel()


@cocotb.test()
async def test_eth_manchester(dut):
    task = await reset_dut(dut)
    try:
        await fire_map(dut, 0x55, 0x18, 2)
        await Timer(1, unit="ns")
        assert tx_busy(dut) == 1, "line busy"
        for _ in range(80):
            await RisingEdge(dut.clk)
            if tx_busy(dut) == 0:
                break
        assert tx_busy(dut) == 0
        assert ones_ok(dut) == 1
    finally:
        task.cancel()
