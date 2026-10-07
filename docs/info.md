# ONE CPU 1.1 32 · 1.6 GB/s

That is the UART. Thirty-two bases on one FIRE. 1.6 GB/s inside on the rise. The line is 100 Mbit/s. A finished read weighs the byte that came back against the byte that was fired. The bank keeps 1024 of each. The face holds the running count. HOT on the UART map replays the bank on the face.

## Pin layout

| Pad | UART | ONE CPU 1.1 32 · 1.6 GB/s |
|---|---|---|
| `ui[0]` | FIRE | same pulse, all 32 bases |
| `ui[1]` | HOT | clock holds the stage. On the UART map it also replays the bank |
| `ui[2]` | RX | finished byte lands in `r8` and in the bank |
| `ui[4:3]` | UART, SPI, I2C, stretch | `00` keeps the face on `uo[4:7]` |
| `ui[7:5]` | count 1, 4, 5, 8, 16, 33, 125, 434 | the hold. The clock stays 50 MHz |
| `uio[7:0]` | the byte | base *k* folds byte + *k*. Any byte |
| `uo[0]` | TX | low byte of that word |
| `uo[2]` | ONES | `r15` is `0x4F4E4553` |
| `uo[4:7]` | the face, or the walk | the running weigh, or the replay |

Not three protocol blocks. The map selects the walk. The byte is any word. The clock holds the stage while the tile is enabled. No fetch after fabrication.

## Bank

1024 bytes of what you fired. 1024 bytes of what came back. 2 KB. Flops. Write only when that byte finishes. No write, the pattern stays. Power off, it is gone. The weigh is the count of bits that differ, across the stretch, not only the last byte.

## Range

The clock is 50 MHz. One rise is the base, 20 ns. Count 1 uses both halves, 10 ns and 10 ns. Every larger count is that same rise, held. The three pins pick eight holds. Any other integer is the same mechanic. It is not on these three pins.

| sel | rises |
|---|---|
| 0 | 1 |
| 1 | 4 |
| 2 | 5 |
| 3 | 8 |
| 4 | 16 |
| 5 | 33 |
| 6 | 125 |
| 7 | 434 |

## Processor

32 bases, 16 sites. The rise adds 1 to the cycle and 128 to the stride. 1.6 GB/s. Any byte. Base k gets byte + k. r7 is 128, r14 is 4, r15 is ONES. No fetch.

The walks stay. UART, SPI, I2C, and hook 11. The bank does not replace them.
