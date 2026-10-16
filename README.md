# Digital VLSI Assignment — 4-bit × 4-bit Array Multiplier

## 1. Introduction

This report documents Parts A through D of a Digital VLSI assignment: the design,
exhaustive functional verification, logic synthesis, and gate-level
verification of a 4-bit × 4-bit unsigned structural array multiplier. The
intended project flow is RTL design and verification, logic synthesis, static
timing analysis, and physical design. The verified physical-design results are
documented in Section 5.

The team information already associated with this project is:

- Manas Inamdar — Roll No. 2023102052
- Soham Jahagirdar — Roll No. 2023102046

The RTL is simulated with Icarus Verilog inside the existing
`mult4_dvd_iic` Docker container. The project is mounted at
`/foss/designs/mult4_dvd` inside the container. GTKWave is available in the
same environment for waveform inspection.

## 2. Design and Verification — Part A

### 2.1 Design Architecture

The design accepts unsigned 4-bit operands `a` and `b` and produces an 8-bit
registered product `p`.

Each bit of `a` is ANDed with each bit of `b`, producing four rows of four
partial-product bits. This gives 4 × 4 = 16 RTL AND operations. The rows are
combined by three rows of four explicitly instantiated full adders, giving 12
full-adder instances. At RTL these are operations and module instances; they
are not claims about the eventual number of physical standard-cell gates.

The input operands are captured in `a_reg` and `b_reg`. The combinational
array operates on those registered operands, and `p_reg` stores the result.
Reset is asynchronous and active-low. With inputs presented between clock
edges, the input registers capture them on the first rising edge and the
output register updates on the second rising edge, giving the required
two-cycle architectural latency.

### 2.2 RTL Files

| File | Role |
|---|---|
| `rtl/full_adder.v` | Structural one-bit full adder with sum and carry outputs. |
| `rtl/mult_array.v` | Four-row partial-product array, three four-bit full-adder rows, and registered interface. |
| `tb/tb_mult.v` | Exhaustive 256-vector testbench, golden-value comparison, and VCD generation. |

The full adder implements:

```verilog
sum  = a ^ b ^ cin
cout = (a & b) | (a & cin) | (b & cin)
```

### 2.3 Structural Verification

The following properties were checked directly from the current source files.

| Property | Verified result |
|---|---|
| Input width | 4 bits for `a`, 4 bits for `b` |
| Output width | 8 bits for `p` |
| AND operations in `mult_array.v` | 16 |
| Full-adder instances | 12 |
| Multiplication operator in `mult_array.v` | 0 |
| Input registers | `a_reg[3:0]`, `b_reg[3:0]` present |
| Output register | `p_reg[7:0]` present |
| Reset | Asynchronous active-low `negedge rst_n` |
| Clock period | 10 ns (`forever #5 clk = ~clk`) |
| Test vectors | 256 combinations |
| VCD file | `mult.vcd` generated |

The testbench uses multiplication only to generate the golden reference
value with `expected = ai * bi`; the multiplier RTL contains no multiplication
operator.

### 2.4 Functional Verification

The testbench iterates over every value of `a` from 0 through 15 and every
value of `b` from 0 through 15. Therefore, 16 × 16 = 256 input combinations
are checked. Each result is compared against the expected product, and the
testbench emits exactly one final PASS or FAIL summary.

The correct RTL simulation produced:

```text
PASS: 256 vectors checked, 0 errors
```

The commands used inside the existing container were:

```bash
cd /foss/designs/mult4_dvd
/foss/tools/bin/iverilog -g2012 -Wall -s full_adder \
  -o /tmp/part_a_full_adder_check rtl/full_adder.v
/foss/tools/bin/iverilog -g2012 -Wall \
  -o /tmp/part_a_correct \
  tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
/foss/tools/bin/vvp /tmp/part_a_correct
```

The final corrected run generated `mult.vcd` in the project directory.

### 2.5 Deliberate Error Test

The assignment requires an intentional full-adder error. For this experiment,
the sum equation was temporarily changed from:

```verilog
assign sum = a ^ b ^ cin;
```

to:

```verilog
assign sum = a ^ b;
```

The corrupted version was compiled and run in a container temporary directory
so the project waveform was not overwritten:

```bash
cd /foss/designs/mult4_dvd
/foss/tools/bin/iverilog -g2012 -Wall \
  -o /tmp/part_a_error \
  tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
mkdir -p /tmp/part_a_error_run
cd /tmp/part_a_error_run
/foss/tools/bin/vvp /tmp/part_a_error
```

The actual result was:

