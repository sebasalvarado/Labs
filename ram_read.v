/*
 *
 */
module ram_read(clk, resetn, x_in, y_in, go, data_in, address, data_out, writeEn, x_out, y_out);
	input, clk, resetn;
	input [7:0] x_in; //The x coordinate given by the datapath
	input [6:0] y_in; //THe y coordinate given by the datapath
	input go;
	input [7:0] data_in; //The data read from the RAM module
	

	output [4:0] address; //The address that we will want to read from the RAM
	output [7:0] data_out; //When we want to delete some data we will write zeros to the RAM
	output writeEn;
	output [7:0] x_out; //X coordinate for the delete box that we will need if successful found
	output [7:0] y_out; // Y coordinate for the delete box

	//Declare the wires that we will need in this module

	
endmodule

/* Decoding of Signals: ld_ram is zero when we choose the output of Ram to in the RAM_X 1 is otherwise
 * addr_choose is low when we will choose the address stored in addr_x for the input of the RAM
 */
module ram_read_controlunit(clk, resetn,go,finish,x_comp, y_comp,reset_address, ld_x_y, add_x_addr, add_y_addr, ld_ram, addr_choose, final_comp);
	input clk, resetn,go;
	input finish; //Will be high when the datapath says that we have already got all the address in the RAM
	output reg x_comp, y_comp, reset_address, ld_x_y, add_x_addr, add_y_addr, ld_ram, addr_choose, final_comp; 
	
	//Define the current and next state registers
	reg [4:0] current_state, next_state;
	//Define the State table for this module
	localparam START_STATE = 5'd0,
		   LOAD_X_Y = 5'd1,
		   LOAD_X_Y_WAIT = 5'd2,
		   READ_SIGNAL_X = 5'd3,
		   LOAD_RAM_X = 5'd4,
		   COMPARE_X = 5'd5,
		   ADD_ADDR_X = 5'd6,
		   READ_SIGNAL_Y = 5'd7,
		   LOAD_RAM_Y = 5'd8,
	           COMPARE_Y = 5'd9,
		   ADD_ADDR_Y = 5'd10,
	           FINAL_COMPARISON = 5'd11,
		   RESET_ADDRESS = 5'd12,
		   FINISH = 5'd13;
	//Always block for the next state transisitons
	always@(*)
	begin:Transition	
	case(current_state)
		START_STATE: next_state = (go)? LOAD_X_Y: START_STATE;
		LOAD_X_Y: next_state = LOAD_X_Y_WAIT;
		LOAD_X_Y_WAIT: next_state = READ_SIGNAL_X; // We will transition to the state where we send the signals to the RAM module
		READ_SIGNAL_X: next_state = LOAD_RAM_X; //  
	 	LOAD_RAM_X: next_state = COMPARE_X; //Send signal to perform the comparison of X and the interval given
		COMPARE_X: next_state = ADD_ADDR_X;//Signal to add the counter on X
		ADD_ADDR_X: next_state = READ_SIGNAL_Y;
		READ_SIGNAL_Y: next_state = LOAD_RAM_Y; //Indicate that we will load what the ram gives us
		LOAD_RAM_Y: next_state = COMPARE_Y; // When we already loaded we have to compare the Y to the desired interval
		COMPARE_Y: next_state = ADD_ADDR_Y;
		ADD_ADDR_Y: next_state = FINAL_COMAPRISON;
		FINAL_COMPARISON: next_state = (finish)? RESET_ADDRESS: READ_SIGNAL_X; //If we havent finished reading the RAM go back to read X
		RESET_ADDRESS: next_state = FINISH;
		FINISH: next_state = (go)? LOAD_X_Y: FINISH; //loop until go is high again
	endcase
	end

	//Always block for the output logic
	always@(posedge clk)
	begin:OutputSIg
	// Make all the signals be low by default
	final_comp = 1'b0; //Signal that indicates to compare the final results for x and y 
	x_comp = 1'b0;
	y_comp = 1'b0; 
	reset_address = 1'b0;
	ld_x_y = 1'b0;
	add_x_addr = 1'b0;
	add_y_addr = 1'b0;
  	ld_ram = 1'b0; //Set zero if we want to load into the RAM X register the output of the data
	addr_choose = 1'b0; //This will be zero when we pass the address of X
	
	case(current_state)
	  LOAD_X_Y: begin
		ld_x_y = 1'b1;
		end
	  READ_SIGNAL_X: begin
		addr_choose = 1'b0;
		end
	 LOAD_RAM_X: begin
		ld_ram = 1'b0;
		end
	COMPARE_X: begin
		x_comp = 1'b1;
		end
	ADD_ADDR_X: begin
		add_x_addr = 1'b1;
		end
	READ_SIGNAL_Y: begin
		addr_choose = 1'b1;
		end
	LOAD_RAM_Y: begin	
		ld_ram = 1'b1; 
		end
	COMPARE_Y: begin
		y_comp = 1'b1;
		end
	ADD_ADDR_Y: begin	
		add_y_addr = 1'b1;
		end
	FINAL_COMPARISON: begin
		final_comp = 1'b1;
		end
	RESET_ADDRESS: begin
		reset_address = 1'b1;
		end
		
	endcase 
	end

	//CHange of states logic
	always@(posedge clk)
	begin:NextState
		if(!resetn)
			current_state <= START_STATE;
		else begin
			current_state <= next_state;
		end
	end	
