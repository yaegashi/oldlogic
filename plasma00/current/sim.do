# $Id: sim.do 61 2005-12-11 14:49:53Z yaegashi $

vlib work
vcom -93 -explicit mlite/mlite_pack.vhd
vcom -93 -explicit mlite/alu.vhd
vcom -93 -explicit mlite/bus_mux.vhd
vcom -93 -explicit mlite/control.vhd
vcom -93 -explicit mlite/mem_ctrl.vhd
vcom -93 -explicit mlite/mlite_cpu.vhd
vcom -93 -explicit mlite/mult.vhd
vcom -93 -explicit mlite/pc_next.vhd
vcom -93 -explicit mlite/pipeline.vhd
vcom -93 -explicit mlite/reg_bank.vhd
vcom -93 -explicit mlite/shifter.vhd
vcom -93 -explicit dpram.vhd
vcom -93 -explicit asramc.vhd
vcom -93 -explicit clkgen.vhd
vcom -93 -explicit confinit.vhd
vcom -93 -explicit crtc.vhd
vcom -93 -explicit fb.vhd
vcom -93 -explicit ram16xyd.vhd
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