```text
FAIL: 256 vectors checked, 95 errors
```

The correct `a ^ b ^ cin` equation was restored, and the corrected simulation
was run again with the PASS result shown above. The current reproducible fault test is in `../setup/verify-improvements.sh`;
its captured output is `../analysis/optimization-verification/error.log`.

### 2.6 Hand-Worked Example — A = 7, B = 9

For Manas Inamdar (roll 2023102052), the last digit is 2, giving A = 7
and the specified exception B = 9:

```text
A = 7 = 0111
B = 9 = 1001
```

The bits of `B` generate the following aligned rows:

- `b[0] = 1` generates `00000111`.
- `b[1] = 0` generates `00000000`.
- `b[2] = 0` generates `00000000`.
- `b[3] = 1` generates `00111000`.

Therefore:

```text
        00000111
        00000000
        00000000
        00111000
        --------
        00111111
```

Thus:

```text
7 × 9 = 63 = 00111111
```

This matches the RTL wiring: `pp0` and `pp3` contain `0111`, while `pp1` and
`pp2` are zero. The three four-bit full-adder rows combine the shifted rows;
the final product concatenation is
`{carry3[4], sum3[3:0], sum2[0], sum1[0], pp0[0]}`.

### 2.7 Waveform Verification

The correct simulation generated `mult.vcd`. Its top-level waveform contains
`clk`, `rst_n`, `a`, `b`, and `p`; the dump also contains `a_reg`, `b_reg`,
`p_reg`, partial products, carries, sums, and full-adder signals.

The historical `A=7`, `B=9` transaction showed approximately
(the updated testbench drives on falling edges, so regenerate the figure):

```text
input assignment  = 2437 ns
first rising edge  = 2445 ns
second rising edge = 2455 ns
p = 63 (0x3F)     = 2455 ns
```

This demonstrates the required two-rising-edge latency.

```text
[PART A FIGURE TODO: Insert the student-captured GTKWave screenshot with
the two-cycle latency marked. The old clone does not include this figure;
regenerate it from the current testbench waveform.]
```

### 2.8 Block Diagram

The required architectural diagram should show:

```text
              +-------------+
A[3:0] ------>| A register  |---+
              +-------------+   |
                                v
                         16 AND operations
                         / partial products
                                |
                                v
                         12-full-adder array
                                |
                                v
              +-------------+  |
B[3:0] ------>| B register  |--+
              +-------------+

                         +-------------+
                         | P register  |----> P[7:0]
                         +-------------+

Clock connects to the input and output registers. `rst_n` is an
asynchronous active-low reset for all registers.
```

```text
[PART A FIGURE TODO: Insert a clean block diagram of the multiplier
architecture. The final diagram will be prepared manually by the student.]
```

## 3. Synthesis — Part B

Part B was rerun from the current Part A RTL using Yosys and the required
SKY130A high-density standard-cell library. The container defaults to the
IHP SG13G2 PDK, so the synthesis command explicitly selects SKY130A without
changing the container's global environment.

### 3.1 Synthesis Environment and Liberty

| Item | Value |
|---|---|
| Container | `mult4_dvd_iic` |
| Project path in container | `/foss/designs/mult4_dvd` |
| PDK root | `/foss/pdks` |
| PDK | `sky130A` |
| Standard-cell library | `sky130_fd_sc_hd` |
| Liberty | `/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib` |
| Standard-cell Verilog models | `/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/` |

### 3.2 Synthesis Flow and Commands

The rebuilt `synth/synth.tcl` follows the required sequence: read the RTL,
flatten the `mult_array` hierarchy, map flip-flops with `dfflibmap`, map
combinational logic with `abc`, remove unused logic, print Liberty-based
statistics, and write the mapped Verilog netlist.

The exact synthesis command was:

```bash
cd /foss/designs/mult4_dvd
env PDK_ROOT=/foss/pdks PDK=sky130A STD_CELL_LIBRARY=sky130_fd_sc_hd \
  /foss/tools/bin/yosys -c synth/synth.tcl \
  2>&1 | tee synth/part_b_synthesis.log
```

The generated artifacts are `synth/mult_array_netlist.v` and
`synth/mult_array_stat.rpt`. Reproduction logs on this machine are under
`../analysis/docker-verification/synthesis/`.

### 3.3 Fresh Synthesis Results

The following values come from the regenerated `synth/mult_array_stat.rpt`:

