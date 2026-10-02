set lib "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
if {[info exists ::env(STA_PERIOD_NS)]} {
    set T $::env(STA_PERIOD_NS)
} else {
    set T 10.00
}

if {[info exists ::env(STA_REPORT_PATH)]} {
    set report_path $::env(STA_REPORT_PATH)
} else {
    set report_path "sta/mult_array_timing.rpt"
}

read_liberty $lib
read_verilog synth/mult_array_netlist.v
link_design mult_array
create_clock -name clk -period $T [get_ports clk]
set_input_delay 1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]
set_output_delay 1.0 -clock clk [all_outputs]
report_worst_slack -max
report_checks -path_delay max -digits 3 > $report_path
