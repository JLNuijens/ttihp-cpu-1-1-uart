# CPU 1.1 UART

1.1 class line. UART is FIRE on a pad. Sixteen 1.1-class bases in a 6×4 Tiny Tapeout tile, sixteen pad/register sites inside. Plug peeled to shuttle pins.

Byte on `uio`. Pulse FIRE. Clock count walks start, eight data bits LSB-first, stop on `uo[0]`. Same FIRE folds the face. `r15` stays `0x4F4E4553`.

## How it works

The stage is preloaded. Power is the clock. `HOT` (or `ena`) holds the bases. A rising edge on `ui[0]` is FIRE:

- `js_uart_fire` packs `{stop, seq[7:0], start}` and walks one bit every `CLKS_PER_BIT` clocks.
- All 16 bases take the same FIRE. Face (`sig0`/`sig1`/`wt`) is the 1.1 fold of the word.
- TX idle is high. BUSY is high for the ten bits.

Sim uses `CLKS_PER_BIT = 8`. Silicon at 50 MHz for 115200 baud is 434.

## How to test

1. `rst_n` low, then high. `uo[2]` (ONES_OK) = 1. TX idle high.
2. `uio` = `0x55`. Pulse `ui[0]` one clock.
3. TX: start, 01010101 LSB-first, stop. All 16 bases take that FIRE.
4. `uo[1]` BUSY high for the 10 bits, then low.
5. FIRE `0x53`. ONES_OK stays 1.

## External hardware

UART RX on `uo[0]`. 8N1. Idle high. Dev-board USB-UART or a scope is enough. No crystal. Baud is clock divide.

`N_BASES` default 16. Drop to 8 if GDS is fat. 32 is the wall.
