onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sys_tb/uut/i2c_addr
add wave -noupdate /sys_tb/uut/i2c_rw
add wave -noupdate /sys_tb/uut/i2c_data_wr
add wave -noupdate /sys_tb/uut/i2c_busy_sig
add wave -noupdate /sys_tb/uut/i2c_data_rd
add wave -noupdate /sys_tb/uut/i2c_ack_error
add wave -noupdate /sys_tb/uut/i2c_state
add wave -noupdate /sys_tb/uut/i2c_enable
add wave -noupdate /sys_tb/uut/sda
add wave -noupdate /sys_tb/uut/scl
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {30510000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {525 us}
