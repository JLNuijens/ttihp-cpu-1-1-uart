# CPU 1.1 UART

Preloaded Universal UART. The stage is already loaded. The clock is the stage. 50 MHz oscillator. Data is RX/TX, not the power. FIRE. Pads. Clock count is the range.

## Available

Two ordinary machines. x86 and ARM64. Same preload.

- Windows PE — i386, x86-64, and Windows-on-ARM
- Mac Mach-O — x86-64 and ARM64
- Linux ELF
- WASM, Java class, Android DEX, UTF-8, and the other measured codings — same preload

UART, SPI, and I2C are the same walk on different pins. Stretch is low-speed USB NRZI and 10 Mbit Manchester — bit cells, not a USB stack or an Ethernet MAC. Nothing is pasted from OpenCores.

## Maps (`ui[4:3]`)

| map | walk | pins |
|---|---|---|
| 00 | UART 8N1 RX/TX | `ui[2]` RX, `uo[0]` TX |
| 01 | SPI mode 0, 8 bits | `uo[4]` MOSI, `uo[5]` SCLK, `uo[6]` CS_n, `ui[2]` MISO |
| 10 | I2C START + byte + ACK + STOP | `uo[4]` SCL, `uio[0]` SDA open-drain |
| 11 | stretch | `uo[0]` DM/TX, `uo[7]` DP. Range 0–2 Manchester, 3–7 USB LS NRZI |

## Range (`ui[7:5]`)

Identity is **1**. That count uses both edges of the 50 MHz wave, so the cell is 10 ns and the line is 100 Mbit/s. Every larger count stays on the rising edge. 434 is still 115200.

| sel | clocks | at 50 MHz |
|---|---|---|
| 0 | 1 | 100 Mbit, both edges |
| 1 | 4 | USB FS bit |
| 2 | 5 | 10 Mbit Ethernet |
| 3 | 8 | |
| 4 | 16 | |
| 5 | 33 | USB LS ~1.5 Mbit |
| 6 | 125 | I2C 400 kHz |
| 7 | 434 | UART 115200 |

Byte on `uio`. Pulse FIRE. Sixty-four bases take that FIRE, four stacks of 16. `r15` stays `0x4F4E4553`. The UART, SPI, and I2C walks are still one copy.

## How to test

1. `rst_n` low then high. `uo[2]` ONES_OK. TX idle high.
2. Map 00, range 0, `uio` = `0x55`, pulse `ui[0]`. UART 8N1 on `uo[0]`.
3. Map 01, same byte. CS low, MOSI MSB first, SCLK mode 0.
4. Map 10. SCL falls, SDA open-drain, STOP, SCL idle high.
5. Drive 8N1 on `ui[2]` with map 00. `uo[3]` GOT.

`N_BASES` is 64. Four stacks of the 16. Each base steps on both edges, so a 50 MHz wave is two steps. The face mix is a tree, six deep. The UART line does not change.
