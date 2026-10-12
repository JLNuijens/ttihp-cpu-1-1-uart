// Golden model. 512 is the processor track. 720 is the pickup.
// The stack does not add power. Intake 0 is output 0.

export const STACK = 128
export const TRACK = 512
export const PICKUP = 720

export function differential(inp: number, inn: number): number {
  return inp - inn
}

export function squares(intake: number, stack = STACK): number {
  return (intake * TRACK) / stack
}

export function degrees(intake: number, stack = STACK): number {
  return (intake * PICKUP) / stack
}

export function unitsOut(count: number): number {
  return 2 ** count
}

export function degreeStep(count: number): number {
  return 1 / unitsOut(count)
}

export function catches(stack: number, count: number): boolean {
  return stack >= unitsOut(count)
}

// Fill the units inside a count, then move up. There is no last count.
export function seat(walked: number): { count: number; unit: number } {
  let count = 0
  let left = walked
  while (left >= 2 ** count) {
    left -= 2 ** count
    count += 1
  }
  return { count, unit: left }
}
