# ONE CPU 1.1 32

Jane Street protocol-emulator ASIC. IHP CMOS5L, tile 8×4. The clock is 50 MHz. `ui[0]` sits low. Raise it for one cycle. That cycle is FIRE. The byte is already on the pins, and all 32 bases take it. Base *k* gets the byte plus *k*. Every cycle, on all 32, is the 1.6 GB/s. The line at count 1 is 100 Mbit/s, both edges. Four `512×32` macros. Two behind the bases hold a cycle each. Two in front hold the list.

Jane Street asked for one part that can be used for more than one thing after fabrication. This one is. The register is the program: the map, the count, and the byte. No separate file is sent. The loads are the CPU, UART, SPI, I2C, and, on the hook, the memory, JTAG, Manchester, SWD, PS/2, a USB low-speed bit cell, and a CAN bit cell. Same clock, same FIRE, same 32 bases.

## SRAM

Two copies of `RM_IHPSG13_1P_512x32_c2_bm_bist` sit behind the bases. Both hold a cycle. FIRE writes the new cycle in the second and moves the one already there into the first. The compare is the second minus the first. The clock is not set back. 256 of the 512 words are named by the pins. Two more sit in front and hold the list, 1,024 cells, 13 bits used in each. One of those two is on at a time.

Map `11`, count `000`. `uio[7:0]` is the address. The upper address bit is held at 0, so 256 of 512 words are reachable. Both macros use that address. Bases 0 and 1 each read their own word. `uo[7:0]` is the low byte of the first word and replaces the walk pins while this map is selected. FIRE stores the two results. The words remain until that address is written again.

## Pin layout

| Pad | Walk | Processor |
|---|---|---|
| `ui[0]` | FIRE | One rising edge, all 32 bases |
| `ui[1]` | HOT, and the store | High holds the stage. With map `11`, count `000`, and FIRE, stores the register. |
| `ui[2]` | RX | Finished byte is stored in r8 |
| `ui[4:3]` | UART, SPI, I2C, or hook | `00` leaves the face on `uo[4:7]` |
| `ui[7:5]` | Hold, 1 to 434 clocks | Does not change the face |
| `uio[7:0]` | Byte, or the memory address | Base *k* folds byte + *k* |
| `uo[0]` | TX, 100 Mbit/s at count 1 | Low byte of the word on the memory map |
| `uo[2]` | ONES | High while r15 is `0x4F4E4553` |
| `uo[4:7]` | SPI, I2C, or the hook line | Low nibble, then the next four, one rising edge each |

## Configuration

The protocol after fabrication is three inputs and FIRE.

| Input | Width | Effect |
|---|---|---|
| `uio[7:0]` | 8 | The byte. Any of 256. Sites do not change. |
| `ui[7:5]` | 3 | Clocks the bit is held: 1, 4, 5, 8, 16, 33, 125, 434. |
| `ui[4:3]` | 2 | Pins that carry the bit. |

Same clock. Same FIRE. Same 32 bases. Any byte, any count, and any map is a cell. The named walks are not a whitelist. No module is added.

The register is the program. It holds the map, the count, and the byte. It is not the SRAM. Set the pads to the load, then FIRE on map `11`, count `000`, with `ui[1]` high. Reset clears it. The count is one of the eight holds. The two macros behind the bases hold a cycle each.

The byte is loaded into the shift and into all 32 bases on the FIRE edge. UART, SPI, I2C, Manchester, NRZI, JTAG, SWD, PS/2, and the CAN cell shift that byte. A named file format is a sequence of bytes. An unnamed byte takes the same edge.

The same FIRE is the add, the carry, the multiply, the divide, the AND, the OR, the XOR, the shift, and the compare. Base *k* returns the byte plus *k*. The stride is 128 times the cycle. The count divides the 50 MHz clock. `ui[5]` and `ui[6]` together are the 8-clock hold. All three count pins are the 434-clock hold. The 32 results mix by XOR onto `uo[7:4]`. The low byte of the result is the byte you fired. Each clock adds 1 to the cycle and 128 to the stride. The how-to is in the README under Functions.

Count 1 uses both edges of the 50 MHz clock. Every larger count holds the bit on the rising edge. The falling edge is not a new bit.

## Preloaded

The input is the load. FIRE puts it on the bases and on the pins. A byte is eight weights: 1, 2, 4, 8, 16, 32, 64, 128. Each is 2 of the one before it. The byte is the sum of the weights that are on. There is no separate file.

An instruction from another machine is that byte. The opcode is the byte. The 1s in it are the weights, and those run on the cycle `ui[0]` is high. `90` is `10010000`, weights 16 and 128, result `104f0090`. `C3` is not a return. `B1` has no name. All 256 codes take that cycle and return themselves in the low byte. 113 machines were fired, 185 cycles, and every byte came back. The table is in the README under "The byte." x86 and ARM64 are not a special case, and they are not a limit.

