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
`iic-osic-tools_xvnc` Docker container. The project is mounted at
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
was run again with the PASS result shown above. No permanent terminal log was
created; no log path is claimed here.

### 2.6 Hand-Worked Example — A = 7, B = 9

For the required personal example:

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

The inspected `A=7`, `B=9` transaction showed approximately:

```text
input assignment  = 2437 ns
first rising edge  = 2445 ns
second rising edge = 2455 ns
p = 63 (0x3F)     = 2455 ns
```

This demonstrates the required two-rising-edge latency.

```text
[PART A FIGURE TODO: Insert the student-captured GTKWave screenshot with
the two-cycle latency marked. A raw capture is currently available at
pics/part_a/gtkwave_pic.png; this is not the annotated final figure.]
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
| Container | `iic-osic-tools_xvnc` |
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
`synth/mult_array_stat.rpt`. The complete captured Yosys output is in
`synth/part_b_synthesis.log`.

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
/foss/tools/bin/iverilog -g2012 -Wall \
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
architectural behavior. The compile warnings are captured in
`synth/part_b_gate_compile.log`, and the gate-level result is captured in
`synth/part_b_gate_sim.log`.

## 4. Timing — Part C

Part C was rerun with OpenSTA 3.1.0 using the fresh Part B SKY130A netlist and
the same SKY130 typical Liberty corner used for synthesis.

### 4.1 STA Environment

| Item | Value |
|---|---|
| Container | `iic-osic-tools_xvnc` |
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

Part D was redone from the assignment PDF using LibreLane v3.1.0.dev3 in the
existing `iic-osic-tools_xvnc` container. The official runs use the two RTL
source files required by the PDF and do not modify the verified Part A, Part B,
or Part C source artifacts.

### 5.1 Existing PNR Audit

The pre-existing runs `pnr/runs/RUN_2026-10-02_01-52-11` and
`pnr/runs/RUN_2026-10-02_02-11-14` resolved to `ihp-sg13g2` with
`sg13g2_stdcell`, even though the assignment requires SKY130A. The earlier
`part_d_*` runs used the mapped Part B netlist and were also discarded because
the PDF requires RTL input files. None of those runs, metrics, GDS files, or
screenshots is used as official Part D evidence; all were retained for audit.

### 5.2 PNR Configuration

The corrected active configuration is `pnr/config.json`:

| Setting | Value |
|---|---|
| Design and RTL inputs | `mult_array`, `../rtl/full_adder.v`, `../rtl/mult_array.v` |
| PDK / standard-cell library | `sky130A` / `sky130_fd_sc_hd` |
| Clock port | `clk` |
| Floorplan sizing | Absolute, `DIE_AREA = [0, 0, 150, 150]` |
| Final clock period in the active config | `6.5 ns` (initial attempt was `3.5 ns`) |
| Liberty corner | `sky130_fd_sc_hd__tt_025C_1v80.lib` |

Part C measured `T_min = 2.590 ns`. The initial Part D period was computed as
`1.2 × 2.590 = 3.108 ns`, rounded up to the next 0.5 ns step, `3.5 ns`.
Every LibreLane invocation explicitly selected `PDK_ROOT=/foss/pdks`,
`PDK=sky130A`, and `STD_CELL_LIBRARY=sky130_fd_sc_hd`.

### 5.3 Clock-Period Attempts and Signoff

Each period was run from the same RTL configuration, advancing by exactly
0.5 ns after a setup failure. DRC is the pair of Magic and KLayout checks; LVS
is the Netgen result.

| Clock period | Setup WNS/slack (ns) | Max-slew count | DRC | LVS | Outcome |
|---:|---:|---:|---:|---:|---|
| 3.5 ns | -2.029468 | 11 | 0 | 0 | Setup failed |
| 4.0 ns | -1.529468 | 11 | 0 | 0 | Setup failed |
| 4.5 ns | -1.028412 | 11 | 0 | 0 | Setup failed |
| 5.0 ns | -0.528412 | 11 | 0 | 0 | Setup failed |
| 5.5 ns | -0.145564 | 11 | 0 | 0 | Setup failed |
| 6.0 ns | -0.151290 | 11 | 0 | 0 | Setup failed |
| **6.5 ns** | **+0.041334** | **11** | **0** | **0** | **PASS** |

All seven runs reached final GDS/signoff metrics before the deferred setup
checker determined the outcome; the first six were rejected for negative setup
slack and 6.5 ns was the first passing setup result.

The first successful RTL-based run is `pnr/runs/part_d_rtl_6p5`. Its final
worst setup slack is `0.041334 ns` at the slow-slow 100 °C corner, with zero
setup and hold violation counts. Magic DRC, KLayout DRC, and Netgen LVS all
report zero errors. The metrics retain a max-slew count of 11; this is outside
the PDF's stated success criteria and is reported here rather than hidden.

The same-run artifacts copied for review are:

- `pnr/metrics.json` — copied from `pnr/runs/part_d_rtl_6p5/final/metrics.json`.
- `pnr/mult_array.gds` — copied from `pnr/runs/part_d_rtl_6p5/final/gds/mult_array.gds`.

Both copies are non-empty and byte-for-byte identical to their source files.
The run directories remain local evidence and are not part of the final
artifact set.

### 5.4 Part D Results Table

| Metric | Value |
|---|---:|
| CLOCK_PERIOD used | 6.5 ns |
| Number of RTL-based runs needed | 7 |
| Core area | 17,759.5 µm² |
| Cells after synthesis (Part B) | 63 cells |
| Cells after place and route | 1,893 instances |
| Kinds of cells added | 1,301 decap, 257 fill, 245 tap, 22 buffers |
| Routed wirelength | 2,334 µm |
| Final setup slack | 0.041334 ns |
| Post-route F_max | 154.83 MHz |
| F_max from Part C | 386.10 MHz |
| DRC errors | 0 |
| LVS errors | 0 |

The final die area is 22,500 µm² (150 µm × 150 µm), and reported instance
utilization is 6.98887%.

### 5.5 Cell Count and Physical Support

Part B mapped 63 cells: 16 flip-flops and 47 logic cells. The final RTL-based
physical database contains 1,893 SKY130 standard-cell instances. The cell
frequency report identifies 1,301 decap cells, 257 fill cells, and 245 tap
cells. It also identifies 17 data timing-repair buffers, 3 clock buffers, and
2 clock-delay buffers, or 22 buffers total.

The RTL-based LibreLane mapping itself contains 16 sequential cells, 49
multi-input combinational cells, and 3 inverters before physical support is
counted. This small mapping difference from the independently verified Part B
count of 63 is a synthesis-flow mapping detail; the Part B result remains the
assignment's baseline for the comparison table.

Physical implementation adds support structures that are not represented by
the Part B mapped-cell total. Decaps provide local charge storage for power
integrity, fill cells satisfy layout density and continuity requirements, tap
cells tie wells and substrate to the supply rails, and buffers/clock buffers
repair fanout, transition, and clock-tree delay. The metrics' `fill_cell`
classification includes both decap and fill masters, so those categories are
reported from the cell-frequency report and must not be added to the total a
second time.

### 5.6 Post-Route Frequency and Part C Comparison

Using the PDF's required calculation and the final measured slack:

```text
F_max,post-route = 1000 / (6.5 ns − 0.041334 ns)
                 = 154.83 MHz
