# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog control_data.v

#load simulation using mux as the top level simulation module
vsim control_data

#log all signals and add some signals to waveform window
log -r {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}
#Case 1: Load X and Y in four different clock cycles and start painting at point (0,0)
force {CLOCK_50} 0 0, 1 5 ns -repeat 10 ns
force {KEY[0]} 1 0, 0 7ns, 1 17ns
force {SW[6:0]} 0 0, 2#0000000 7ns, 2#000000 17ns
force {SW[9:7]} 2#111 0
force {KEY[3]} 1 0, 0 17ns, 1 37ns, 0 47ns
force {KEY[1]} 1 0, 0 37ns
run 300ns

#Case 2: Load X and Y in four different clock cycles at point (80,80), then paint it black, then paint it 
force {CLOCK_50} 0 0, 1 5 ns -repeat 10 ns
force {KEY[0]} 1 0, 0 7ns, 1 17ns
force {SW[6:0]} 0 0, 2#01010000 7ns, 2#01010000 17ns, 2#01010100 255ns, 2#01010100 265ns
force {SW[9:7]} 2#111 0, 2#000 255ns, 2#111 425ns
force {KEY[3]} 1 0, 0 17ns, 1 37ns, 0 47ns
force {KEY[1]} 1 0, 0 37ns
run 600ns
