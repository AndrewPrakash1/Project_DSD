# Programs the Boolean Board over USB with the built bitstream.
# Usage: vivado -mode batch -source scripts/program.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
set bit [file join $root vivado wash_machine.runs impl_1 wash_top.bit]

open_hw_manager
connect_hw_server -allow_non_jtag
set targets [get_hw_targets -quiet]
if {[llength $targets] == 0} {
    puts "NO_BOARD: no JTAG target found - check the USB cable and board power"
    return
}
open_hw_target [lindex $targets 0]
set dev [lindex [get_hw_devices xc7s50*] 0]
current_hw_device $dev
set_property PROGRAM.FILE $bit $dev
program_hw_devices $dev
puts "PROGRAMMED: $dev"
close_hw_manager
