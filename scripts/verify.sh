#!/usr/bin/env bash
# Run inside the IIC container. Optional argument: routed gate-level netlist.
set -euo pipefail
project="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
out="${VERIFY_OUTPUT_DIR:-/tmp/mult4-verification}"
cells=/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog
if [ "$#" -gt 0 ]; then
    routed_netlist=$(realpath "$1")
fi
mkdir -p "$out"
cd "$out"
for tb in tb_mult tb_stream; do
    iverilog -g2012 -s "$tb" -o "$tb.rtl.sim" "$project/tb/$tb.v" "$project/rtl/full_adder.v" "$project/rtl/mult_array.v"
    vvp "$tb.rtl.sim" | tee "$tb.rtl.log"
    iverilog -g2012 -DFUNCTIONAL '-DUNIT_DELAY=#1' -s "$tb" -o "$tb.gate.sim" "$project/tb/$tb.v" "$cells/primitives.v" "$cells/sky130_fd_sc_hd.v" "$project/synth/mult_array_netlist.v"
    vvp "$tb.gate.sim" | tee "$tb.gate.log"
    if [ "$#" -gt 0 ]; then
        iverilog -g2012 -DFUNCTIONAL '-DUNIT_DELAY=#1' -s "$tb" -o "$tb.routed.sim" "$project/tb/$tb.v" "$cells/primitives.v" "$cells/sky130_fd_sc_hd.v" "$routed_netlist"
        vvp "$tb.routed.sim" | tee "$tb.routed.log"
    fi
done
sed 's/a \^ b \^ cin/a ^ b/' "$project/rtl/full_adder.v" > full_adder_error.v
iverilog -g2012 -s tb_mult -o error.sim "$project/tb/tb_mult.v" full_adder_error.v "$project/rtl/mult_array.v"
if vvp error.sim > error.log 2>&1; then
    echo 'ERROR: deliberate arithmetic fault returned success' >&2
    exit 1
fi
grep -q '^FAIL: 256 vectors checked,' error.log
echo 'PASS: deliberate fault detected and returned a nonzero process status'
