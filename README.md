![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# ONE CPU 1.1 32 · 1.6 GB/s

Jane Street protocol-emulator ASIC. Tiny Tapeout IHP CMOS5L, 6×4. Joshua Luke Nuijens / Axiom 1 Technology.

That name is the UART. Thirty-two bases, same sites, same FIRE, same pads. The rise is 1.6 GB/s inside. The wire is 8N1, both edges at count 1, 100 Mbit/s. The GDS that passed had two. This one has four, so the die holds more words. Four `512×32` SRAM macros. 8 KB on the die. 256 addresses come out to the pins, and each address keeps four words. The address is the byte on the bidirectional pins. Read is the next input of bases 0 through 3. FIRE stores those four results, and they stay until written again. The 8×4 tile is not in the template yet, so this stays a 6×4.

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

Jane Street asked for flexibility, not a UART block plus an SPI block plus an I2C block. This die does not take a new program after fabrication. The clock holds the stage while the tile is enabled. The map picks the walk: UART, SPI mode 0, I2C, or hook `11`. On hook `11`, count 0 is the memory. The other count slots pick Manchester, a real JTAG bit-bang, a real SWD header, a PS/2 device frame at 12.5 kHz, USB low-speed, or a CAN bit cell. The byte on the pads is any word.

## Universal, and the range

Jane Street wrote that the goal is not a UART block plus an SPI block plus an I2C block. The chip should be reprogrammable enough to support new protocols after fabrication, within its timing and its pins. They named the RP2040 PIO as inspiration, and said to consider doing it differently.

This die does it differently. Nothing is loaded. The pins are the program. Same clock. Same FIRE. Same 32 bases. Set the pins, and the cell is different.

| Pin | What you change |
|---|---|
| `uio[7:0]` | the byte. Any of the 256. The sites do not change |
| `ui[7:5]` | how many clocks the bit is held. Eight counts |
| `ui[4:3]` | which pins that bit walks out on |

UART at the I2C hold is not a new chip. I2C at the USB count is not a new chip. SPI at the fast hold is not a new chip. It is the same die, with the pins set to something else.

The whole die is the one machine. There is not a fold on the side and a protocol engine beside it.

One oscillator, 50 MHz. That clock is the only time. FIRE is the rising edge of `ui[0]`. One edge. Nothing is fetched.

Three inputs are already on the pins when that edge arrives.

The byte is `uio[7:0]`. It is the pattern. The same edge loads it into the shift and into all 32 bases. Base *k* folds byte + *k*. UART sends it as start, the eight bits, stop. SPI shifts it, mode 0. I2C shifts it between START and STOP. Manchester, NRZI, JTAG, SWD, PS/2, and the CAN cell shift it too. Any of the 256 bytes. A named file format is just bytes. A byte with no name is the same shift.

The count is `ui[7:5]`. It is not a mode switch stored in a program. It is how many clocks this oscillator holds the bit.

| sel | clocks the bit is held | both edges or the rise |
|---|---|---|
| 0 | 1 | both edges. 10 ns. 100 Mbit/s |
| 1 | 4 | rise |
| 2 | 5 | rise. 10 Mbit/s |
| 3 | 8 | rise |
| 4 | 16 | rise |
| 5 | 33 | rise. USB low-speed |
| 6 | 125 | rise. I2C 400 kHz |
| 7 | 434 | rise. UART 115200 |

Count 1 writes a bit on the rise and the next bit on the fall. Every larger count writes the bit on the rise and holds it. The fall is not a new bit.

The map is `ui[4:3]`. It does not load a machine. It chooses which pins that same shift comes out of.

| map | the pins the byte walks out on |
|---|---|
| 00 | NRZ. `uo[0]` TX, `ui[2]` RX |
| 01 | SPI mode 0. MOSI, SCLK, CS |
| 10 | I2C. SCL driven, SDA open-drain |
| 11 | the count picks the line. 0 is the memory. 1 JTAG. 2 Manchester. 3 SWD. 4 PS/2. 5 and 7 NRZI. 6 a CAN bit cell |

The walks that were not selected do not get FIRE. They hold. One pulse, one walk, all 32 bases.

After fabrication you do not add a module and you do not fetch. You put a byte on `uio`, a count on `ui[7:5]`, a map on `ui[4:3]`, and you pulse FIRE. The cell that comes out is that byte, held for that many clocks, on those pins. The 32 bases fold the same byte on that same edge. ONES, the face, and the word the memory keeps are that fold. That is the protocol. It is the inputs. It is already on the die.

The count is not owned by the name next to it. Allnary is already the byte: any of the 256, same sites. Crossing a count with a different map is a different cell. These ten were run on this die.

| | map | count | byte | what came out |
|---|---|---|---|---|
| 1 | UART | 4 | `A5` | 8N1. Each bit held 4 clocks. 12.5 Mbit/s |
| 2 | UART | 5 | `3C` | 8N1 at the 10 Mbit count. NRZ, not Manchester |
| 3 | UART | 33 | `55` | 8N1 at the USB low-speed count |
| 4 | SPI | 1 | `C3` | SPI at the fast hold. The byte finished |
| 5 | SPI | 125 | `96` | SPI at the I2C hold. MSB stayed on MOSI |
| 6 | SPI | 16 | `0F` | SPI. SCLK half-period was 16 clocks |
| 7 | I2C | 1 | `A0` | I2C at the fast hold. SCL ran, then released |
| 8 | I2C | 8 | `55` | I2C. SCL moved on the count-8 hold |
| 9 | I2C | 33 | `42` | I2C. First SCL hold was 33 clocks |
| 10 | UART | 125 | `81` | 8N1. Start bit held 125 clocks, the I2C count |

## SRAM

Four copies of `RM_IHPSG13_1P_512x32_c2_bm_bist`. 512 words × 32 bits, one port. 2 KB each, 8 KB on the die. The two that passed precheck are still there. Two more sit beside them.

Map `11`, count `000`. Then `uio[7:0]` is the address, not the byte. That is 256 of the 512 words. All four macros sit on the same address.

| | |
|---|---|
| Read | Base 0 through base 3 each take the word from their own memory. `uo[7:0]` is the low byte of the first word. |
| Write | FIRE stores each of those four results at that address. |
| Hold | Leave the address. The four words stay. Come back and they are the inputs again. |

UART, SPI, I2C, and the other walks keep their own pins. The memory only takes the pins on that one map.

## ONE CPU 1.1 32

| | |
|---|---|
| Bases | 32, 16 sites each |
| Step | rise. cycle +1, stride +128 |
| Inside | 1.6 GB/s |
| In | one byte per FIRE |
| Out | ONES on `uo[2]`. Four pins, eight bits of the mix, one nibble each rise, 200 Mbit/s |
| Pressed | r7 = 128, r14 = 4, r15 = `0x4F4E4553` |
| FIRE | r4 sig0, r5 sig1, r6 weight, r9 the word. Base k folds byte + k |
| RX | the finished byte lands in r8 |
| Fetch | none |

r0, r3, and r10–r13 stay 0. The full site table is in [docs/info.md](docs/info.md).

## Preloaded

Any word. Same sites. x86 and ARM64 are not the limit.

Windows PE, Mac Mach-O, Linux ELF, Android DEX, Java, WASM, UTF-8, and a GPU file all take the same FIRE. The list is not a whitelist. A byte the list does not name still folds.

Joshua Luke Nuijens / Axiom 1 Technology, LLC

- Docs: [docs/info.md](docs/info.md)
- Challenge: [Jane Street — Can you design a chip?](https://blog.janestreet.com/protocol-emulator-asic-competition/)
- Template: [TinyTapeout/ttihp-verilog-template @ cmos5l](https://github.com/TinyTapeout/ttihp-verilog-template/tree/cmos5l)

## This is the GitHub they take

Jane Street’s process is this tree, public, on GitHub:

1. `info.yaml` — `tiles: "6x4"`, `top_module: tt_um_jlnuijens_one11_uart`, `clock_hz: 50000000`
2. `src/` — `project.v`, `one_cpu11.v`, `js_uart_fire.v`, plus LibreLane `config.json` (20 ns = 50 MHz)
3. `test/` — cocotb + Icarus. GitHub Action `test` runs `make` in `test/`
4. `.github/workflows/gds.yaml` — `TinyTapeout/tt-gds-action@ihp-cmos5l` builds GDS

Push to `main`. Actions run. Enable **Settings → Pages → GitHub Actions** so the GDS viewer deploys.

Sign up for updates (not the tapeout): [Jane Street form](https://docs.google.com/forms/d/e/1FAIpQLSeF7fq756MegxZRQxotBwUJYZx-cL9MrGjxV0z4uD_J0sADxQ/viewform).

Final submit is a second form they add closer to **January 18, 2027**. Paste this repo URL. They clone it. Winners go on the March 2027 CMOS5L shuttle.

This is not a Quartus project. Quartus is the Nano / CPU 1.1 processor path.

## Pins

| pin | role |
|---|---|
| `ui[0]` | FIRE |
| `ui[1]` | HOT. The clock holds the stage |
| `ui[2]` | UART RX, SPI MISO, JTAG TDO, CAN RX. Idle high. UART watches it only on map `00` |
| `ui[4:3]` | `00` UART, `01` SPI, `10` I2C, `11` the other walks |
| `ui[7:5]` | count 1, 4, 5, 8, 16, 33, 125, 434. On hook `11`, count 0 is the memory. The other slots pick the walk |
| `uio[7:0]` | the byte |
| `uio[0]` | I2C SDA, SWDIO, or PS/2 data |
| `uio[1]` | PS/2 clock |
| `uo[0]` | UART TX, Manchester or USB DM, CAN bit |
| `uo[1]` | BUSY |
| `uo[2]` | ONES. `r15` is `0x4F4E4553` |
| `uo[3]` | GOT |
| `uo[4]` | SPI MOSI, I2C SCL, JTAG TDI, or face bit 0 |
| `uo[5]` | SPI SCLK, JTAG TCK, SWCLK, or face bit 1 |
| `uo[6]` | SPI CS, JTAG TMS, or face bit 2 |
| `uo[7]` | Manchester or USB DP, or face bit 3 |

The site table, the hook slots, and the walks are in [docs/info.md](docs/info.md).

## Sim

```
python3 test/sim_uart.py
cd test && make
```

`Range` is 1, 4, 5, 8, 16, 33, 125, 434. Count 1 is both edges, 100 Mbit/s. The rest are holds on the rising edge.

## License

Apache-2.0.
