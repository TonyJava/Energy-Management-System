onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sys_tb/uut/plc_fsm/tx_pulse_past
add wave -noupdate /sys_tb/uut/plc_fsm/tx_interrupt_sig
add wave -noupdate /sys_tb/uut/plc_fsm/tx_pulse
add wave -noupdate /sys_tb/uut/plc_fsm/tx_pulse_count
add wave -noupdate /sys_tb/uut/plc_fsm/tx_offset
add wave -noupdate /sys_tb/uut/plc_fsm/tx_threshold
add wave -noupdate /sys_tb/uut/plc_fsm/plc_state
add wave -noupdate /sys_tb/uut/plc_fsm/sda
add wave -noupdate /sys_tb/uut/plc_fsm/scl
add wave -noupdate -radix hexadecimal /sys_tb/uut/plc_fsm/i2c_data_wr
add wave -noupdate /sys_tb/uut/plc_fsm/i2c_enable
add wave -noupdate /sys_tb/uut/plc_fsm/i2c_busy_sig
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5006810000 ps} 0} {{Cursor 2} {10476516600 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 253
configure wave -valuecolwidth 185
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
WaveRestoreZoom {0 ps} {11271109500 ps}