| Metric | Value |
|---|---:|
| Total synthesized cells | 63 cells |
| Flip-flops | 16 cells |
| Logic/combinational cells | 47 cells |
| Total cell area | 740.710400 µm² |
| Sequential area | 400.384000 µm² |
| Sequential area percentage | 54.05% |
| Gate-level vectors checked | 256 |
| Gate-level errors | 0 |
| Most-used cell | `dfrtp_1`: 16 |
| Second most-used cell | `nand2_1`: 8 |
| Third most-used cell | `a21oi_1`: 6 |

The 16 sequential bits are the four bits of `a_reg`, four bits of `b_reg`,
and eight bits of `p_reg`. The logic-cell count is `63 − 16 = 47`, which is
the value used in the Question 1 answer in Section 6. The sequential-area
percentage, 54.05%, is used in the Question 3 answer in Section 6.

Because the synthesis flow uses `synth -flatten`, the twelve RTL
`full_adder` instances are absorbed into the top-level logic. The generated
netlist contains only the top module `mult_array`, with no remaining
`full_adder` hierarchy. The mapped total of 63 cells includes the 16 mapped
flip-flops and 47 combinational standard cells.

### 3.4 Gate-Level Simulation

The fresh netlist was simulated with the current exhaustive testbench and the
SKY130A standard-cell models. The run used a separate temporary directory so
that the Part A `mult.vcd` was not overwritten.

The exact compile and run commands were:

```bash
cd /foss/designs/mult4_dvd
rm -rf /tmp/part_b_gate_run
mkdir -p /tmp/part_b_gate_run
/foss/tools/bin/iverilog -g2012 -Wall -DFUNCTIONAL '-DUNIT_DELAY=#1' \
  -o /tmp/part_b_gate_sim \
  tb/tb_mult.v synth/mult_array_netlist.v \
  /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v \
  /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v \
  2>&1 | tee synth/part_b_gate_compile.log
cd /tmp/part_b_gate_run
/foss/tools/bin/vvp /tmp/part_b_gate_sim \
  2>&1 | tee /foss/designs/mult4_dvd/synth/part_b_gate_sim.log
```

The actual result was:

```text
PASS: 256 vectors checked, 0 errors
```

No extra settling delay was required for this SKY130 functional-model run.
The standard-cell models produced compile-time timescale and timing-expression
warnings only; the testbench still observed the registered two-cycle
architectural behavior. Current gate-level evidence is under `../analysis/optimization-verification/`.

## 4. Timing — Part C

Part C was rerun with OpenSTA 3.1.0 using the fresh Part B SKY130A netlist and
the same SKY130 typical Liberty corner used for synthesis.

### 4.1 STA Environment

| Item | Value |
|---|---|
| Container | `mult4_dvd_iic` |
| Project path in container | `/foss/designs/mult4_dvd` |
| PDK root | `/foss/pdks` |
| PDK | `sky130A` |
| Standard-cell library | `sky130_fd_sc_hd` |
| Liberty | `/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib` |
| Netlist | `synth/mult_array_netlist.v` |
| Clock port and input clock period | `clk`, 10.00 ns for the initial run |
| Input delays | 1.0 ns on all non-clock inputs |
| Output delay | 1.0 ns |

The netlist cross-check confirmed top module `mult_array`, ports matching
Part A, 16 mapped `dfrtp` flip-flops, active-low `RESET_B` connections, and
no preserved `full_adder` hierarchy.

### 4.2 STA Commands and Reports

The rebuilt `sta/sta.tcl` reads the Liberty, reads the mapped netlist, links
`mult_array`, creates `clk`, applies the input/output delays, reports worst
maximum slack, and writes detailed maximum-delay checks. The period and
report path are selected through environment variables so both required runs
use the same script.

The exact 10 ns command was:

```bash
cd /foss/designs/mult4_dvd
env PDK_ROOT=/foss/pdks PDK=sky130A STD_CELL_LIBRARY=sky130_fd_sc_hd \
  STA_PERIOD_NS=10.00 \
  STA_REPORT_PATH=sta/mult_array_timing_10ns.rpt \
  /foss/tools/bin/sta -exit sta/sta.tcl \
  2>&1 | tee sta/part_c_10ns.log
```

The fresh output was `worst slack max 7.41`, and the detailed 10 ns report
is preserved in `sta/mult_array_timing_10ns.rpt`.

Using that measured slack:

```text
T_min = 10.00 ns − 7.41 ns = 2.59 ns
F_max = 1000 / 2.59 ns = 386.10 MHz
```

The exact rounded-period command was:

```bash
cd /foss/designs/mult4_dvd
env PDK_ROOT=/foss/pdks PDK=sky130A STD_CELL_LIBRARY=sky130_fd_sc_hd \
  STA_PERIOD_NS=2.59 \
  STA_REPORT_PATH=sta/mult_array_timing.rpt \
  /foss/tools/bin/sta -exit sta/sta.tcl \
  2>&1 | tee sta/part_c_tmin.log
```

