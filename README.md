![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# CPU 1.1 UART

Jane Street protocol-emulator ASIC — Tiny Tapeout IHP CMOS5L, 6×4 tiles.

The clock is the stage. 50 MHz oscillator. Data is RX/TX, not the power. UART, SPI, and I2C are one FIRE walk. Stretch USB LS NRZI and 10 Mbit Manchester. Clock range is the count (1 = 50 Mbit). Sixteen 1.1-class bases. Preloaded. No fetch.

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

`Range` is 1, 4, 5, 8, 16, 33, 125, 434 clocks per bit. Identity is 1.

## License

Apache-2.0.
