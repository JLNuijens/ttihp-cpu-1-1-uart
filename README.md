![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# CPU 1.1 UART

Jane Street protocol-emulator ASIC. Tiny Tapeout IHP CMOS5L, 6×4. Joshua Luke Nuijens / Axiom 1 Technology.

ONE CPU 1.1 32. The UART is that processor, not a block beside it. Thirty-two bases, same sites, same FIRE. The rise steps at 1.6 GB/s inside. The UART line is unchanged: 8N1, both edges at count 1, 100 Mbit/s. Layout used 40% of the tile. GDS built.

Jane Street asked for flexibility, not a UART block plus an SPI block plus an I2C block. This die does not take a new program after fabrication. The clock holds the stage while the tile is enabled. The map picks the walk: UART, SPI mode 0, I2C, USB low-speed bit, or 10 Mbit Manchester. The byte on the pads is any word. A different coding, including a GPU file, is another word on that same FIRE.

## Preloaded

Universal UART. The stage is already loaded.

## Available

Two ordinary machines. x86 and ARM64. Same preload.

- Windows PE — i386, x86-64, and Windows-on-ARM
- Mac Mach-O — x86-64 and ARM64
- Linux ELF
- WASM, Java class, Android DEX, UTF-8, and the other measured codings — same preload

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
