![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# CPU 1.1 UART

Jane Street protocol-emulator ASIC — Tiny Tapeout IHP CMOS5L, 6×4 tiles.

UART is FIRE on a pad. Byte on `uio`, pulse `ui[0]`, clock count walks 8N1 on `uo[0]`. Sixteen 1.1-class bases take that FIRE on the same edge. Preloaded. No fetch.

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
| `uio[7:0]` | seq byte |
| `uo[0]` | UART TX |
| `uo[1]` | BUSY |
| `uo[2]` | ONES (`r15 == 0x4F4E4553`) |

## Sim

```
python3 test/sim_uart.py
cd test && make
```

`CLKS_PER_BIT` is 8 in sim. Silicon at 50 MHz / 115200 ≈ 434.

## License

Apache-2.0.
