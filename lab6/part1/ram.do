#Set the working dir, where all complied Verilog goes
 vlib work
#Compute all verilog modules in asynchronousadder.v to working dir
 vlog part1.v
#Load simulation using asynchrounousadder as top level module
 vsim -Lf /data/quartus-15.0.0.145/modelsim_ase/altera/verilog/altera_mf part1
#Log alll signals and add some sognals to waveform window.
 log {/*}
#add wave would add all items in top level module
 add wave {/*} 
 
# First Case:
force {SW[0]} 0 0;
force {SW[2:1]} 2#11 0;
force {SW[4:3]} 2#00 0;
force {SW[5]} 1 0;
force {SW[8:6]} 2#000 0;
force {SW[9]} 1 0;
force {KEY[0]} 1 0, 0 5 -repeat 10;
run 100ns;

# Second Case:
force {SW[0]} 1 0;
force {SW[2:1]} 2#00 0; 
force {SW[5:3]} 2#111 0;
force {SW[7:6]} 2#00 0;
force {SW[9:8]} 2#11 0;
force {KEY[0]} 1 0, 0 5 -repeat 10;
run 100ns;

# Third Case: 
force {SW[0]} 1 0;
force {SW[6:1]} 2#000000 0;
force {SW[8:7]} 2#11 0; 
force {SW[9]} 0 0;
force {KEY[0]} 1 0, 0 5 -repeat 10;
run 100ns;

# Fourth Case:
force {SW[0]} 1 0;
force {SW[1]} 0 0;
force {SW[3:2]} 2#11 0;
force {SW[7:4]} 2#0000 0;
force {SW[8]} 1 0;
force {SW[9]} 0 0;
force {KEY[0]} 1 0, 0 5 -repeat 10;
run 100ns;

# Fifth Case:
force {SW[0]} 0 0;
force {SW[1]} 1 0;
force {SW[2]} 0 0;
force {SW[3]} 1 0;
force {SW[5:4]} 2#00 0;
force {SW[6]} 1 0;
force {SW[8:7]} 2#00 0;
force {SW[9]} 1 0; 
force {KEY[0]} 1 0, 0 5 -repeat 10;
run 100ns;

# Sixth Case:
force {SW[0]} 0 0;
force {SW[2:1]} 2#11 0;
force {SW[3]} 0 0;
force {SW[9:4]} 2#111111 0;
force {KEY[0]} 1 0, 0 5 -repeat 10;
run 100ns;


