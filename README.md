# 4-bit Array Multiplier — RTL to GDSII (SKY130)

Digital VLSI Design assignment: a registered 4-bit × 4-bit unsigned array multiplier
(16 AND gates, 12 full adders, 16 flip-flops, 2-cycle latency), taken through RTL simulation,
Yosys synthesis, OpenSTA timing analysis and LibreLane place-and-route to a GDSII layout on
SkyWater SKY130 (`sky130_fd_sc_hd`). Results tables, figures and answers are in
[`report/report.pdf`](report/report.pdf).

## Team

| Name | Roll number |
|---|---|
| Manas Inamdar | 2023102052 |
| Soham Jahagirdar | 2023102046 |

## Results at a glance

| Part | Result |
|---|---|
| A — RTL | `PASS: 256 vectors checked, 0 errors`; error test (`sum = a ^ b`): `FAIL: 256 vectors checked, 95 errors` |
| B — Synthesis | 63 cells (16 × `dfrtp_1`), 740.7104 µm², flip-flops 54.05 %; gate-level simulation PASS |
| C — STA (tt corner) | WNS 7.41 ns at T = 10 ns → T<sub>min</sub> = 2.59 ns, F<sub>max</sub> = 386.10 MHz |
| D — Place & route | `CLOCK_PERIOD` 6.5 ns after 7 runs; setup slack +0.041 ns; post-route F<sub>max</sub> 154.83 MHz; 0 DRC, 0 LVS |

## Repository structure

```
mult4_dvd/
|-- README.md
|-- rtl/      full_adder.v, mult_array.v
|-- tb/       tb_mult.v
|-- synth/    synth.tcl, mult_array_netlist.v, mult_array_stat.rpt
|-- sta/      sta.tcl, mult_array_timing.rpt (T = Tmin = 2.59 ns)
|-- pnr/      config.json, metrics.json, mult_array.gds (copied from the final run)
`-- report/   report.pdf
```

## Tools

Everything runs in the IIC-OSIC-TOOLS Docker image, pinned to the release used for every
committed result:

| Item | Version |
|---|---|
| Image | `hpretl/iic-osic-tools:2026.09` (`sha256:b87b3f1af9ba72d9486466ea777cf4248e96e20d9dba76d67259bc185db3859c`) |
| Icarus Verilog | 14.0 (devel) s20260301-477-gd1982fc7 |
| Yosys | 0.69 (9f75ca1f9) |
| OpenSTA | 3.1.0 |
| LibreLane | 3.1.0.dev3, with its OpenROAD 26Q1-1024-gdcf36133a |
| KLayout / Magic / Netgen | 0.30.12 / 8.3.684 / 1.5.323 |
| PDK | `sky130A` at `/foss/pdks`, library `sky130_fd_sc_hd` |

A different image release can change cell choices, slack and wirelength slightly.

## Starting the container

On Windows, use Docker Desktop with WSL 2 integration enabled for Ubuntu; the commands below are
typed in the Ubuntu terminal. The repository is mounted at `/foss/designs/mult4_dvd`.

```sh
docker pull hpretl/iic-osic-tools:2026.09
docker run -d --name mult4_dvd_batch --user $(id -u):$(id -g) -e HOME=/headless \
  -v $HOME/DVD:/foss/designs --entrypoint sleep hpretl/iic-osic-tools:2026.09 infinity
docker exec -it mult4_dvd_batch bash -l
```

GUI tools (GTKWave, KLayout) can instead be used from the browser desktop started by the image's
`start_vnc.sh` (Section 4 of the assignment). Inside the container, in every new shell:

```sh
cd /foss/designs/mult4_dvd
export PDK_ROOT=/foss/pdks PDK=sky130A STD_CELL_LIBRARY=sky130_fd_sc_hd   # image default is another PDK
iverilog -V | head -1; yosys -V; sta -version; echo $PDK_ROOT $PDK
```

## Every command, in order

All commands run from `/foss/designs/mult4_dvd` inside the container unless stated otherwise.

### Part A — RTL design and verification

```sh
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
#   PASS: 256 vectors checked, 0 errors          (writes mult.vcd)
gtkwave mult.vcd                                  # A = 7, B = 9 is at 2450–2465 ns

# Task 6: error injection on a copy, so rtl/full_adder.v itself is never edited
sed 's/a \^ b \^ cin/a ^ b/' rtl/full_adder.v > /tmp/full_adder_bug.v
grep -n "assign sum" /tmp/full_adder_bug.v       # assign sum  = a ^ b;
iverilog -g2012 -o /tmp/sim_bug tb/tb_mult.v /tmp/full_adder_bug.v rtl/mult_array.v
vvp /tmp/sim_bug
#   MISMATCH: a=3 b=3 expected=9 actual=5   ... (95 MISMATCH lines)
#   FAIL: 256 vectors checked, 95 errors
#   FATAL: tb/tb_mult.v:70: Multiplier verification failed
vvp sim                                           # correct design: PASS again
```

The testbench releases reset and drives operands on falling clock edges, then checks `p` 2 ns
after the second rising edge. On FAIL it prints the summary line and then stops with `$fatal`, so
the process returns a non-zero exit status.

Example for task 5 (Manas Inamdar, roll 2023102052): last digit 2, so A = 2 + 5 = 7 and,
because A = 7, B = 9. 7 × 9 = 63; in the waveform the inputs are applied at 2450 ns, captured at
2455 ns (edge 1) and `p = 63` appears at 2465 ns (edge 2).

### Part B — Logic synthesis with Yosys

```sh
yosys -c synth/synth.tcl
#   writes synth/mult_array_stat.rpt (63 cells, 740.7104 µm², 54.05 % sequential)
#   and synth/mult_array_netlist.v

CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
#   PASS: 256 vectors checked, 0 errors
```

### Part C — Static timing analysis with OpenSTA

`sta/sta.tcl` takes the clock period from `STA_PERIOD_NS` (default 10.00 ns) and writes
`sta/mult_array_timing.rpt`; `-exit` returns to the shell when the script ends.

```sh
sta -exit sta/sta.tcl                       # T = 10 ns  -> worst slack max 7.41
#   Tmin = 10 - 7.41 = 2.59 ns, Fmax = 1000 / 2.59 = 386.10 MHz
STA_PERIOD_NS=2.59 sta -exit sta/sta.tcl    # T = Tmin   -> worst slack max -0.00
#   detailed report: slack 0.000 ns; rounding Tmin to 0.01 ns lands exactly on the boundary
#   (at 2.60 ns the slack is +0.01 ns). sta/mult_array_timing.rpt is this final 2.59 ns report.
```

### Part D — Physical design with LibreLane

Initial period: 1.2 × T<sub>min</sub> = 1.2 × 2.59 = 3.108 ns, rounded up to the next 0.5 ns =
**3.5 ns**. `pnr/config.json` contains only the required settings (plus `PDK` and
`STD_CELL_LIBRARY`). Each attempt sets the period, runs the flow, and on a setup failure adds 0.5 ns:

```sh
cd pnr
for T in 3.5 4.0 4.5 5.0 5.5 6.0 6.5; do
  sed -i "s/\"CLOCK_PERIOD\": [0-9.]*/\"CLOCK_PERIOD\": $T/" config.json
  librelane --run-tag run_$T config.json && break    # exits non-zero on setup violations
done
```

| Run | `CLOCK_PERIOD` (ns) | Setup slack, worst corner (ns) | Setup slack, tt corner (ns) | DRC (Magic / KLayout) | LVS | Result |
|---:|---:|---:|---:|:---:|---:|:---|
| 1 | 3.5 | −2.029468 | +0.587 | 0 / 0 | 0 | setup violation |
| 2 | 4.0 | −1.529468 | +1.087 | 0 / 0 | 0 | setup violation |
| 3 | 4.5 | −1.028412 | +1.588 | 0 / 0 | 0 | setup violation |
| 4 | 5.0 | −0.528412 | +2.088 | 0 / 0 | 0 | setup violation |
| 5 | 5.5 | −0.145564 | +2.542 | 0 / 0 | 0 | setup violation |
| 6 | 6.0 | −0.151290 | +2.887 | 0 / 0 | 0 | setup violation |
| 7 | **6.5** | **+0.041334** | +3.260 | 0 / 0 | 0 | **passed** |

Every failure is a setup violation in the slow `ss_100C_1v60` corner. The flow is deterministic:
re-running all seven periods in a fresh container reproduces these slacks exactly, and the 6.5 ns
GDS is geometrically identical (KLayout XOR) to the one from the first submission attempt.

Copy the final results and inspect them:

```sh
cp runs/run_6.5/final/metrics.json .
cp runs/run_6.5/final/gds/mult_array.gds .
python3 -c "
import json; m = json.load(open('metrics.json'))
for k in ['design__instance__count', 'design__core__area', 'route__wirelength', 'timing__setup__ws',
          'magic__drc_error__count', 'klayout__drc_error__count', 'design__lvs_error__count',
          'design__max_slew_violation__count']:
    print(f'{k:40s} {m[k]}')"
klayout mult_array.gds                             # whole die; zoom into the cell rows and wires
cd ..
```

Final run: setup slack +0.041 ns, hold slack +0.129 ns, post-route
F<sub>max</sub> = 1000 / (6.5 − 0.041) = 154.83 MHz, 1893 instances, core area 17,759.5 µm²,
wirelength 2334 µm, 0 DRC and 0 LVS errors. `metrics.json` also reports 11 max-slew violations
in the slow corner, all on the reset net (one buffer drives 10 `RESET_B` pins with a 0.778 ns
transition against a 0.75 ns limit). Reset recovery and removal still pass in that corner
(+4.01 ns and +0.97 ns), and slew is not one of the assignment's pass criteria
(0 DRC, 0 LVS, setup slack ≥ 0). `pnr/runs/` is not committed.