The final detailed report is `sta/mult_array_timing.rpt`.

### 4.3 Part C Results

| Metric | Value |
|---|---:|
| Worst slack at T = 10 ns | 7.410 ns |
| T_min | 2.590 ns |
| F_max | 386.10 MHz |
| Slack at T = T_min | Approximately 0 ns; OpenSTA summary `-0.00 ns`, detailed report `0.000 ns (VIOLATED)` because T_min was rounded to 2.59 ns |
| Critical-path start point | `_087_` (`sky130_fd_sc_hd__dfrtp_1`) |
| Critical-path end point | `_100_` (`sky130_fd_sc_hd__dfrtp_1`) |
| Number of cells on critical path | 10 standard-cell instances |
| Latency = 2 × T_min | 5.180 ns |
| Throughput | 386.10 million results/s |

The ordered path from the final report is:

```text
_087_  sky130_fd_sc_hd__dfrtp_1   launch flip-flop
_039_  sky130_fd_sc_hd__clkinv_1
_047_  sky130_fd_sc_hd__o311ai_0
_050_  sky130_fd_sc_hd__a21oi_1
_063_  sky130_fd_sc_hd__maj3_1
_064_  sky130_fd_sc_hd__xnor2_1
_073_  sky130_fd_sc_hd__maj3_1
_075_  sky130_fd_sc_hd__maj3_1
_079_  sky130_fd_sc_hd__xnor3_1
_100_  sky130_fd_sc_hd__dfrtp_1   capture flip-flop
```

The reported data arrival time is 2.457 ns. The path contains 10 standard-cell
instances including the launch and capture flip-flops, or 8 combinational
standard cells between the registers. The final run prints `-0.00` for worst
slack and the detailed report prints `0.000 ns (VIOLATED)`: this is the
rounding boundary caused by using 2.59 ns to two decimal places, not a
positive-slack result.

The approximately `2N = 8` full-adder-delay estimate for a 4-bit array is an
architectural comparison. The eight intervening cells above are technology-
mapped standard cells after flattening; they are not eight preserved
full-adder modules and their count must not be called a full-adder count.

## 5. Physical Design — Part D

The active implementation is the optimized RTL-based SKY130A run at **6.0 ns**.
Its configuration, metrics, GDS and routed netlist all come from the same run.
The original 6.5 ns configuration and results are preserved in `pnr/baseline/`.
See [OPTIMIZATION.md](OPTIMIZATION.md) for experiments, tradeoffs and provenance.

### 5.1 Configuration and constraints

The design still uses 16 partial-product AND operations, 12 explicit full adders,
16 register bits, asynchronous active-low reset, and two-edge latency. The die
remains 150 × 150 µm. No RTL or Part B/C artifacts were changed for optimization.
`pnr/config.json` enables repair after global routing and increases timing and
slew repair margins. It selects `max_ss_100C_1v60` as the default corner, retaining
multi-corner setup/hold checks. These are physical-flow changes.

The assignment's initial period remains `ceil(1.2 × 2.59 / 0.5) × 0.5 = 3.5 ns`.
The handover records the original default-flow sequence:

| Period (ns) | Historical setup slack (ns) |
|---:|---:|
| 3.5 | -2.029468 |
| 4.0 | -1.529468 |
| 4.5 | -1.028412 |
| 5.0 | -0.528412 |
| 5.5 | -0.145564 |
| 6.0 | -0.151290 |
| 6.5 | +0.041334 |

The earlier six failed-run logs were not included in the clone; those numbers
are historical README evidence. The new optimization sweep is separate and
has complete local flow outputs under `../experiments/physical-optimization/`.

### 5.2 Current results

| Metric | Optimized implementation |
|---|---:|
| Clock period | 6.0 ns |
| Clock rate / throughput after pipeline fill | 166.67 MHz / million results per second |
| Core area | 17,759.5 µm² |
| Die area | 22,500 µm² |
| Part B cells / area | 63 / 740.7104 µm² |
| Final setup slack | +0.144724 ns |
| Final hold slack | +0.123630 ns |
| Setup / hold violation count | 0 / 0 |
| Slew / capacitance / fanout violation count | 0 / 0 / 0 |
| Magic / KLayout DRC errors | 0 / 0 |
| LVS errors | 0 |
| Standard-cell area, including taps and repair cells, excluding fill | 1,340.04 µm² |
| Final cell instances, including physical support | 1,906 |
| Routed wirelength | 2,494 µm |
| Assignment's slack-derived post-route Fmax estimate | 170.79 MHz |

