# Tests — CPU 1.1 UART

cocotb + Icarus. GitHub Action `test` runs this Makefile.

```
cd test
make -B
python3 sim_uart.py
```

`PROJECT_SOURCES` must match `info.yaml` `source_files`:

```
project.v one_cpu11.v js_uart_fire.v
```

FIRE `0x55` must walk 8N1 on TX. FIRE `0x53` is the ONES low byte. `uo[2]` stays 1.
