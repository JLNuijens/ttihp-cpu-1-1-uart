#!/usr/bin/env python3
"""Cycle model of js_uart_fire.v — FIRE 0x55 must be 8N1 on TX."""
from __future__ import annotations

CLKS = 8
ONES = 0x4F4E4553


def walk(seq: int, clks: int = CLKS) -> list[int]:
    tx = 1
    go = False
    bit_i = 0
    ck = 0
    frame = 0x3FF
    busy = False
    fire = True
    out: list[int] = []
    # enough clocks for start+8+stop + idle
    for _ in range(12 * clks):
        if fire and not busy:
            frame = ((1 << 9) | ((seq & 0xFF) << 1) | 0)
            bit_i = 0
            ck = 0
            go = True
            busy = True
            tx = 0
            fire = False
        elif go:
            if ck == clks - 1:
                ck = 0
                if bit_i == 9:
                    go = False
                    busy = False
                    tx = 1
                else:
                    nxt = bit_i + 1
                    tx = (frame >> nxt) & 1
                    bit_i = nxt
            else:
                ck += 1
        out.append(tx)
    return out


def decode(bits: list[int], clks: int = CLKS) -> int:
    # first falling edge is start
    i = bits.index(0)
    mid = i + clks // 2
    val = 0
    for b in range(8):
        sample = bits[mid + (b + 1) * clks]
        val |= (sample & 1) << b
    stop = bits[mid + 9 * clks]
    assert stop == 1, "stop"
    return val


def main() -> None:
    bits = walk(0x55)
    assert bits[0] == 0, "start"
    got = decode(bits)
    assert got == 0x55, hex(got)
    assert ONES == 0x4F4E4553
    print("PASS  FIRE 0x55  8N1  start+01010101+stop")
    bits2 = walk(0x53)
    assert decode(bits2) == 0x53
    print("PASS  FIRE 0x53  (ONES low byte)")


if __name__ == "__main__":
    main()