```

Part C reported `F_max = 386.10 MHz` from the pre-layout mapped-netlist STA.
The post-route value is lower because placement, routed metal, and extracted
resistance/capacitance add delay; clock and timing-repair buffers also add
physical implementation delay. The two values therefore measure different
stages of the flow.

### 5.7 KLayout Inspection

The final RTL-based SKY130A GDS was rendered and visually inspected. The
evidence views are:

- `pics/part_d/klayout_whole_die.png` — whole-die view from the final run's
  KLayout render.
- `pics/part_d/klayout_zoomed.png` — zoomed view derived from that same final
  KLayout render for detailed routing and cell inspection.

The images correspond to `pnr/runs/part_d_rtl_6p5/final/gds/mult_array.gds`; no
older IHP or mapped-netlist layout image is used.

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

The post-route maximum frequency is lower because placement, routed metal, and
extracted parasitic resistance and capacitance add delay that is absent from
the pre-layout Part C estimate: `154.83 MHz` after routing versus `386.10 MHz`
from Part C. The final physical database adds 1,301 decap cells for local
power storage, 257 fill cells for density and continuity, 245 tap cells for
well/substrate ties, 17 data timing-repair buffers, 3 clock buffers, and 2
clock-delay buffers for fanout, transition, skew, and clock-tree repair.

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

Part D is complete for the verified 6.5 ns RTL-based SKY130A run. The run directories
remain local evidence and are intentionally not included in the report's
artifact list.

## 7. Conclusion

The structural 4-bit × 4-bit unsigned multiplier has been rebuilt and
exhaustively verified over all 256 input combinations. The deliberate
full-adder error produced the required 95-vector failure result, the correct
equation was restored, and the final corrected simulation passed with zero
errors. Part B then produced a fresh 63-cell SKY130A mapped netlist and a
gate-level PASS over all 256 vectors. Part C measured 7.410 ns worst slack at
10.00 ns, a 2.590 ns minimum period, and 386.10 MHz maximum frequency. Part D
then completed the corrected RTL-based SKY130A physical-design run at 6.5 ns
with positive setup slack and zero Magic/KLayout DRC and LVS errors. The 7 × 9 example, two-cycle waveform
behavior, final GDS, and KLayout views are documented.

The Part A waveform annotation and final block-diagram figure remain manual
evidence items. The verified Part D run is complete; its generated run
directories and intermediate logs remain local evidence.