endmodule

module ram_read_datapath(clk, resetn, x_in, y_in,data_in,  x_comp, y_comp, reset_address, ld_x_y, add_x_addr, add_y_addr, ld_ram, addr_choose, final_comp, finish, address, data_out,writeEn,x_out, y_out);
	input clk, resetn;
	input [7:0] x_in;
	input [6:0] y_in;
	input [7:0] data_in; //The data read from the RAM module
	input x_comp, y_comp, reset_address, ld_x_y, add_x_addr, add_y_addr, ld_ram, addr_choose, final_comp; //Signals received from the FSM

	output reg finish;
	output reg [4:0] address;
	output reg [7:0] data_out;
	output reg writeEn;
	output reg [7:0] x_out;
	output reg [6:0] y_out;
	

	//Declare the registers that we will need internaly
	reg [7:0] x;
	reg [6:0] y;
	reg [4:0] addr_x, addr_y;
	reg [7:0] RAM_x, RAM_y;
	reg result_x, result_y //THese two registers contain the comparisons result of x and y 
	reg final_result;

	//Input Logic for the registers in our datapath 
	always@(posedge clk)
	begin:INputXandY
		if(!resetn) begin
			x <= 8'b0;
			y <= 7'd0;
		else begin
			if(ld_x_y) begin
				x <= x_in; 
				y <= y_in;
			end
		end
	end
	
	//Input logic for the x address counter
	always@(posedge clk)
	begin:AddrX
		if(!resetn) begin
			addr_x <= 5'd0;
		else begin
			if(addr_x === 5'd30) begin
				//Reset the counter and send the signal
				addr_x <= 5'd0;
				finish <= 1'd1;
				end
			if(add_x_addr) begin
				addr_x <= addr_x +5'd2;
			end
		end
	end

	//Input LOgic for the y address counter
	always@(posedge clk)
	begin:AddrY
		if(!resetn) begin
			addr_y <= 5'd1;
		end
		else begin
			if(add_y_addr) begin
				addr_y <= addr_y + 5'd2;
			end
		end
	end

	//INput LOgic RAM X
	always@(posedge clk)
	begin:RAMxy
		if(!resetn) begin
			RAM_x <= 8'd0;
			RAM_y <= 8'd0;
		end
		else begin
			if(!ld_ram) begin
				//THis means we have to load the data to the X ram register
				RAM_x <= data_in;
				RAM_y <= RAM_y;
			end
			else begin
				if(ld_ram) begin
					RAM_x <= RAM_x;
					RAM_y <= data_in;
				end
			end
			end
	end

	//Input Logic for the Result Register for X
	always@(posedge clk)
	begin:ResultsX
		if(!resetn) begin
			result_x <= 1'b0;
		end
		else begin
			if(x_comp)begin
				if((x <= RAM_x - 8'd16) || (x >= RAM_x + 8'd16)) begin
					//Put the Result ignal high
					result_x <= 1'b1;
				end
				else begin
					result_x <= 1'b0;
				end
			end
		end
	end

	//INput Logic for the Register Y
	always@(posedge clk)
	begin:ResultY
		if(!resetn) begin
			result_y <= 1'b0;
		end
		else begin
			if(y_comp) begin
				if((y <= RAM_y - 8'd20)) begin
					result_y = 1'b1;
				end
				else begin
					result_y <= 1'b0;
				end
			end
		end
	end

	//Input logic for the final comparison between x and y
	always@(posedge clk)
	begin:FinalCOmp
		if(!resetn)
			final_result <= 1'b0;
		else begin
			final_result <= (result_x && result_y);
		end
	end

	//Output Logic that we will use
	always@(*)
	begin:Output
		data = 8'd0;
  		writeEn = final_result
		address = (addr_choose)? addr_x: addr_y;
		x_out = x; 
		y_out y;
	end										
endmodule
