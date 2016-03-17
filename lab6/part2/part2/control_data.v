module control_data(CLOCK_50, SW, KEY, X,Y, COLOR, PLOT);
	//Define the inputs of the module
	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	// Define the ouputs of the module that will be inputs of VGA
	output [2:0] COLOR;
	output [7:0] X;
	output [6:0] Y;
	output PLOT;
	

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire writeEn;
	wire [6:0]INPUT;
	wire go, resetn , load_enable;
	//Assign corresponding keys into the wires.
	assign resetn = KEY[0];
	assign COLOR = SW[9:7];
	assign  go = ~KEY[1];
	assign INPUT = SW[6:0];
	assign load_enable = ~KEY[3];

	// ALl the wires that we need to connect control and datapath
	wire load_x, load_y, load_r, load_c, ld_alu_out;

	// Instansiate datapath
	datapath d0(
		.clk(CLOCK_50),
		.resetn(resetn),

		.load_x(load_x),
		.load_y(load_y),
		.load_r(load_r),
		.load_c(load_c),
		.ld_alu_out(ld_alu_out),

		.data_in(INPUT),

		.x(X),
		.y(Y)
		);

    // Instansiate FSM control
     control c0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.go(go),
		.load_enable(load_enable),

		// Outputs that are being put into the datapath and the VGA
		.load_x(load_x),
		.load_y(load_y),
		.load_r(load_r),
		.load_c(load_c),
		.load_alu_out(ld_alu_out),
		.plot(PLOT)
		);
endmodule


module datapath(input clk,
	 	input resetn,
		input load_x,
		input load_y,
		input load_r,
		input load_c,
		input ld_alu_out,
		input [6:0]data_in,
		output reg [7:0]x, output reg [6:0]y);
	// Declare the registers that we will have
	reg [7:0]x_reg;
	reg [6:0] y_reg;
	reg [3:0] counter;
	reg [14:0] alu_output;
	// Define the two outputs of our ALU unit
	reg [7:0] x_alu;
	reg [6:0] y_alu;

	//Input Logic for Load registers
	always@(posedge clk)
	begin: InputLogic
		if(!resetn) begin
			x <= 8'b0;
			y <= 7'b0;
			x_reg <=8'b0;
			y_reg <=7'b0;
			x_alu <= 8'b0;
			y_alu <= 7'b0;
			counter <= 4'b0;
		end
		else begin
		     if(load_x)
		    // Set x depending on the signal of ldu_alu_out, first 8 bits of the alu_out
			x_reg <= ld_alu_out? {1'b0,data_in}: {1'b0,data_in};
		     if(load_y)
			y_reg <= ld_alu_out? {1'b0,data_in}: {1'b0,data_in};
		end
	end
	//Output Result Register
	always@(posedge clk)
	begin:Output
		if(!resetn) begin
			x <= 8'b0;
			y <= 8'b0;
		end
		else
		   begin
		   if(load_r)
			x <=  x_alu;	// Set the output x to the first 8 bits
			y <=  y_alu; // Set the output y to the first 7 bits
	           end
	end

	//LOgic for the Counter register
	always@(posedge clk)
	begin:COUNTERLOGIC
		if(counter == 4'd15)  // the reset case is already being handled before
		    counter <= 4'b00; // When we reach 15 we reset it again and keep counting
		else begin
		    if(load_c == 1'b1)
		    counter <= counter + 1'b1; // add one on every clock edge
		end
	end
	// The ALU Implementation
	always@(*)
	begin:ALU
		// We add the two most significant bits to Y and the least to X
		x_alu = x_reg + {6'b0,counter[1:0]};
		y_alu = y_reg + {5'b0,counter[3:2]};
	end
endmodule

module control(input clk,
		input resetn,
		input go,
		input load_enable,
		output reg load_x, load_y, load_r, load_c,
		output reg load_alu_out,
		output reg plot);
	// Declare the State table to refer to it later
	localparam LOAD_X = 3'd0,
		   LOAD_X_WAIT = 3'd1,
		   LOAD_Y = 3'd2,
		   LOAD_Y_WAIT = 3'd3,
		   DISPLAY_RESULT = 3'd4;

	reg [2:0] current_state, next_state;

	// Create the always block for the next state logic
	always@(*)
	begin: state_table
	     case(current_state)
		LOAD_X:	 next_state = load_enable? LOAD_X_WAIT:LOAD_X;	//loop in its state until go signal goes high again
		LOAD_X_WAIT:  next_state = load_enable? LOAD_X_WAIT: LOAD_Y; //loop in its state until go signal goes high again
		LOAD_Y: next_state = (load_enable)? LOAD_Y_WAIT: LOAD_Y; //loop in its state until go signal goes high again
		LOAD_Y_WAIT: next_state = go? DISPLAY_RESULT: LOAD_Y_WAIT; //loop in its state until go signal goes high again
		DISPLAY_RESULT: next_state = go? DISPLAY_RESULT:LOAD_X; //loop in its state until go signal goes high again
	     default: next_state = LOAD_X;
	     endcase
	end // THis was the state table
	//Output logic, everything that the data path will receive as input goes here.
	always@(*)
	begin:OutLogic
	// Set all of them to zero
	   load_x = 1'b0;
	   load_y = 1'b0;
       	   load_r = 1'b0;
	   load_c = 1'b0;
	   load_alu_out = 1'b0;
	   case(current_state)
		LOAD_X: begin
		  load_x = 1'b1; // send signal to allow X to be loaded
		  load_alu_out = 1'b1; // Select the mux to choose the data from data_in
		  end
		LOAD_Y: begin
		  load_y = 1'b1; // send signal to allow Y to be loaded
		  load_alu_out = 1'b1; // Select the mux to choose the data from data_in
		   end
		DISPLAY_RESULT: begin
		  load_x = 1'b1; // When we will perform the computation
		  load_y = 1'b1; // All of the registers must be open and ready to be loaded.
		  load_r = 1'b1;
		  load_c = 1'b1;
		  load_alu_out = 1'b0;
		  plot = 1'b1;
		  end
	   endcase
	end

	//CUrrent state registers logic on positive clock edge
	always@(posedge clk)
	begin: StateFFs
		if(!resetn)
			current_state <= LOAD_X;
		else
			current_state <= next_state;
	end // THis is the state FFs that we will use
endmodule
