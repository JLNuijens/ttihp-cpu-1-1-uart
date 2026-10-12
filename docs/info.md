# ONE CPU 1.1 32 · 1.6 GB/s

That is the UART. Thirty-two bases on one FIRE. 1.6 GB/s inside on the rise. The line is 100 Mbit/s. Four `512×32` foundry macros sit beside it. 8 KB. The 8×4 template is not in the flow yet.

## SRAM

Four copies of `RM_IHPSG13_1P_512x32_c2_bm_bist`. 512 words, 32 bits, 2 KB each. 8 KB on the die. One port. Two of them already passed precheck. The other two are the same macro, placed beside them.

On map `11`, range `000`, `uio[7:0]` is the address. The top address bit stays 0, so 256 of the 512 words come out to the pins. All four macros use that same address. Bases 0 through 3 each read their own word. `uo[7:0]` is the low byte of the first word, and it replaces the walk pins while this map is selected. FIRE stores the four results at that address. The words stay until that address is written again. UART, SPI, I2C, and the other walks keep their pins.

## Pin layout

| Pad | UART | ONE CPU 1.1 32 · 1.6 GB/s |
|---|---|---|
| `ui[0]` | FIRE | same pulse, all 32 bases |
| `ui[1]` | HOT | clock holds the stage |
| `ui[2]` | RX | finished byte lands in `r8` |
| `ui[4:3]` | UART, SPI, I2C, stretch | `00` keeps the face on `uo[4:7]` |
| `ui[7:5]` | count 1…434 | does not change the face |
| `uio[7:0]` | the byte | base *k* folds byte + *k* |
| `uo[0]` | TX · 100 Mbit/s | low byte of that word |
| `uo[2]` | ONES | `r15` is `0x4F4E4553` |
| `uo[4:7]` | SPI / I2C / stretch, or the face | low nibble, then the next four, one rise each |

Not three protocol blocks. The map selects the walk. The byte is any word. The clock holds the stage while the tile is enabled. No fetch after fabrication.

## Universal, and the range

Jane Street asked if the chip can be pointed at something else after it is built. This die does that with the pins. Same clock. Same FIRE. Same 32 bases.

`uio[7:0]` is the byte. Any of the 256. The sites do not change. `ui[7:5]` is how many clocks the bit is held. Eight counts. `ui[4:3]` is which pins that bit walks out on. Set those, pulse FIRE, and the cell is different. UART at the I2C hold is the same die. I2C at the USB count is the same die. SPI at the fast hold is the same die.

One oscillator. FIRE is one rising edge of `ui[0]`. Nothing is fetched. The whole die is that edge.

The byte on `uio[7:0]` is the pattern. That edge loads it into the shift and into all 32 bases. Base *k* folds byte + *k*. UART, SPI, I2C, Manchester, NRZI, JTAG, SWD, PS/2, and the CAN cell all shift that same byte. Any of the 256. A named format is just bytes.

The count on `ui[7:5]` is how many clocks the bit is held: 1, 4, 5, 8, 16, 33, 125, 434. Count 1 uses both edges. Every larger count holds on the rise. The fall is not a new bit. The count is the rate. It is not a program.

The map on `ui[4:3]` chooses the pins. `00` is NRZ on TX. `01` is SPI mode 0. `10` is I2C, SCL driven and SDA open-drain. `11` lets the count pick the line: memory, JTAG, Manchester, SWD, PS/2, NRZI, or a CAN bit cell. The walks that were not selected do not get FIRE. They hold.

After fabrication the protocol is those three inputs. Byte, count, map, FIRE. The cell that comes out is that byte, held for that many clocks, on those pins. The 32 bases fold the same byte on that same edge. There is not a second machine beside this one.

Preloaded Universal UART. The stage is already loaded. The clock is the stage. 50 MHz oscillator. Data is RX/TX, not the power. FIRE. Pads. Clock count is the range.

## Preloaded

Any word. Same sites. x86 and ARM64 are not the limit.

Windows PE, Mac Mach-O, Linux ELF, Android DEX, Java, WASM, UTF-8, and a GPU file all take the same FIRE. The list is not a whitelist. A byte the list does not name still folds.

UART, SPI, and I2C are the same walk on different pins. Stretch is low-speed USB NRZI and 10 Mbit Manchester — bit cells, not a USB stack or an Ethernet MAC. Nothing is pasted from OpenCores.

## Maps (`ui[4:3]`)

