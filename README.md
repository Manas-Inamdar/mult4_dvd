# Digital VLSI Assignment — 4-bit × 4-bit Array Multiplier

## 1. Introduction

This report documents Parts A and B of a Digital VLSI assignment: the design,
exhaustive functional verification, logic synthesis, and gate-level
verification of a 4-bit × 4-bit unsigned structural array multiplier. The
intended project flow is RTL design and verification, logic synthesis, static
timing analysis, and physical design. Timing and physical-design results
remain placeholders until those stages are independently rerun and verified.

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

Part C will be documented after static timing analysis is independently rerun
and verified. No Part C numerical result is claimed in this report.

## 5. Physical Design — Part D

Part D has not been performed as part of this report. Existing physical-design
artifacts are not used as Part D results here. A correct SKY130A physical-design
run will be documented only after it is explicitly authorized and verified.

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

```text
[QUESTION 2 TODO: Complete after the remaining assignment stages are verified.]
```

### Question 3

The percentage of total cell area occupied by flip-flops is:

```text
(400.384000 / 740.710400) × 100 ≈ 54.05%
```

The design has 8 bits of registered input (`a_reg` and `b_reg`) and 8 bits
of registered output (`p_reg`), for 16 flip-flops total. Because the
combinational multiplier is small, the fixed area of these registers forms a
large fraction of the total cell area.

### Questions 4–6

```text
[QUESTIONS 4–6 TODO: Complete after Parts C–D are independently verified.]
```

```text
[PART C/D TODO: Do not add timing or physical-design answers until those
stages are independently verified.]
```

## 7. Conclusion

The structural 4-bit × 4-bit unsigned multiplier has been rebuilt and
exhaustively verified over all 256 input combinations. The deliberate
full-adder error produced the required 95-vector failure result, the correct
equation was restored, and the final corrected simulation passed with zero
errors. Part B then produced a fresh 63-cell SKY130A mapped netlist and a
gate-level PASS over all 256 vectors. The 7 × 9 example and two-cycle
waveform behavior are documented.

The Part A waveform annotation and final block-diagram figure remain manual
evidence items. This report does not claim that the complete RTL-to-GDSII
flow is finished.