The frequency estimate is `1000 / (6.0 − 0.144724)`. The validated operating
point is 6.0 ns; the estimate is not a separately routed/verified clock period.
Part C uses the TT 25 °C, 1.8 V corner and ideal pre-layout interconnect. Physical
signoff also considers slow/fast corners, routed parasitics and clock-tree delay.
The 386.10 MHz Part C estimate and post-route result therefore differ in both
analysis conditions and implementation stage.

### 5.3 Reproduce and inspect

In the IIC 2026.09 container, apply the documented OpenSTA compatibility adapter
once, then run from `/foss/designs/mult4_dvd`:

```bash
python3 scripts/fix-iic-sta-scenes.py
python3 -m librelane --manual-pdk --pdk-root /foss/pdks \
  -j 4 --run-tag optimized_6p0 pnr/config.json
bash scripts/verify.sh pnr/mult_array_routed.v
```

The adapter may require container root when modifying the installed tool files;
see [OPTIMIZATION.md](OPTIMIZATION.md). It fixes scene-name API conversion and
does not alter constraints, timing arithmetic or checks.

`pnr/signoff/` contains DRC/LVS reports, the resolved configuration and SHA-256
provenance. `pics/part_d/klayout_whole_die.png` is the actual KLayout rendering
of the selected run. The zoomed student screenshot, annotated waveform,
block diagram and final `report/report.pdf` still need completion.

## 6. Answers to Questions 1–6

### Question 1

The mapped logic/combinational standard-cell count is:

```text
63 total synthesized cells − 16 flip-flops = 47 logic/combinational cells
```

The 16 AND operations and 12 full-adder instances describe the RTL
structure; they are not a direct count of technology-library cells. Synthesis
maps and optimizes their Boolean logic into SKY130 standard cells. A single
RTL full adder may use multiple cells, different operations may be merged or
optimized, and additional cells may implement the synthesized Boolean
functions. Therefore, 47 is the mapped logic-cell count, not a claim that the
original array contains 47 gates.

### Question 2

The critical path launches at `_087_` (`sky130_fd_sc_hd__dfrtp_1`) and
captures at `_100_` (`sky130_fd_sc_hd__dfrtp_1`). It contains 10 standard-cell
instances including the two flip-flops, with 8 combinational standard cells
between them and a reported data arrival time of 2.457 ns. The path is the
technology-mapped implementation of the flattened arithmetic logic. The
assignment's approximately `2N = 8` full-adder-delay estimate for `N = 4` is
conceptual and is not a claim that the path contains eight full-adder cells.

### Question 3

The percentage of total cell area occupied by flip-flops is:

```text
(400.384000 / 740.710400) × 100 ≈ 54.05%
```

The design has 8 bits of registered input (`a_reg` and `b_reg`) and 8 bits
of registered output (`p_reg`), for 16 flip-flops total. Because the
combinational multiplier is small, the fixed area of these registers forms a
large fraction of the total cell area.

### Question 4

The post-route frequency estimate is 170.79 MHz, versus 386.10 MHz in Part C.
The latter uses the typical corner and ideal interconnect; physical signoff
includes slower process/voltage/temperature corners, extracted wire RC and
clock-tree effects. Fill, decap and tap cells support the physical layout;
data buffers and clock buffers repair timing, transition and clock distribution.
These physical support cells are additional to the mapped Part B logic.

### Question 5

DRC checks whether the layout obeys the process design rules for spacing,
width, enclosure, connectivity, and related manufacturing constraints. LVS
compares the extracted layout netlist with the intended design netlist to
verify that the devices and connections match. Both must pass before
manufacture: DRC establishes that the geometry is manufacturable, while LVS
establishes that the manufactured geometry implements the intended circuit.

### Question 6

For the assignment's architectural scaling estimate at `N = 8`:

```text
AND operations       = N²       = 8² = 64
Full adders          = N(N − 1) = 8(8 − 1) = 56
Approx. critical path = 2N       = 2(8) = 16 full-adder delays
```

These are architectural scaling estimates from the structural-array formulas,
not measured post-synthesis or post-route standard-cell counts.

The optimized Part D implementation passes setup, hold, electrical checks,
Magic/KLayout DRC and LVS. RTL, synthesized-netlist and routed-netlist functional
tests pass all 256 inputs and consecutive-cycle/reset scenarios. The original
baseline remains available for comparison. Submission figures and the final
PDF remain outstanding.
