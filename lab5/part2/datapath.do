# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog datapath.v

#load simulation using mux as the top level simulation module
vsim datapath

#log all signals and add some signals to waveform window
log -r {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

#Case 1: Load A,B,C,X in four different clock cycles
force {clk} 0 0, 1 5 ns -repeat 10 ns
force {resetn} 0 0, 1 7ns
force {data_in} 0 0, 2#00000001 7ns, 2#00000001 17ns, 2#00000010 27ns,2#00000010 37ns, 0 47ns
force {ld_alu_out} 0 0
force {ld_a} 0 0, 1 7ns,0 17ns
force {ld_b} 0 0, 1 17ns, 0 27ns
force {ld_c} 0 0, 1 27ns, 0 37ns
force {ld_x} 0 0, 1 37ns, 0 47ns

run 100ns

#Case 2: Load A,B,C then reset and check that all of the registers are zero now
force {clk} 0 0, 1 5 ns -repeat 10 ns
force {resetn} 0 0, 1 7ns, 0 40ns
force {data_in} 0 0, 2#00000001 7ns, 2#00000001 17ns, 2#00000010 27ns
force {ld_alu_out} 0 0
force {ld_a} 0 0, 1 7ns,0 17ns
force {ld_b} 0 0, 1 17ns, 0 27ns
force {ld_c} 0 0, 1 27ns, 0 37ns
run 100ns

#Case 3: Compute Ax + A we will use the whole datapath including storing in A and output on R
force {clk} 0 0, 1 5 ns -repeat 10 ns
force {resetn} 0 0, 1 7ns
force {data_in} 0 0, 2#00000001 7ns, 2#00000010 17ns
force {ld_alu_out} 0 0, 1 47ns
force {ld_a} 0 0, 1 7ns,0 17ns, 1 37ns, 0 57ns
force {ld_b} 0 0
force {ld_c} 0 0
force {ld_x} 0 0, 1 17ns, 0 27ns
force {alu_select_a} 2#00 27ns
force {alu_select_b} 2#11 27ns
force {alu_op} 1 35ns
force {ld_r} 1 35ns, 0 57ns
run 100ns