| map | walk | pins |
|---|---|---|
| 00 | UART 8N1 RX/TX | `ui[2]` RX, `uo[0]` TX |
| 01 | SPI mode 0, 8 bits | `uo[4]` MOSI, `uo[5]` SCLK, `uo[6]` CS_n, `ui[2]` MISO |
| 10 | I2C START + byte + ACK + STOP | `uo[4]` SCL, `uio[0]` SDA open-drain |
| 11 | stretch, and the other walks | see the count slot. Manchester and USB stay. JTAG, SWD, PS/2, and a CAN bit are the slots we took |

## Range (`ui[7:5]`)

Identity is **1**. That count uses both edges of the 50 MHz wave, so the cell is 10 ns and the line is 100 Mbit/s. Every larger count stays on the rising edge. 434 is still 115200.

| sel | clocks | UART / SPI / I2C | hook `11` |
|---|---|---|---|
| 0 | 1 | 100 Mbit, both edges | memory. `uio` is the address. `uo[7:0]` is the low byte of the kept word. Manchester is not on these pins |
| 1 | 4 | | JTAG. FIRE the TMS byte, FIRE the TDI byte. Eight TCK. TDO comes back. TCK `uo[5]`, TMS `uo[6]`, TDI `uo[4]`, TDO `ui[2]` |
| 2 | 5 | 10 Mbit | Manchester |
| 3 | 8 | | SWD. FIRE the request, FIRE the data byte. Header, turnaround, ACK, one data byte. SWCLK `uo[5]`, SWDIO `uio[0]` |
| 4 | 16 | | PS/2 device frame at 12.5 kHz, not at count 16. Start, byte, odd parity, stop. Clock `uio[1]`, data `uio[0]` |
| 5 | 33 | USB LS ~1.5 Mbit | USB LS NRZI |
| 6 | 125 | I2C 400 kHz | CAN bit cell only. Not a frame. `uo[0]`, RX `ui[2]` |
| 7 | 434 | UART 115200 | USB at that count |

Hook `11` only. On UART, SPI, and I2C the same slots are still just the bit time.

JTAG is a real bit-bang. The first FIRE stores TMS. The second FIRE clocks eight bits of TDI with that TMS, and samples TDO. SWD is a real header: start, APnDP, RnW, A2, A3, parity, stop, park, then the turnaround, the ACK, and one byte of the data phase. Not a 32-bit read. PS/2 is the device frame, open-drain, 4000 clocks a half-bit, 12.5 kHz. CAN on slot 6 is still eight bit cells, not a frame.

Byte on `uio`. Pulse FIRE. Thirty-two bases take that FIRE, two stacks of 16. `r15` stays `0x4F4E4553`. The UART, SPI, and I2C walks are still one copy.

## Processor · ONE CPU 1.1 32

Allnary. Any byte. The sites do not change with the coding. 32 bases, 16 sites each. The lane is the only difference.

| | |
|---|---|
| Clock | 50 MHz. The step is the rise. 20 ns. |
| Stack | 32 bases. Not 128. |
| Inside | 32 × 50 MHz = 1.6 billion steps/s = 1.6 GB/s |
| Word in | 8 bits, one FIRE. Not one byte per clock. |
| Face out | `uo[2]` plus four pins. This rise is the low nibble, the next rise is the next four. 200 Mbit/s. The clock is not used as data. The rest stays inside. |
| Fetch | none. Already loaded. |

| Site | At reset | While the clock holds |
|---|---|---|
| r1 | 0 | cycle + 1 each rise |
| r2 | the lane | stride + 128 each rise |
| r4 | `0x020A0000` | sig0 of the FIRE word |
| r5 | 0 | sig1 of the FIRE word |
| r6 | 1 | weight of the FIRE word |
| r7 | 128 | held every rise |
| r8 | 0 | last RX byte |
| r9 | 0 | last FIRE word |
| r14 | 4 | held every rise |
| r15 | `0x4F4E4553` | ONES, held every rise |

r0, r3, and r10 through r13 stay 0. Base k starts its stride at k. FIRE gives that base `byte + k`. A finished RX byte lands in r8 of every base. The count does not change the face.

Leave the map at UART. Put the byte on `uio`. Pulse `ui[0]`. Read `uo[2]` and `uo[4]` through `uo[7]`.

## How to test

1. `rst_n` low then high. `uo[2]` ONES_OK. TX idle high.
2. Map 00, range 0, `uio` = `0x55`, pulse `ui[0]`. UART 8N1 on `uo[0]`.
3. Map 01, same byte. CS low, MOSI MSB first, SCLK mode 0.
4. Map 10. SCL falls, SDA open-drain, STOP, SCL idle high.
5. Drive 8N1 on `ui[2]` with map 00. `uo[3]` GOT.

`N_BASES` is 32. Two stacks of the 16. Four stacks measured 77% of the core and detailed placement failed, so they do not fit this tile. The step is the rise. The fall stays the UART bit at count 1.
