#set the working dir, where all complied Verilog goes
vlib work

#Complue all verilog modules in full4adder.v to working dir
vlog full4adder.v

#Load simulation using full4adder as top level module
vsim full4adder

#Log alll signals and add some sognals to waveform window.
log {/*}
#add wave would add all items in top level module
add wave {/*}

#First test case
force {SW[1]} 0
force {SW[3]} 0
force {SW[5:4]} 0
force {SW[7]} 0
force {SW[8]} 0

force {SW[0]} 1
force {SW[2]} 1
force {SW[6]} 1
#Run the simulation for 10ns
run 10ns

#Second test case
force {SW[2:0]} 0
force {SW[6:4]} 0

force {SW[3]} 1
force {SW[7]} 1
force {SW[8]} 0
#Run the simulation for 10ns
run 10ns

#Third test case
force {SW[7:0]} 1
force {SW[8]} 0
#Run the simulation for 10ns
run 10ns

#Fourth test case
force {SW[3]} 1
force {SW[6:4]} 1
force {SW[8]} 0

force {SW[2:0]} 0
force {SW[7]} 0
#Run the simulation for 10ns
run 10ns

#Fifth test case
force {SW[1]} 1
force {SW[3]} 1
force {SW[5]} 1
force {SW[7]} 1
force {SW[8]} 0
force {SW[0]} 0
force {SW[2]} 0
force {SW[4]} 0
force {SW[6]} 0
#Run the simulation for 10ns
run 10ns

#Sixth test case
force {SW[7:3]} 1
force {SW[8]} 0
force {sw[0:2]} 0
#Run the simalation for 10ns
run 10ns