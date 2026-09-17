# CPU 1.1 UART

1.1 class line. UART is FIRE on a pad. Clock is the oscillator — not the data. RX in, TX out. Sixteen 1.1-class bases in a 6×4 Tiny Tapeout tile, sixteen pad/register sites inside.

Byte on `uio`. Pulse FIRE. One clock is one bit: start, eight data LSB-first, stop on `uo[0]`. Drive 8N1 on `ui[2]` and the byte lands on r8. Same FIRE folds the face. `r15` stays `0x4F4E4553`.

## How it works

The stage is preloaded. Power is the clock. `HOT` (or `ena`) holds the bases.

- Rising edge on `ui[0]` is FIRE. `js_uart_fire` packs `{stop, seq[7:0], start}` and walks one bit every clock.
- Falling edge on `ui[2]` is RX start. Same count samples eight data bits, then stop. Byte strobes into r8 of every base.
- All 16 bases take the same FIRE. Face (`sig0`/`sig1`/`wt`) is the 1.1 fold of the word. Every site is XOR-tied into `uo[7:4]` so synth cannot delete the pads.
- TX idle is high. RX idle is high. `CLKS_PER_BIT = 1`. 50 MHz → 50 Mbit.

## How to test

1. `rst_n` low, then high. `uo[2]` (ONES_OK) = 1. TX idle high.
2. `uio` = `0x55`. Pulse `ui[0]` one clock.
3. TX: start, 01010101 LSB-first, stop.
4. Drive the same 8N1 on `ui[2]`. `uo[3]` RX_GOT.
5. FIRE `0x53`. ONES_OK stays 1.

## External hardware

Clock, ground, RX, TX. No crystal. Baud is the clock.

`N_BASES` default 16. Drop to 8 if GDS is fat. 32 is the wall.