UART, SPI, and I2C are the same shift on different pins. The hook walks are bit cells: low-speed USB NRZI, 10 Mbit Manchester, a JTAG shift, an SWD header, a PS/2 device frame, and a CAN bit. They are not a USB stack, an Ethernet MAC, or a CAN controller.

## Maps (`ui[4:3]`)

| Map | Walk | Output | Input |
|---|---|---|---|
| `00` | UART 8N1 | `uo[0]` TX | `ui[2]` RX |
| `01` | SPI mode 0, 8 bits | `uo[4]` MOSI, `uo[5]` SCLK, `uo[6]` CS | `ui[2]` MISO |
| `10` | I2C START, byte, ACK, STOP | `uo[4]` SCL | `uio[0]` SDA, open-drain |
| `11` | Count selects the line | See the range table | See the range table |

## Range (`ui[7:5]`)

| Sel | Clocks | On UART, SPI, I2C | On map `11` |
|---|---|---|---|
| 0 | 1, both edges, 100 Mbit/s | Bit time 10 ns | Memory. `uio` is the address. `uo[7:0]` is the low byte. |
| 1 | 4 | Bit time 80 ns | JTAG. First FIRE stores TMS. Second FIRE clocks eight TDI bits and samples TDO. TCK `uo[5]`, TMS `uo[6]`, TDI `uo[4]`, TDO `ui[2]`. |
| 2 | 5, 10 Mbit/s | Bit time 100 ns | Manchester on `uo[0]` and `uo[7]`. |
| 3 | 8 | Bit time 160 ns | SWD. Request, then one data byte. Header, turnaround, ACK. SWCLK `uo[5]`, SWDIO `uio[0]`. Not a 32-bit read. |
| 4 | 16 | Bit time 320 ns | PS/2 device frame at 12.5 kHz. Half-bit is 4000 clocks. Start, byte, odd parity, stop. Clock `uio[1]`, data `uio[0]`. |
| 5 | 33 | USB low-speed bit time | USB low-speed NRZI. A bit cell, not a stack. |
| 6 | 125 | I2C 400 kHz bit time | CAN bit cell on `uo[0]`. Eight cells, not a frame. RX is `ui[2]`. |
| 7 | 434 | UART 115200 | USB NRZI at this hold. A bit cell, not a stack. |

On maps `00`, `01`, and `10` the count is only the bit time. The hook walks are selected only on map `11`.

## Seat

The 512 is the preload already in the CPU. r7 is 128. r14 is 4. `4 × 128 = 512`. There is no second circuit. A pin weight times r14 is the 512 column. That number times `720 / 512` is the 720 column. Each rising edge adds r7 to the stride. That is one rung: 4, and 5.625°.

The macros hold. One FIRE writes one address, the byte on `uio`. Base 0 goes in the first macro, base 1 in the second. Other addresses keep what they have. The word stays until that address is written again. Not a fetch. Not a cache.

## Ground

1. `rst_n` low. `ui` and `uio` held at 0.
2. `rst_n` high. Difference is 0. `uo[7:0]` is `00000101`, with `uo[7]` on the left.
3. Raise one pin. That weight is the intake. `ui` is negative. `uio` is positive.

| Weight | Seat |
|---|---|
| 1 | 5.625° |
| 2 | 11.25° |
| 4 | 22.5° |
| 8 | 45° |
| 16 | 90° |
| 32 | 180° |
| 64 | 360° |
| 128 | 720° |

The per-pin `uo` readings are in the README. Reset is required to measure one pin alone. Code on `ui[3]` and `ui[4]` in the same clock returns `00000000`, which is neither pin's own result. The two patterns are not added.

## Processor

| | |
|---|---|
| Clock | 50 MHz. Step is the rising edge. 20 ns. |
| Bases | 32. Stride per base is +128. |
| Internal rate | 1.6 GB/s |
| Word | 8 bits, one FIRE |
| Face | `uo[2]`, and `uo[4:7]` when no walk owns them. 200 Mbit/s. |
| Fetch | None |

| Site | At reset | While the clock holds |
|---|---|---|
| r1 | 0 | Cycle + 1 each rising edge |
| r2 | The lane | Stride + 128 each rising edge |
| r4 | `0x020A0000` | Signature 0 |
| r5 | 0 | Signature 1 |
| r6 | 1 | Weight |
| r7 | 128 | Held |
| r8 | 0 | Last RX byte |
| r9 | 0 | Last FIRE word |
| r14 | 4 | Held |
| r15 | `0x4F4E4553` | ONES |

r0, r3, and r10 through r13 stay 0.

## Procedure

1. `rst_n` low, then high. `uo[2]` is ONES. `uo[0]` is idle high.
2. Map `00`, count `000`, `uio` = `0x55`. Pulse `ui[0]`. `uo[0]` is 8N1.
3. Map `01`, same byte. `uo[6]` low, `uo[4]` MSB first, `uo[5]` mode 0.
4. Map `10`. `uo[4]` falls, `uio[0]` open-drain, then STOP.
5. Drive 8N1 into `ui[2]` on map `00`. `uo[3]` marks the received byte.
