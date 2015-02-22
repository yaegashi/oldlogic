# $Id: tsim.do 49 2005-11-29 13:29:05Z yaegashi $

vlib work
#vcom -93 -explicit func_sim.vhd
vcom -93 -explicit time_sim.vhd
vcom -93 -explicit sram.vhd
vcom -93 -explicit tsim.vhd

vsim -t 1ps -lib work tbench
view wave
add wave -hex *
#force -freeze -repeat 40ns u0/clkgen0_bufg1/o 1 0, 0 20ns
run 1us
