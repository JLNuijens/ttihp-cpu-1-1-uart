![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# ONE CPU 1.1 32 · 1.6 GB/s

Jane Street protocol-emulator ASIC. Tiny Tapeout IHP CMOS5L, 6×4. Joshua Luke Nuijens / Axiom 1 Technology.

That name is the UART. Thirty-two bases, same sites, same FIRE, same pads. The rise is 1.6 GB/s inside. The wire is 8N1, both edges at count 1, 100 Mbit/s. Layout used 40% of the tile. GDS built.

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
| `uo[4:7]` | SPI / I2C / stretch, or the face | the mix, four bits |

Jane Street asked for flexibility, not a UART block plus an SPI block plus an I2C block. This die does not take a new program after fabrication. The clock holds the stage while the tile is enabled. The map picks the walk: UART, SPI mode 0, I2C, or hook `11`. On hook `11` the count slot picks Manchester, a real JTAG bit-bang, a real SWD header, a PS/2 device frame at 12.5 kHz, USB low-speed, or a CAN bit cell. The byte on the pads is any word.

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
| `ui[0]` | FIRE (rising) |
| `ui[1]` | HOT |
| `ui[2]` | UART RX / SPI MISO |
| `ui[4:3]` | map: UART SPI I2C USB/ETH |
| `ui[7:5]` | range 1 / 4 / 5 / 8 / 16 / 33 / 125 / 434 |
| `uio[7:0]` | seq byte (I2C SDA on bit 0) |
| `uo[0]` | UART TX / USB DM / ETH |
| `uo[1]` | BUSY |
| `uo[2]` | ONES (`r15 == 0x4F4E4553`) |
| `uo[3]` | GOT |
| `uo[4]` | SPI MOSI / I2C SCL |
| `uo[5]` | SPI SCLK |
| `uo[6]` | SPI CS_n |
| `uo[7]` | USB DP / face |

## Sim

```
python3 test/sim_uart.py
cd test && make
```

`Range` is 1, 4, 5, 8, 16, 33, 125, 434. Count 1 is both edges, 100 Mbit/s. The rest are holds on the rising edge.

## License

Apache-2.0.
