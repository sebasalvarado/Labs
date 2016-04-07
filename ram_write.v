/*Tested and working module that controls the writing into the RAM
 */

module ram_write(clk, resetn, ready, x_in, y_in, data, address, writeEn);
	input clk, resetn, ready;
	input [7:0] x_in;
	input [6:0] y_in;
	output [7:0] data;
	output [4:0] address;
	output writeEn;

	//Declare the wires that we have to use
	wire ld_x_wire, ld_y_wire, ld_data_wire,count_wire;
	wire finish_wire;
	ram_write_control control(
		.clk(clk),
		.resetn(resetn),
		.ready(ready),
		.finish(finish_wire),
		.ld_x(ld_x_wire),
		.ld_y(ld_y_wire),
		.ld_data(ld_data_wire),
		.count(count_wire),
		.writeEn(writeEn)
	);

	ram_write_datapath data_path(
		.clk(clk),
		.resetn(resetn),
		.x_in(x_in),
		.y_in(y_in),
		.ld_x(ld_x_wire),
		.ld_y(ld_y_wire),
		.ld_data(ld_data_wire),
		.count(count_wire),
		.data_out(data),
		.address(address),
		.finish(finish_wire)
	);
endmodule



/* Module that given an x and y, writes into the RAM the values at x and y
 * Keeps a counter and an address register to know to which address we want to write
 */
module ram_write_control(clk, resetn, ready,finish, ld_x,ld_y,ld_data,count, writeEn);
	input clk, resetn;
	input finish;
	input ready; //Signal sent from the control unit to indicate that we should write
	output reg writeEn; //Signal to the RAM to indicate that it must write
	output reg ld_x, ld_y, ld_data,count;
	//Declare the registers that we will need for this module
	 //Register that will have a 1 when we have wrote the 32 rows of the RAM
	//Declare the registers for the states we need
	reg [3:0] current_state, next_state;

	localparam START_STATE = 4'd0,
	           LOAD_X = 4'd1,
		   LOAD_X_WAIT =4'd2,
		   LOAD_Y = 4'd3,
		   LOAD_Y_WAIT = 4'd4, 
		   WRITE_X = 4'd5,
		   WRITE_X_WAIT = 4'd6,
		   UPDATE_ADDR = 4'd7,
		   UPDATE_FINAL = 4'd8,
		   WRITE_Y = 4'd9,
		   WRITE_Y_WAIT = 4'd10,
		   WAIT  = 4'd11,
		   FINISH = 4'd12;

	//Always block for the next state logic
	always@(*)
	begin:StateTable
	case(current_state)
		START_STATE: next_state = (ready)?LOAD_X:START_STATE;
		LOAD_X: next_state = LOAD_X_WAIT;//Send the signals to load x properly into the register
		LOAD_X_WAIT: next_state = WRITE_X;
		WRITE_X: next_state = WRITE_X_WAIT;
		WRITE_X_WAIT: next_state = UPDATE_ADDR;
		UPDATE_ADDR: next_state = LOAD_Y;
		LOAD_Y:  next_state = LOAD_Y_WAIT;
		LOAD_Y_WAIT: next_state  = WRITE_Y;
		WRITE_Y: next_state = WRITE_Y_WAIT;
		WRITE_Y_WAIT: next_state = UPDATE_FINAL;
		UPDATE_FINAL: next_state = (finish)? FINISH:WAIT;
		WAIT: next_state = (ready)? LOAD_X:WAIT; //Loop in WAIT until we are ready to paint again
		FINISH: next_state = FINISH;
	endcase
	end


	//Always block for the ouput logic
	always@(*)
	begin:Output
	writeEn = 1'b0;
	count = 1'b0;
	ld_data = 1'b0;
	ld_x = 1'b0;
	ld_y = 1'b0;
	case(current_state)
		LOAD_X: begin
			ld_x = 1'b1;
			end
		LOAD_Y: begin
			ld_y = 1'b1;
			end
		WRITE_X: begin
			ld_data = 1'b1;
			end
		WRITE_X_WAIT:begin
			writeEn = 1'b1;
			end
		UPDATE_ADDR: begin 
			count = 1'b1; //Indicate to count up
			end
		WRITE_Y: begin
			ld_data = 1'b1;
			end
		WRITE_Y_WAIT: begin
			writeEn = 1'b1;
			end
		UPDATE_FINAL: begin	
			count = 1'b1;
			end
	endcase
	end

	//Next State logic Always block
	always@(posedge clk)
	begin:NexState
		if(!resetn)
			current_state <= START_STATE;
		else  begin
			current_state <= next_state;
		end
	end

endmodule

module ram_write_datapath(clk, resetn, x_in, y_in,ld_x,ld_y,ld_data,count, data_out, address, finish);
	input clk,resetn,count,ld_x,ld_y,ld_data;
	input [7:0] x_in;
	input [6:0] y_in;
	output reg [7:0] data_out;
	output reg [4:0] address;
	output reg finish;

	//Define the data register that will be needed
	reg [7:0] data_register;

	//ALways block for the input logic
	always@(posedge clk)
	begin:Input
		if(!resetn)begin
			data_register <= 8'd0;
			end
		else begin
			if(ld_x) begin
				data_register <= x_in;
				end
			if(ld_y) begin
				data_register <= y_in;
				end
		end
	end
	// Always block for the Output Logic 
	always@(posedge clk)
	begin:Output
		if(!resetn)
			data_out <= 8'd0;
		else begin
			if(ld_data)begin
				data_out <= data_register;
			end
		end
	end
	//Always block for the address that will go in to the RAM
	always@(posedge clk)
	begin:Adress
		if(!resetn)
			address <= 5'd0; // when we reset the first place we will paint is 0
		else begin
			if(count === 1'b1)begin
				address <= address + 5'd1;
			end
			if(count === 1'b0)begin
				address <= address;
			end
		     end
	end
	//Always block for the finish signal
	always@(posedge clk)
	begin:Finish
		if(!resetn)
			finish <= 1'b0;
		else begin
		    if(address === 5'd31)
			finish <= 1'b1;
		    if(address !== 5'd31)
			finish <= 1'b0;
		end
	end
endmodule
