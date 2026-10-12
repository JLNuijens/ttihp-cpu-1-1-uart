import {
  catches, degreeStep, degrees, differential, seat, squares, unitsOut,
} from "../src/lib/front.ts"

let fails = 0
function eq(name: string, got: number, want: number) {
  if (got !== want) {
    console.log("FAIL", name, got, want)
    fails += 1
  }
}

const one = differential(1, 0)
eq("seat squares", squares(one), 4)
eq("seat degrees", degrees(one), 5.625)
eq("ratio", squares(one) === 0 ? 0 : degrees(one) / squares(one), 720 / 512)
eq("no power", squares(0, 100000), 0)
eq("diff", differential(3, 5), -2)
eq("neg squares", squares(-2), -8)
eq("neg degrees", degrees(-2), -11.25)

eq("c0 units", unitsOut(0), 1)
eq("c0 deg", degreeStep(0), 1)
eq("c1 units", unitsOut(1), 2)
eq("c1 deg", degreeStep(1), 0.5)
eq("c7 units", unitsOut(7), 128)
eq("c7 deg", degreeStep(7), 0.0078125)
eq("c10 units", unitsOut(10), 1024)
eq("c10 deg", degreeStep(10), 0.0009765625)
eq("c16 units", unitsOut(16), 65536)
eq("c16 deg", degreeStep(16), 1 / 65536)
eq("catch 7", catches(128, 7) ? 1 : 0, 1)
eq("catch 8", catches(128, 8) ? 1 : 0, 0)

const s0 = seat(0)
const s1 = seat(1)
const s3 = seat(3)
eq("walk 0 count", s0.count, 0)
eq("walk 0 unit", s0.unit, 0)
eq("walk 1 count", s1.count, 1)
eq("walk 3 count", s3.count, 2)

if (fails === 0) console.log("PASS")
else {
  console.log("FAILS", fails)
  process.exit(1)
}
