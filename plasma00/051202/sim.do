# $Id: sim.do 49 2005-11-29 13:29:05Z yaegashi $

vlib work
vcom -93 -explicit mlite_pack.vhd
vcom -93 -explicit alu.vhd
vcom -93 -explicit asramc.vhd
vcom -93 -explicit bus_mux.vhd
vcom -93 -explicit clkgen.vhd
vcom -93 -explicit confinit.vhd
vcom -93 -explicit control.vhd
vcom -93 -explicit crtc.vhd
vcom -93 -explicit dpram.vhd
vcom -93 -explicit fb.vhd
vcom -93 -explicit mem_ctrl.vhd
vcom -93 -explicit mlite_cpu.vhd
vcom -93 -explicit mult.vhd
vcom -93 -explicit pc_next.vhd
vcom -93 -explicit pipeline.vhd
vcom -93 -explicit ram16xyd.vhd
vcom -93 -explicit reg_bank.vhd
vcom -93 -explicit shifter.vhd
vcom -93 -explicit top.vhd
vcom -93 -explicit sram.vhd
vcom -93 -explicit sim.vhd

vsim -t 1ps -lib work tbench
view wave
add wave -hex *
add wave -hex u0/*
add wave -hex u0/ramc0/*
add wave -hex u1/*
run 1us
