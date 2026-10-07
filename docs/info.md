# ONE CPU 1.1 32 · 1.6 GB/s

That is the UART. Thirty-two bases on one FIRE. 1.6 GB/s inside on the rise. The line is 100 Mbit/s. A finished read weighs the byte that came back against the byte that was fired. The bank keeps 1024 of each. The face holds the running count. HOT on the UART map replays the bank on the face.

## Bank

1024 bytes of what you fired. 1024 bytes of what came back. Flops. Write only when that byte finishes. No write, the pattern stays. Power off, it is gone. The face holds the weigh across the stretch. `ui[1]` HOT, map still UART, replays it: the sent byte, then the received byte, then the next.

The count is the adjustable part. The clock stays 50 MHz. One rise is the base. The eight pin choices are 1, 4, 5, 8, 16, 33, 125, 434 rises. Any byte. The bank does not care what the byte was.

## Range

| sel | rises | What the wave is |
|---|---|---|
| 0 | 1 | both halves, 10 ns and 10 ns |
| 1 | 4 | four rises |
| 2 | 5 | five rises |
| 3 | 8 | eight rises |
| 4 | 16 | sixteen rises |
| 5 | 33 | thirty-three rises |
| 6 | 125 | one hundred twenty-five rises |
| 7 | 434 | four hundred thirty-four rises |

Any other integer is the same hold. These eight are the ones the three pins can pick.
