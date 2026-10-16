# Implementation improvement — 13 October 2026

The selected implementation runs at **6.0 ns (166.67 MHz)** with positive setup
and hold slack and no slew, capacitance, fanout, DRC or LVS violations. The
structural multiplier RTL, reset, pipeline, 16 registers, 12 full adders,
16 partial-product ANDs and 150 × 150 µm die are preserved.

## Measured comparison

All slacks below are the worst reported across signoff corners, after detailed
routing and RC extraction. The original result is the artifact supplied in
the clone; the other results were generated locally in IIC 2026.09.

| Implementation | Period (ns) | Setup slack (ns) | Hold slack (ns) | Slew violations | Standard-cell area (µm²) | Wirelength (µm) |
|---|---:|---:|---:|---:|---:|---:|
| Original saved baseline | 6.5 | +0.041334 | +0.128645 | 11 | 1241.19 | 2334 |
| Fresh unchanged configuration | 6.5 | +0.079360 | +0.128163 | 0 | 1239.94 | 2446 |
| Repair settings | 6.5 | +0.148887 | +0.125929 | 0 | 1259.96 | 2456 |
| **Selected repair settings** | **6.0** | **+0.144724** | **+0.123630** | **0** | **1340.04** | **2494** |
| Repair settings, rejected | 5.5 | -0.071948 | See raw metrics | 0 | See raw metrics | See raw metrics |

Both DRC engines and LVS report zero errors for the three new passing runs.
The 5.5 ns run is rejected for setup even if its geometric/connectivity checks
pass. It is not used for active artifacts. This sweep establishes a better
implementation; it does not establish a global optimum.

Compared with the supplied baseline, the selected clock rate increases 8.33%,
and setup margin grows from 41 ps to 145 ps. The slack-derived frequency
estimate increases from 154.83 to 170.79 MHz (10.30%). That estimate is not a
separately verified operating point. The standard-cell area increases 7.96%
and wirelength 6.86%; the fixed die area is unchanged. This trades a modest
area increase for speed and margin. The standard-cell area metric includes
taps/repair cells and excludes fill; it is different from Part B's 740.7104 µm².

The fresh control also removes the historical slew violations and changes
slack, so the entire original-to-new improvement cannot be attributed to the
repair settings. At an identical 6.5 ns period in the current environment,
repair adds 69.53 ps setup margin over the control at a 1.61% standard-cell area
cost. Original physical-run logs/tool identity were not included in the clone;
the baseline control makes that uncertainty explicit.

## Physical changes

`pnr/config.json` adds these supported LibreLane controls:

```json
{
  "DEFAULT_CORNER": "max_ss_100C_1v60",
  "RUN_POST_GRT_DESIGN_REPAIR": true,
  "RUN_POST_GRT_RESIZER_TIMING": true,
  "DESIGN_REPAIR_MAX_SLEW_PCT": 40,
  "GRT_DESIGN_REPAIR_MAX_SLEW_PCT": 30,
  "PL_RESIZER_SETUP_SLACK_MARGIN": 0.2,
  "GRT_RESIZER_SETUP_SLACK_MARGIN": 0.2
}
```

These controls enable routed-parasitic repair and request additional timing
and transition margin. They do not waive checks or reduce analyzed corners.
The generic LibreLane interface delays remain at their default 20% of period
(1.3 ns for 6.5 ns, 1.2 ns for 6.0 ns). No custom timing exceptions were added.
The same-period control comparison avoids that interface-delay difference.
Part B's prescribed synthesis and Part C's TT timing analysis remain intact.

References: [LibreLane timing closure](https://librelane.readthedocs.io/en/latest/usage/timing_closure/index.html),
[configuration variables](https://librelane.readthedocs.io/en/latest/reference/step_config_vars.html),
[OpenROAD repair_design](https://openroad.readthedocs.io/en/latest/main/src/rsz/README.html).

## Verification changes

`tb/tb_mult.v` now releases reset and drives operands on falling edges, avoiding
an active-edge scheduling race. FAIL still prints the required summary, then
uses `$fatal(1, ...)` so automation receives a failure exit status.
`tb/tb_stream.v` checks all 256 inputs on consecutive cycles, pipeline drain,
asynchronous reset between edges while the output is nonzero, and the two-edge
7×9 example. `scripts/verify.sh` runs these against RTL, Part B gates and an
optional routed netlist. The deliberate bad sum equation still produces
95 mismatches and now returns nonzero. Simulations use functional cell models
with `UNIT_DELAY=#1`; extracted timing is checked by multi-corner STA, not SDF
simulation. Both exhaustive and streaming tests passed for the selected routed
netlist as well as RTL and the synthesized netlist.

## Tool compatibility and reproduction

Image: `hpretl/iic-osic-tools:2026.09`, digest
`sha256:b87b3f1af9ba72d9486466ea777cf4248e96e20d9dba76d67259bc185db3859c`.
LibreLane 3.1.0.dev3; OpenSTA 3.1.0 f89887b596; Yosys 0.69 9f75ca1f9;
OpenROAD 26Q3-2443-g50432012f; KLayout 0.30.12.

This image has a LibreLane/OpenSTA API mismatch: `sta::scenes` returns opaque
objects, while the flow assumes names. `scripts/fix-iic-sta-scenes.py` converts
objects to names using `sta::get_name`, retains objects for internal calls,
and converts names back for `sta::set_cmd_scene`. It preserves a `.dvd-original`
backup and is idempotent. This adapter changes API plumbing, not timing values
or constraints. It is required before running the full physical flow with
this image. From WSL (use `sg docker -c '…'` if your shell predates group setup):

```bash
docker exec -u 0 mult4_dvd_iic python3 \
  /foss/designs/mult4_dvd/scripts/fix-iic-sta-scenes.py
docker exec mult4_dvd_iic bash -lc \
  'cd /foss/designs/mult4_dvd && python3 -m librelane --manual-pdk --pdk-root /foss/pdks -j 4 --run-tag optimized_6p0 pnr/config.json'
docker exec mult4_dvd_iic bash -lc \
  'cd /foss/designs/mult4_dvd && bash scripts/verify.sh pnr/mult_array_routed.v'
```

`pnr/signoff/provenance.json` identifies the selected local run and SHA-256
hashes of the promoted artifacts. DRC/LVS reports and resolved configuration
are included in `pnr/signoff/`. Full ODB, SPEF, SDF, STA reports and flow logs
are preserved locally under `../experiments/physical-optimization/`:

- `control/pnr/runs/control_6p5`
- `repair/pnr/runs/repair_6p5` (initial attempts hit the API mismatch; resumed after fix)
- `repair-fast/pnr/runs/repair_6p0` — selected, full clean run after adapter
- `repair-5p5/pnr/runs/repair_5p5` — rejected for timing

The original artifacts remain in `pnr/baseline/`, and the original source/
README are also recoverable from Git HEAD `7b3e499`. No commit or push was made.
Submission waveform annotations, block diagram, zoomed layout screenshot and
`report/report.pdf` remain separate outstanding deliverables.
