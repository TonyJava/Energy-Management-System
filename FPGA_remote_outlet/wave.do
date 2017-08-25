onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sys_tb/uut/state
add wave -noupdate /sys_tb/uut/inst_pwr
add wave -noupdate /sys_tb/uut/sum_inst_pwr
add wave -noupdate /sys_tb/uut/power_output_valid
add wave -noupdate -radix decimal /sys_tb/uut/count
add wave -noupdate /sys_tb/uut/plc_fsm/plc_state
add wave -noupdate /sys_tb/uut/plc_fsm/sda
add wave -noupdate /sys_tb/uut/plc_fsm/scl
add wave -noupdate /sys_tb/uut/plc_fsm/tx_pulse_past
add wave -noupdate /sys_tb/uut/plc_fsm/tx_interrupt_sig
add wave -noupdate /sys_tb/uut/plc_fsm/tx_pulse
add wave -noupdate /sys_tb/uut/plc_fsm/tx_pulse_count
add wave -noupdate -radix hexadecimal /sys_tb/uut/plc_fsm/power_to_tx
add wave -noupdate -radix hexadecimal /sys_tb/uut/plc_fsm/i2c_data_wr
add wave -noupdate /sys_tb/uut/plc_fsm/i2c_enable
add wave -noupdate /sys_tb/uut/plc_fsm/i2c_busy_sig
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4488789761 ps} 0} {{Cursor 2} {5000510000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 299
configure wave -valuecolwidth 198
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ms
update
WaveRestoreZoom {8966182364 ps} {10054411455 ps}
