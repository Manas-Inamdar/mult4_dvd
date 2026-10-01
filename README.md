# Digital VLSI Assignment: 4-bit Array Multiplier

## Team

- Manas Inamdar - Roll No. 2023102052
- Soham Jahagirdar - Roll No. 2023102046

This is a two-person team project approved by the instructor.

## Project

Design and verification of a 4-bit x 4-bit unsigned structural array multiplier producing an 8-bit registered product, followed by synthesis, static timing analysis, and RTL-to-GDSII physical design.

## Technology and Library

- Process: SkyWater SKY130, 130 nm
- Standard-cell library: sky130_fd_sc_hd
- Active PDK: sky130A

## Required Toolchain

- Icarus Verilog and GTKWave
- Yosys
- OpenSTA
- LibreLane
- OpenROAD
- KLayout
- Magic
- Netgen
- IIC-OSIC-TOOLS Docker environment

## Working Environment

EDA work is performed inside the IIC-OSIC-TOOLS container under `/foss/designs`.

## Repository

- Repository name: `mult4_dvd`
- GitHub owner: `Manas-Inamdar`
- Visibility: private

## Command History

Exact commands will be recorded here in the order they are actually run.

### Part A RTL verification

1. `iverilog -g2012 -s full_adder -o /tmp/full_adder_check rtl/full_adder.v`
2. `iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v`
3. `vvp sim`
	- Result: `PASS: 256 vectors checked, 0 errors`
	- Generated: `mult.vcd`
4. For the deliberate error test, temporarily changed `sum` in `rtl/full_adder.v` to `a ^ b`.
5. `iverilog -g2012 -o sim_error tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v`
6. `vvp sim_error`
	- Result: `FAIL: 256 vectors checked, 95 errors`
7. Restored `sum` to `a ^ b ^ cin`.
8. Repeated the required RTL simulation commands.
	- Result: `PASS: 256 vectors checked, 0 errors`
9. Structural checks performed:
	- counted 12 `full_adder` instances in `rtl/mult_array.v`;
	- checked that `rtl/mult_array.v` contains no `*` operator;
	- checked registered inputs/output and asynchronous active-low reset;
	- compiled with `iverilog -g2012 -Wall`.

### Part A evidence status

- RTL PASS output: captured in the terminal log.
- Deliberate-error FAIL output: captured in the terminal log.
- `mult.vcd`: generated locally for GTKWave inspection.
- Personal example: A = 7 and B = 9; hand calculation and waveform annotation require team review.
- Waveform screenshot: requires GTKWave inspection and team capture/review.
- Block diagram: requires team creation/review.

## Generated Results

Generated synthesis, timing, physical-design, waveform, and report files will be added only after the corresponding workflow stages produce them.
