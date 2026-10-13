![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# ONE CPU 1.1 32

Jane Street protocol-emulator ASIC. Tiny Tapeout, IHP CMOS5L, tile 6×4.

Joshua Luke Nuijens / Axiom 1 Technology, LLC. Top module `tt_um_jlnuijens_one11_uart`.

## Specification

| | |
|---|---|
| Clock | 50 MHz. Period 20 ns. One oscillator. |
| Bases | 32. Two stacks of 16. Base *k* takes byte + *k*. |
| Internal rate | 32 × 50 MHz = 1.6 GB/s, on the rising edge. |
| Word in | 8 bits, one FIRE. Not one byte per clock. |
| Fetch | None. The stage is loaded. The clock holds it while the tile is enabled. |
| Line | UART 8N1. Count 1 uses both edges: 10 ns, 100 Mbit/s. |
| Memory | Four `RM_IHPSG13_1P_512x32_c2_bm_bist`. 512 × 32, one port. 8 KB. |
| Address on the pins | `uio[7:0]`, 256 of 512 words. Four words at that address. |
| Tile | 6×4. The 8×4 template is not in this flow. |
| License | Apache-2.0 |

Jane Street asked for a design that can be pointed at a new protocol after fabrication, within the timing and the pins, rather than a UART block plus an SPI block plus an I2C block. The RP2040 PIO was the reference. This die does not load a program. The pins are the configuration. The same clock, the same FIRE, and the same 32 bases produce the cell.

## How to use

1. Drive `rst_n` low. Hold `ui[7:0]` and `uio[7:0]` at 0. Release `rst_n`. The difference is 0. `uo[7:0]` reads `00000101` (`uo[7]` on the left): TX idle, ONES set.
2. Place the byte on `uio[7:0]`. Any of the 256 values. The sites do not change with the value.
3. Set the hold on `ui[7:5]`. Eight values. This is the bit time, not a stored mode.
4. Set the map on `ui[4:3]`. This selects which pins carry that bit.
5. Pulse `ui[0]` high for one clock, then low. That rising edge is FIRE. One walk runs. The walks that were not selected hold.
6. Read `uo[7:0]`. `uo[1]` is high while the walk is busy. `uo[0]` is the NRZ output when the map is UART.

`ui[1]` held high keeps the clock on the stage. The tile enable does the same while the tile is selected.

## Pins

| Pin | Direction | Function | Use |
|---|---|---|---|
| `rst_n` | in | Reset, active low | Low, then high, with `ui` and `uio` at 0. Returns the stage to the ground. |
| `clk` | in | 50 MHz | The only time base. |
| `ena` | in | Tile enable | Holds the stage while the tile is selected. |
| `ui[0]` | in | FIRE | Rising edge. One operation for all 32 bases and for the selected walk. |
| `ui[1]` | in | HOT | High holds the stage. |
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

| `ui[4:3]` | Walk | Output | Input |
|---|---|---|---|
| `00` | UART 8N1 | `uo[0]` TX. Start, eight data bits, LSB first, stop. | `ui[2]` RX |
| `01` | SPI mode 0, 8 bits | `uo[4]` MOSI, `uo[5]` SCLK, `uo[6]` CS | `ui[2]` MISO |
| `10` | I2C START, one byte, ACK, STOP | `uo[4]` SCL, driven | `uio[0]` SDA, open-drain |
| `11` | Selected by the count | See the next table | See the next table |

On map `11` the count selects the line.

| Count | Walk | Output |
|---|---|---|
| `000` | Memory | `uo[7:0]` is the low byte of the word at the address on `uio[7:0]`. |
| `001` | JTAG bit-bang | First FIRE stores TMS. Second FIRE clocks eight TDI bits. `uo[5]` TCK, `uo[6]` TMS, `uo[4]` TDI. `ui[2]` is TDO. |
| `010` | Manchester | `uo[0]`, `uo[7]`. |
| `011` | SWD | FIRE the request, FIRE the data byte. Header, turnaround, ACK, one data byte. `uo[5]` SWCLK, `uio[0]` SWDIO. |
| `100` | PS/2 device frame | 12.5 kHz. The half-bit is 4000 clocks, not the count-16 hold. Start, byte, odd parity, stop. `uio[1]` clock, `uio[0]` data. |
| `101` | USB low-speed NRZI | Bit cell on `uo[0]` and `uo[7]`. Not a USB stack. |
| `110` | CAN bit cell | Eight cells on `uo[0]`. Not a frame. `ui[2]` is RX. |
| `111` | USB NRZI at the UART hold | Bit cell. Not a USB stack. |

## Cells

A cell is one byte, one hold, and one map. The output column is the pin waveform. These ten were simulated on this die.

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

Map `11`, count `000`. `uio[7:0]` is the address. The upper address bit stays 0, so the pins reach 256 of the 512 words. All four macros use that address.

| Operation | Result |
|---|---|
| Read | Bases 0 through 3 each take the word from their own macro. `uo[7:0]` is the low byte of the first word. |
| Write | FIRE stores the four results at that address. |
| Hold | The words remain until that address is written again. |

UART, SPI, I2C, and the other walks keep their pins on the other maps.

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

r0, r3, and r10 through r13 stay 0. FIRE loads base *k* with byte + *k*. A finished RX byte is written to r8 of every base. The count does not change the face.

`uo[4:7]` carries the face when no walk owns those pins. One rising edge is the low nibble. The next rising edge is the next four bits. 200 Mbit/s. The clock is not used as data.

There is no fetch. A byte the design was not shown still folds. PE, ELF, Mach-O, DEX, WASM, UTF-8, and a GPU file are bytes. The list is not a whitelist.

## Pickup

The 512 track stays on the processor. The 720 track is the second output of the same intake. The stack is 128. The clock stays hot. The stack is a divisor, not an added term. An intake of 0 is an output of 0.

| Output | Definition | One intake |
|---|---|---|
| Squares | intake × 512 / 128 | 4 |
| Degrees | intake × 720 / 128 | 5.625° |
| Ratio | 720 / 512 | 1.40625 |

Intake is `uio[7:0]` minus `ui[7:0]`, the pin values taken as unsigned bytes. The same function runs on the vector, base 0 against base 16.

Count 0 is 1°. Each count doubles the units and halves the degree. The stack reaches a count only when `2^count` is less than or equal to 128. Count 7 is 128 units, 0.0078125°. Count 8 is 256 units and is not reached. The units inside a count are counted before the count advances. The map does not end at count 16.

| Count | Units | Degree of one unit |
|---|---|---|
| 0 | 1 | 1° |
| 1 | 2 | 0.5° |
| 7 | 128 | 0.0078125° |
| 10 | 1,024 | 0.0009765625° |
| 16 | 65,536 | 1/65536° |

## Ground

Reset, then one pin. Hold `rst_n` low with both bytes at 0. Release `rst_n`. Difference 0. `uo[7:0]` is `00000101`.

Raise one pin and leave the others at 0. That pin's weight is the whole intake. `ui` is the minus side. `uio` is the plus side. The same weight is the same seat. Weight 128 is 720°. Weight 64 is 360°. Weight 32 is 180°. Weight 16 is 90°. Weight 8 is 45°. Weight 4 is 22.5°. Weight 1 is 5.625°.

`uo[7]` is the left-hand bit. Measured from a separate reset on each row.

| Pin | Weight | Differential | 512 | 720 | `uo[7:0]` |
|---|---|---|---|---|---|
| none | 0 | 0 | 0 | 0 | `00000101` |
| `ui[0]` | 1 | −1 | −4 | −5.625° | `00000110` |
| `ui[1]` | 2 | −2 | −8 | −11.25° | `00000101` |
| `ui[2]` | 4 | −4 | −16 | −22.5° | `00000101` |
| `ui[3]` | 8 | −8 | −32 | −45° | `01000101` |
| `ui[4]` | 16 | −16 | −64 | −90° | `00010101` |
| `ui[5]` | 32 | −32 | −128 | −180° | `00000101` |
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

The `uio` rows share `00001111` because `ui[2]` is low, so the receiver leaves idle. Those eight rows do not differ from each other on `uo`. If the pins are left asserted together, the weights add. Reset is the operation that returns a single pin to its own seat.

## Verify

```
python3 test/sim_uart.py
cd test && make
```

## Submit

Public GitHub tree. `info.yaml` sets `tiles: "6x4"`, `top_module: tt_um_jlnuijens_one11_uart`, `clock_hz: 50000000`. Push to `main` runs test, docs, and GDS. The submission form takes this repository URL. Deadline 18 January 2027. Selected designs are planned for the March 2027 CMOS5L shuttle.

Pin-level detail is also in [docs/info.md](docs/info.md).
