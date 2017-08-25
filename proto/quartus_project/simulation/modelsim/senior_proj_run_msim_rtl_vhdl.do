transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {D:/Donald/Documents/senior_proj/hdl/zero_crossing_dect.vhd}
vcom -93 -work work {D:/Donald/Documents/senior_proj/hdl/top_level_wrapper.vhd}
vcom -93 -work work {D:/Donald/Documents/senior_proj/hdl/rms_calc.vhd}
vcom -93 -work work {D:/Donald/Documents/senior_proj/hdl/populate_fifo.vhd}
vcom -93 -work work {D:/Donald/Documents/senior_proj/hdl/genData.vhd}
vcom -93 -work work {D:/Donald/Documents/senior_proj/hdl/freq_dect.vhd}
vcom -93 -work work {D:/Donald/Documents/senior_proj/hdl/edge_dect.vhd}
vcom -93 -work work {D:/Donald/Documents/senior_proj/quartus_project/fifo.vhd}
vcom -93 -work work {D:/Donald/Documents/senior_proj/quartus_project/mult.vhd}
vcom -93 -work work {D:/Donald/Documents/senior_proj/quartus_project/sqrt.vhd}

