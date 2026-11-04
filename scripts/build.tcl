# Creates the Vivado project, runs the simulation, then builds the bitstream.
# Usage: vivado -mode batch -source scripts/build.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
set proj_dir [file join $root vivado]

create_project wash_machine $proj_dir -part xc7s50csga324-1 -force

add_files [glob [file join $root rtl *.v]]
add_files -fileset constrs_1 [file join $root constraints boolean.xdc]
add_files -fileset sim_1 [file join $root sim tb_wash_fsm.v]

set_property top wash_top [get_filesets sources_1]
set_property top tb_wash_fsm [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "===== SIMULATION ====="
launch_simulation -simset sim_1 -mode behavioral
close_sim

puts "===== SYNTHESIS / IMPLEMENTATION / BITSTREAM ====="
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

open_run impl_1
report_utilization -file [file join $proj_dir utilization.rpt]
report_timing_summary -file [file join $proj_dir timing.rpt]
puts "WNS: [get_property SLACK [get_timing_paths]]"
puts "BITSTREAM: [glob -nocomplain [file join $proj_dir wash_machine.runs impl_1 *.bit]]"
