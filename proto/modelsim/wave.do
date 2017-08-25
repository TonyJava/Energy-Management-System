onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /wrapper_tb/uut/v_rms_inst/clk
add wave -noupdate /wrapper_tb/uut/v_rms_inst/rst_n
add wave -noupdate -radix unsigned /wrapper_tb/uut/v_rms_inst/count
add wave -noupdate /wrapper_tb/uut/v_rms_inst/rd_strb
add wave -noupdate /wrapper_tb/uut/v_rms_inst/rms_valid
add wave -noupdate -radix unsigned /wrapper_tb/uut/v_rms_inst/rms
add wave -noupdate /wrapper_tb/uut/v_rms_inst/state
add wave -noupdate -radix unsigned /wrapper_tb/uut/v_rms_inst/sum_data_count
add wave -noupdate -radix decimal /wrapper_tb/uut/v_rms_inst/rd_data
add wave -noupdate -radix decimal /wrapper_tb/uut/v_rms_inst/fifo_sum_reg
add wave -noupdate -radix decimal /wrapper_tb/uut/v_rms_inst/fifo_sum_divide_reg
add wave -noupdate -radix decimal /wrapper_tb/uut/v_rms_inst/sqrt_res_reg
add wave -noupdate /wrapper_tb/uut/v_zero_cross_inst/zero_crossing_dect
add wave -noupdate /wrapper_tb/uut/v_zero_cross_inst/clk
add wave -noupdate /wrapper_tb/uut/v_zero_cross_inst/rst_n
add wave -noupdate /wrapper_tb/uut/v_zero_cross_inst/data_in
add wave -noupdate /wrapper_tb/uut/v_zero_cross_inst/data_in_valid
add wave -noupdate /wrapper_tb/uut/v_zero_cross_inst/zero_crossing_dect
add wave -noupdate /wrapper_tb/uut/v_zero_cross_inst/raw_zero_crossing
add wave -noupdate /wrapper_tb/uut/v_zero_cross_inst/zero_crossing_reg
add wave -noupdate -format Literal /wrapper_tb/uut/v_zero_cross_inst/data_in_re
add wave -noupdate /wrapper_tb/uut/v_zero_cross_inst/zero_crossing_dect_sig
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {18639942734 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 357
configure wave -valuecolwidth 122
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {105 ms}
