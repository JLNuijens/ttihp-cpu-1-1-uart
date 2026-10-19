![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# ONE CPU 1.1 32

Jane Street protocol-emulator ASIC. Tiny Tapeout, IHP CMOS5L, tile 8×4.

Joshua Luke Nuijens / Axiom 1 Technology, LLC. Top module `tt_um_jlnuijens_one11_uart`.

The demo is [this page](https://cdn.jsdelivr.net/gh/JLNuijens/ttihp-cpu-1-1-uart@main/docs/demo.html). The metal is [the tile](https://gds-viewer.tinytapeout.com/?pdk=ihp-sg13cmos5l&model=https://jlnuijens.github.io/ttihp-cpu-1-1-uart/tinytapeout.oas).

## On this tile

8×4. 1724 by 711 µm. One clock, 50 MHz. The clock is the step. While the tile is enabled, all 32 bases add 1 to the cycle and 128 to the stride on every rise. That is the 1.6 GB/s. Nothing is fetched.

On that die, from the same clock:

- Any of 256 bytes. 113 machines were fired, 185 cycles, and every byte came back.
- UART at 100 Mbit/s, SPI mode 0, and I2C. The map picks the pins. The hold picks the bit time. Eight holds, from 1 clock to 434.
- On the hook: JTAG, SWD, PS/2, Manchester, a USB low-speed bit, and a CAN bit.
- A register that stores the map, the hold, and the byte after the chip is made.
- A list of 1,024 of those steps in the two front memories.
- Two cycles kept in the two back memories, and the difference of them.
- Add, carry, the stride as the multiply, the hold as the divide, AND, OR, XOR, shift, and compare.
- The 512 seat and the 720 reading. r15 held at `4F4E4553`.

## Words

| Word | What it is |
|---|---|
| Cycle | One tick of the 50 MHz clock. 20 ns. |
| FIRE | `ui[0]` high for one cycle, low the cycle before. That is the whole word. |
| Byte | The eight pins `uio[7:0]`. |
| Weight | One of 1, 2, 4, 8, 16, 32, 64, 128. A 1 in the byte means that weight is in the sum. |
| Load | The sum of the weights that are present. |
| Base | One of the 32 copies. Base *k* is copy number *k*. Base 0 gets the byte. Base *k* gets the byte plus *k*. |
| Result | The 32-bit word that comes back. Its low byte is the byte that went in. |
| Returned weight | The number beside the result: 1, 2, 8, or a larger power of two. Not one of the eight weights. |
| Stride | The cycle count times 128. Cycle 4 is stride 512. |
| Rung | One step of the stride. One rung is 4 on the seat, and 5.625°. |
| Seat | 512. Register r7 is held at 128. Register r14 is held at 4. `4 × 128 = 512`. |
| 720 | The seat times `720 / 512`. The same number, read in degrees. |
| Map | `ui[4:3]`. Which pins carry the bit. |
| Hold | `ui[7:5]`. How many cycles the bit stays. Also called the count. |
| Walk | The pin sequence for that map. UART, SPI, I2C, or a hook. |
| Hook | Map `11`. The hold then picks the memory, JTAG, Manchester, SWD, PS/2, USB, or CAN. |
| Register | The stored map, hold, and byte. |
| HOT | `ui[1]` high. It holds the stage. With the memory map, it stores the register. |
| Stage | What the clock keeps while the tile is enabled. |
| List | The cells in the two front memories. A cell is a map, a hold, and a byte. |
| Face | `uo[7:4]` when no walk is driving those pins. |
| ONES | Register r15, the value `4F4E4553`. `uo[2]` is high while it holds. |
| Ground | Reset with `ui` and `uio` at 0. The difference is 0. |
| Macro | One memory block. 512 words, 32 bits each. |
| Lane | Where a base starts. Base *k* starts at *k*. The stride is the lane plus 128 times the cycle. |
| Stack | r7, held at 128. One rung adds the stack to the stride. |
| Fold | The 32 results mixed by XOR, from 32 down to 1. |
| Signature | The result kept at r4. The low byte is the byte that went in. |
| Preload | The values already in the registers. r7 is 128. r14 is 4. r15 is ONES. They are written again on every rise. |
| Fetch | Reading a new instruction out of memory each cycle. This chip does not. |
| Tile | The 8×4 piece. 1724 by 711 µm. |
| Pad | One pin on that tile. `ui` in, `uo` out, `uio` either way. |
| Cell | One map, one hold, one byte. |
| Crossing | A hold from one map used on another map. The same shifter. No new block. |
| Nibble | Four bits. `uo[7:4]` is one nibble. |
| Both edges | Count 1. The bit moves on the rise and on the fall. 10 ns. 100 Mbit/s. |
| NRZ | The bit holds one level for the whole hold. Not Manchester. |
| 8N1 | A start bit, eight data bits, one stop bit. No parity bit. |
| Open-drain | The pin can pull low or let go. It does not drive high. I2C and PS/2. |
| BUSY | `uo[1]`. High while the selected walk is running. |
| GOT | `uo[3]`. High when a byte has come in. |
| MOSI | SPI data out of this chip. `uo[4]`. |
| MISO | SPI data in. `ui[2]`. |
| SCLK | SPI clock. `uo[5]`. |
| CS | SPI select, active low. `uo[6]`. |
| SCL | I2C clock. `uo[4]`. |
| SDA | I2C data. `uio[0]`. |
| Manchester | A bit coded as a mid-bit edge, on `uo[0]` and `uo[7]`. |
| NRZI | A bit coded as a change or no change. The USB cell. |

## What it does

The clock is 50 MHz. One cycle is 20 ns.

`ui[0]` sits low. Raise it for one cycle, then let it fall. That cycle is the whole of what this page calls FIRE. The byte is already on `uio[7:0]`. On that cycle all 32 bases take it. Base 0 gets the byte. Base 1 gets the byte plus 1. Base 31 gets the byte plus 31.

Every cycle, whether or not `ui[0]` is high, each base adds 1 to its count and 128 to its stride. 32 bases on every cycle is the 1.6 GB/s. Two SRAM macros behind the bases each hold a cycle. The one-cycle rise keeps the new one and the one before it, and the read is the difference. Two in front hold the list. A register holds the map, the count, and the byte. The clock holds the stage while the tile is enabled.

## Programmable

Jane Street asked for one chip that can be used for more than one thing after it is fabricated. This one is. The register is the program. No separate file is sent.

The loads are the CPU, UART, SPI, I2C, and, on the hook, the memory, JTAG, Manchester, SWD, PS/2, a USB low-speed bit cell, and a CAN bit cell. The register selects which load is on the pins. Until the register is stored, the pads select it.

| Way in | What it is |
|---|---|
| The register | Map, count, and byte. Raise `ui[0]` for one cycle on the memory pads. That stores them. After that the outputs follow the register. |
| CPU 1.1 | One clock cycle. Base *k* gets the byte plus *k*. |
| 512 and 720 | The same seat. r7 is 128. r14 is 4. `4 × 128 = 512`. The 720 reading is that number times `720 / 512`. |

| Field | Pins | Values |
|---|---|---|
| Byte | `uio[7:0]` | Any of 256. The 32 bases do not change with the coding. |
| Count | `ui[7:5]` | 1, 4, 5, 8, 16, 33, 125, or 434 clocks. |
| Map | `ui[4:3]` | Which pins carry the bit. The map table is below. |
| FIRE | `ui[0]` | The name of that one cycle. High for the cycle, low the cycle before. |

UART held for the I2C count is the same shifter on `uo[0]`. SPI at the 10 ns hold is the same shifter on MOSI and SCLK. No module is added for the crossing.

The byte is the load the bases take. An opcode from another machine is that same byte. The next section is the measured run.

## The byte

A byte is eight weights already on the processor: 1, 2, 4, 8, 16, 32, 64, 128. Each one is 2 of the one before it. The byte is the sum of the weights that are present. That is the load. There is no separate file.

An instruction on another machine is that byte. The opcode is the byte. The 1s in it are the weights, and those run on the one cycle `ui[0]` is high. The other machine's name for the byte is not a second operation. `90` is `10010000`, so the weights are 16 and 128, and the result is `104f0090`. `C3` is not a return. `B1` has no name. All three take the same cycle and the same 32 bases. A foreign opcode gets no special case.

Base 0 stores the byte. Base 3 stores the byte plus 3. The result and the weight are what base 0 returned.

| Byte | Weights present | Result | Weight |
|---|---|---|---|
| `00` | none | `020a0000` | 1 |
| `01` | 1 | `020a0001` | 1 |
| `90` | 16 + 128 | `104f0090` | 8 |
| `C3` | 1 + 2 + 64 + 128 | `104f00c3` | 8 |
| `FF` | all eight | `104f00ff` | 8 |
| `1F` | 1 + 2 + 4 + 8 + 16 | `104f001f` | 8 |
| `E7` | 1 + 2 + 4 + 32 + 64 + 128 | `104f00e7` | 8 |
| `A3` | 1 + 2 + 32 + 128 | `104f00a3` | 8 |
| `5C` | 4 + 8 + 16 + 64 | `104f005c` | 8 |
| `B1` | 1 + 16 + 32 + 128 | `104f00b1` | 8 |

All 256 codes take that one cycle. Each one returns itself in the low byte. Two return weight 1: `00` is `020a0000`, `01` is `020a0001`. Seven return weight 2, and they are the single bits `02`, `04`, `08`, `10`, `20`, `40`, `80`, with the result `0414` and that byte. The other 247 return weight 8, with the result `104f` and that byte. The rows above are examples of that field, not the set.

113 machines were fired. A wider instruction was its bytes, one cycle each. 185 cycles. Every byte came back as itself. None missed.

| Machine | Bytes |
|---|---|
| x86 | `90` |
| x86-64 | `48` |
| 6502 | `A9` |
| 65C02 | `1A` |
| 65816 | `A9` |
| Z80 | `3E` |
| eZ80 | `40` |
| 8080 | `76` |
| 8085 | `76` |
| 8008 | `C0` |
| 4004 | `E0` |
| 1802 | `D4` |
| SC/MP | `90` |
| 6800 | `86` |
| 6809 | `86` |
| 68HC11 | `86` |
| 6805 | `A6` |
| 8051 | `E4` |
| STM8 | `72` |
| AVR | `0C` |
| SM83 | `3E` |
| HuC6280 | `03` |
| SPC700 | `8F` |
| Z8 | `8F` |
| Rabbit | `87` |
| PIC16 | `28 00` |
| MSP430 | `40 30` |
| H8 | `01 00` |
| SuperH | `00 09` |
| V850 | `40` |
| Blackfin | `00 00` |
| M32R | `70 00` |
| MicroBlaze | `80 00 00 00` |
| Nios II | `00 00 00 06` |
| Xtensa | `00 20 00` |
| ARC | `26 4A 23 00` |
| Hexagon | `00 C0 00 7F` |
| Thumb | `00 20` |
| ARM | `00 00 A0 E1` |
| ARM64 | `C0 03 5F D6` |
| RISC-V | `13 00 00 00` |
| RISC-V C | `01 00` |
| MIPS | `00 00 00 00` |
| MIPS16 | `65 00` |
| PowerPC | `7C 08 02 A6` |
| SPARC | `9D E3 BF A0` |
| Alpha | `00 00 FE 2F` |
| PA-RISC | `08 00 02 40` |
| System/360 | `1B` |
| z/Architecture | `07` |
| VAX | `04` |
| PDP-11 | `00 87` |
| PDP-8 | `74` |
| Itanium | `00 00 00 00` |
| OpenRISC | `15 00 00 00` |
| LoongArch | `00 00 00 04` |
| C-SKY | `00 00` |
| Andes | `00 00 00 45` |
| TMS9900 | `03 80` |
| NS32016 | `02` |
| Clipper | `00 00` |
| Transputer | `2F` |
| MMIX | `00 00 00 00` |
| Propeller | `00` |
| x87 | `D9` |
| MMX | `0F` |
| SSE | `0F` |
| AVX | `C5` |
| EVEX | `62` |
| JVM | `B1` |
| CIL | `00` |
| WASM | `0B` |
| DEX | `0E` |
| SPIR-V | `07 23 02 03` |
| LLVM | `42 43 C0 DE` |
| eBPF | `B7` |
| cBPF | `00` |
| Lua | `1B` |
| Python | `16` |
| BEAM | `46` |
| OCaml | `84` |
| CHIP-8 | `EE` |
| Uxn | `00` |
| Brainfuck | `2B` |
| Forth | `20` |
| PostScript | `25` |
| ELF | `7F` |
| PE | `4D` |
| Mach-O | `CF` |
| Mach-O 64 | `FE` |
| a.out | `07` |
| COFF | `4C` |
| XCOFF | `01` |
| Java | `CA` |
| FAT | `CA` |
| ZIP | `50` |
| gzip | `1F` |
| bzip2 | `42` |
| xz | `FD` |
| 7z | `37` |
| RAR | `52` |
| PNG | `89` |
| JPEG | `FF` |
| GIF | `47` |
| PDF | `25` |
| SQLite | `53` |
| FLAC | `66` |
| Ogg | `4F` |
| MP3 | `49` |
| MP4 | `66` |
| UTF-8 | `C3` |
| UTF-16 | `FF` |
| UTF-32 | `FF` |

The low byte of the result is the byte that went in. The list is not a whitelist. Any other set whose instructions are bytes is the same cycle.

## Functions

The walks are one use. These are the others. Same clock, same FIRE, same 32 bases.

| Function | How |
|---|---|
| Add | FIRE the byte. Base *k* returns that byte plus *k*. On the memory map the held word is added in pairs. `02 + 0A` returns `0C`. |
| Carry | FIRE `FF`. That base returns `104F00FF`. The next base returns `104F0100`. The low byte wraps from `FF` to `00`. |
| Multiply | Leave the clock running. The stride is 128 times the cycle. Cycle 4 is 512. |
| Divide | Set `ui[7:5]`. That hold divides the 50 MHz clock. Count `000` is 100 Mbit/s. Count `010` is 10 Mbit/s. Count `111` is 434 clocks. |
| AND | Raise `ui[5]` and `ui[6]` together. That is the 8-clock hold. Either pin alone is a different hold. |
| OR | Raise `ui[5]`, `ui[6]`, and `ui[7]` together. That is the 434-clock hold. On the byte, bit 0 or bit 1 returns `104F0003`. |
| XOR | FIRE one byte. The 32 results mix by XOR onto `uo[7:4]`. |
| Shift | Store the count in the register. Each bit of the frame on `uo[0]` is held for that count. |
| Compare | The low byte of the result is the byte you fired. `uo[2]` is high while r15 is `4F4E4553`. |
| Each clock | The cycle adds 1 and the stride adds 128. The next edge replaces that word. |

## Specification

| | |
|---|---|
| Clock | 50 MHz. Period 20 ns. One oscillator. |
| Bases | 32. Two stacks of 16. Base *k* takes byte + *k*. |
| Internal rate | 32 × 50 MHz = 1.6 GB/s, on the rising edge. |
| Word in | 8 bits, on that one clock cycle. Not a new byte every cycle. |
| Fetch | The register is the program. Each clock replaces the cycle and the stride. No separate file is sent. |
| Register | Map, 2 bits. Count, 3 bits, one of the eight holds. Byte, 8 bits. Not the SRAM. |
| Line | UART 8N1. Count 1 uses both edges: 10 ns, 100 Mbit/s. |
| Memory | Four `RM_IHPSG13_1P_512x32_c2_bm_bist`. Two behind the bases hold a cycle each and compare. Two in front hold the list, 1,024 cells. |
| Address on the pins | `uio[7:0]`, 256 of 512 words. Two words at that address. |
| Tile | 8×4. 1724 by 711 µm. |
| License | Apache-2.0 |

## How to use

1. Drive `rst_n` low. Hold `ui[7:0]` and `uio[7:0]` at 0. Release `rst_n`. The difference is 0. `uo[7:0]` reads `00000101` (`uo[7]` on the left): TX idle, ONES set.
2. Place the byte on `uio[7:0]`. Any of the 256 values.
3. Set the hold on `ui[7:5]`. One of the eight.
4. Set the map on `ui[4:3]`.
5. Pulse `ui[0]` for one clock. That FIRE runs the load the pads are showing.
6. To store it, set map `11`, count `000`, raise `ui[1]`, and FIRE. The register keeps the byte, the hold, and the map from the clock before that FIRE. Later FIREs follow the register. The pads can change. Reset clears the register.
7. Read `uo[7:0]`. `uo[1]` is high while the walk is busy. `uo[0]` is the NRZ output when the map is UART.

`ui[1]` held high keeps the clock on the stage. The tile enable does the same while the tile is selected.

## Pins

| Pin | Direction | Function | Use |
|---|---|---|---|
| `rst_n` | in | Reset, active low | Low, then high, with `ui` and `uio` at 0. Returns the stage to the ground. |
| `clk` | in | 50 MHz | The only time base. |
| `ena` | in | Tile enable | Holds the stage while the tile is selected. |
| `ui[0]` | in | FIRE | High for one clock cycle. All 32 bases take the byte on that cycle. The selected walk takes it too. |
| `ui[1]` | in | HOT | High holds the stage. With map `11`, count `000`, and FIRE, stores the register. |
| `ui[2]` | in | Line in | UART RX, SPI MISO, JTAG TDO, CAN RX. Idle high. Sampled on map `00`. |
| `ui[3]` | in | Map bit 0 | With `ui[4]`, selects the walk. |
| `ui[4]` | in | Map bit 1 | With `ui[3]`, selects the walk. |
| `ui[5]` | in | Count bit 0 | With `ui[7:6]`, selects the hold. |
| `ui[6]` | in | Count bit 1 | With `ui[7]` and `ui[5]`, selects the hold. |
| `ui[7]` | in | Count bit 2 | With `ui[6:5]`, selects the hold. |
| `uio[7:0]` | in | Byte, or address | The pattern on every map except memory. On map `11`, count `000`, this is the address. |
| `uio[0]` | inout | SDA / SWDIO / PS/2 data | Driven only while that walk owns it. Open-drain on I2C and PS/2. |
| `uio[1]` | inout | PS/2 clock | Driven only on the PS/2 slot. |
| `uo[0]` | out | TX | UART TX, Manchester, USB DM, or the CAN cell. Idle high on UART. |
| `uo[1]` | out | BUSY | High while the selected walk is running. |
| `uo[2]` | out | ONES | High when `r15` is `0x4F4E4553`. |
| `uo[3]` | out | GOT | High when a byte has been received, or while UART RX is busy. |
| `uo[4]` | out | MOSI / SCL / TDI / face 0 | Selected by the map. Face bit when no walk owns the pin. |
| `uo[5]` | out | SCLK / TCK / SWCLK / face 1 | Selected by the map. |
| `uo[6]` | out | CS / TMS / face 2 | Selected by the map. SPI CS is active low. |
| `uo[7]` | out | DP / face 3 | Manchester or USB DP, otherwise a face bit. |

## Count — `ui[7:5]`

The count is the number of clocks the bit is held. It is not owned by the protocol name in the right-hand column. Those names are the rate the hold matches. Map `00`, `01`, and `10` use the hold as bit time. Map `11` uses the same three bits to select the walk, except count `000`, which is the memory.

| `ui[7:5]` | Clocks | Edge | Bit time | Rate this hold matches |
|---|---|---|---|---|
| `000` | 1 | Both edges | 10 ns | 100 Mbit/s |
| `001` | 4 | Rising | 80 ns | |
| `010` | 5 | Rising | 100 ns | 10 Mbit/s |
| `011` | 8 | Rising | 160 ns | |
| `100` | 16 | Rising | 320 ns | |
| `101` | 33 | Rising | 660 ns | USB low-speed, about 1.5 Mbit/s |
| `110` | 125 | Rising | 2.5 µs | I2C 400 kHz |
| `111` | 434 | Rising | 8.68 µs | UART 115200 |

Count `000` writes one bit on the rising edge and the next bit on the falling edge. Every other count writes the bit on the rising edge and holds it. The falling edge is not a second bit.

## Map — `ui[4:3]`

The four values choose which pins move. They are not a limit on the byte or the count. Any of the 256 bytes at any of the eight holds is a mapping on that map.

| `ui[4:3]` | Walk | Output | Input |
|---|---|---|---|
| `00` | UART 8N1 | `uo[0]` TX. Start, eight data bits, LSB first, stop. | `ui[2]` RX |
| `01` | SPI mode 0, 8 bits | `uo[4]` MOSI, `uo[5]` SCLK, `uo[6]` CS | `ui[2]` MISO |
| `10` | I2C START, one byte, ACK, STOP | `uo[4]` SCL, driven | `uio[0]` SDA, open-drain |
| `11` | Selected by the count | See the next table | See the next table |

On map `11` the count selects the line.

| Count | Walk | Output |
|---|---|---|
| `000` | Memory | The two back macros hold a cycle each. `uo[7:0]` is the low byte of the second minus the first. |
| `001` | JTAG bit-bang | First FIRE stores TMS. Second FIRE clocks eight TDI bits. `uo[5]` TCK, `uo[6]` TMS, `uo[4]` TDI. `ui[2]` is TDO. |
| `010` | Manchester | `uo[0]`, `uo[7]`. |
| `011` | SWD | FIRE the request, FIRE the data byte. Header, turnaround, ACK, one data byte. `uo[5]` SWCLK, `uio[0]` SWDIO. |
| `100` | PS/2 device frame | 12.5 kHz. The half-bit is 4000 clocks, not the count-16 hold. Start, byte, odd parity, stop. `uio[1]` clock, `uio[0]` data. |
| `101` | USB low-speed NRZI | Bit cell on `uo[0]` and `uo[7]`. Not a USB stack. |
| `110` | CAN bit cell | Eight cells on `uo[0]`. Not a frame. `ui[2]` is RX. |
| `111` | USB NRZI at the UART hold | Bit cell. Not a USB stack. |

## Cells

A cell is any byte, any hold, and any map. That is 256 × 8 × 4. The ten rows are examples of that field, not the set. The output column is the pin waveform.

| | Map | Count | Byte | Output |
|---|---|---|---|---|
| 1 | `00` UART | 4 | `A5` | `uo[0]`, 8N1, NRZ. Each bit held 4 clocks, 80 ns. 12.5 Mbit/s. |
| 2 | `00` UART | 5 | `3C` | `uo[0]`, 8N1, NRZ. Bit time 100 ns. 10 Mbit/s. Not Manchester. |
| 3 | `00` UART | 33 | `55` | `uo[0]`, 8N1. Bit time 660 ns, the USB low-speed hold. |
| 4 | `01` SPI | 1 | `C3` | `uo[4]` MOSI, `uo[5]` SCLK, `uo[6]` CS. Mode 0 at the 10 ns hold. The byte completes. |
| 5 | `01` SPI | 125 | `96` | SPI mode 0 at the 2.5 µs hold. MSB remains on MOSI for that hold. |
| 6 | `01` SPI | 16 | `0F` | SPI mode 0. SCLK half-period is 16 clocks, 320 ns. |
| 7 | `10` I2C | 1 | `A0` | `uo[4]` SCL runs at the 10 ns hold, then releases. `uio[0]` SDA open-drain. |
| 8 | `10` I2C | 8 | `55` | SCL moves on the 8-clock hold, 160 ns. |
| 9 | `10` I2C | 33 | `42` | First SCL hold is 33 clocks, 660 ns. |
| 10 | `00` UART | 125 | `81` | `uo[0]`, 8N1. Start bit held 125 clocks, 2.5 µs. |

Crossing a count with a different map does not add a module. UART at the I2C hold is the same shift on `uo[0]`. SPI at count 1 is the same shift on MOSI and SCLK.

## Memory

Four macros. All four are clocked and written. None of them is full on every cycle.

The back pair is on only while the map is `11` and the count is `000`, or on the write cycle after FIRE. The address is the byte on `uio`. The top address bit is held at 0, so 256 of the 512 words are used. Both macros use that same address.

| Macro | Where | What it holds | What a read does |
|---|---|---|---|
| First | Behind the bases | The cycle that was already stored | Kept, so the next FIRE can move it |
| Second | Behind the bases | The cycle at this FIRE | Kept. The stride is not pulled back. |
| Third | In front | List cells 0 to 511 | The counter reads the cell and runs it |
| Fourth | In front | List cells 512 to 1,023 | Same list, the upper half |

FIRE on the back pair writes the new cycle into the second macro and moves the cycle that was there into the first. The compare is the second minus the first. `uo[7:0]` is the low byte of that difference. It is not sent into the 32 bases. While the address is held, base 0 takes the first cycle and base 1 takes the second. The other thirty take the byte plus their number. The clock is not set back to either cycle. The two numbers stay until that address is written again.

The front pair is on only while a cell is being stored or the list is running. One of the two is selected at a time: the lower macro for the first 512 cells, the upper for the next 512. A cell is 13 bits of the 32: the map, the count, and the byte. The other 19 bits are unused. `uio` at `FF` on a store starts the counter at the first cell. Each later FIRE runs the cell the counter is on. When that cell finishes, the counter adds 1.

What this covers, and what it does not:

| Spec | Where it lives |
|---|---|
| The 32 bases, the 1.6 GB/s, the walks | The logic. Not in these macros. |
| The 512 seat and the 720 reading | r7 and r14. Not in these macros. |
| A cycle you can come back to | The second macro keeps it. The clock is not set back to it. |
| The cycle before that one | The first macro. |
| The difference of those two cycles | The compare on `uo[7:0]`. Not sent into the 32 bases. |
| A stored order of map, count, and byte | The two front macros, 1,024 cells. |
| All 32 signatures | Not stored. The bases still fold them. Only the two cycles are kept. |
| All 512 addresses on the back pair | No. The pins name 256. |

UART, SPI, I2C, and the other walks keep their pins on the other maps. The register is not these macros.

## List

The list is the two front macros in the table above. The two behind it hold the two cycles.

## Processor

| Site | At reset | While the clock holds |
|---|---|---|
| r1 | 0 | Cycle + 1 on each rising edge |
| r2 | The lane | Stride + 128 on each rising edge |
| r4 | `0x020A0000` | Signature 0 of the FIRE word |
| r5 | 0 | Signature 1 of the FIRE word |
| r6 | 1 | Weight of the FIRE word |
| r7 | 128 | Held |
| r8 | 0 | Last received byte |
| r9 | 0 | Last FIRE word |
| r14 | 4 | Held |
| r15 | `0x4F4E4553` | ONES. `uo[2]` is high while this value holds |

r0, r3, and r10 through r13 stay 0. FIRE loads base *k* with byte + *k*. A finished RX byte is written to r8 of every base. The count does not change the face. A byte the design was not shown still folds. See "The byte."

`uo[4:7]` carries the face when no walk owns those pins. One rising edge is the low nibble. The next rising edge is the next four bits. 200 Mbit/s. The clock is not used as data.

## Seat

The 512 is already the preload. r7 is held at 128, the stack. r14 is held at 4. `4 × 128 = 512`. There is no second circuit.

A pin weight goes through that seat. `ui` is the minus side. `uio` is the plus side. The 512 column is the weight times r14. The 720 column is that same number times `720 / 512`. One weight is 4 and 5.625°. Weight 128 is 512 and 720°.

The stride is the counting ladder. Each rising edge adds r7, one rung. One rung is 4 on the 512 seat and 5.625° on the 720 reading. Four rising edges are four rungs: 16, and 22.5°.

Count 0 is 1°. Each count doubles the units and halves the degree. The stack reaches a count only when `2^count` is less than or equal to 128. Count 7 is 128 units, 0.0078125°. Count 8 is 256 units and is not reached.

| Count | Units | Degree of one unit |
|---|---|---|
| 0 | 1 | 1° |
| 1 | 2 | 0.5° |
| 7 | 128 | 0.0078125° |
| 10 | 1,024 | 0.0009765625° |
| 16 | 65,536 | 1/65536° |

## Ground

Reset, then one pin. Hold `rst_n` low with both bytes at 0. Release `rst_n`. Difference 0. `uo[7:0]` is `00000101`.

Raise one pin from that ground and leave the others at 0. The 512 and 720 columns are the seat. They are not a second output pin. `uo` is what that pin did on this die. `uo[7]` is the left-hand bit.

| Pin | Weight | Differential | 512 | 720 | `uo[7:0]` |
|---|---|---|---|---|---|
| none | 0 | 0 | 0 | 0 | `00000101` |
| `ui[0]` | 1 | −1 | −4 | −5.625° | `00001110` |
| `ui[1]` | 2 | −2 | −8 | −11.25° | `00001111` |
| `ui[2]` | 4 | −4 | −16 | −22.5° | `00001111` |
| `ui[3]` | 8 | −8 | −32 | −45° | `01001111` |
| `ui[4]` | 16 | −16 | −64 | −90° | `00010111` |
| `ui[5]` | 32 | −32 | −128 | −180° | `00001111` |
| `ui[6]` | 64 | −64 | −256 | −360° | `00001111` |
| `ui[7]` | 128 | −128 | −512 | −720° | `00001111` |
| `uio[0]` | 1 | +1 | 4 | 5.625° | `00001111` |
| `uio[1]` | 2 | +2 | 8 | 11.25° | `00001111` |
| `uio[2]` | 4 | +4 | 16 | 22.5° | `00001111` |
| `uio[3]` | 8 | +8 | 32 | 45° | `00001111` |
| `uio[4]` | 16 | +16 | 64 | 90° | `00001111` |
| `uio[5]` | 32 | +32 | 128 | 180° | `00001111` |
| `uio[6]` | 64 | +64 | 256 | 360° | `00001111` |
| `uio[7]` | 128 | +128 | 512 | 720° | `00001111` |

`uio` does not change `uo` from one bit to the next. Those eight pins sit at `00001111`. Reset before each pin.

`ui[3]` alone is `01001111`. `ui[4]` alone is `00010111`. Both in the same clock are `00000000`, which is not those two patterns added. Neither driven is the cycle, `00001111` then `00001101`.

## Verify

```
python3 test/sim_uart.py
cd test && make
```

## Submit

Public GitHub tree. `info.yaml` sets `tiles: "8x4"`, `top_module: tt_um_jlnuijens_one11_uart`, `clock_hz: 50000000`. Push to `main` runs test, docs, and GDS. The submission form takes this repository URL. Deadline 18 January 2027. Selected designs are planned for the March 2027 CMOS5L shuttle.

Pin-level detail is also in [docs/info.md](docs/info.md).
