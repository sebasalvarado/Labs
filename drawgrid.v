//Possible Errors: Line 198 maybe go is 1 when we press it try switching sides of cases
module drawgrid
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	// Declare your inputs and outputs here

	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	// We will use the 320 x 240 pixels display
	wire [2:0] colour;
	wire [9:0] x_wire;
	wire [7:0] y_wire;
	wire writeEn;
	wire [5:0] offset_x;
	wire [5:0] offset_y;
	wire resetn, mux_select_x, mux_select_y, go;
	//Assign corresponding keys into the wires.
	assign resetn = KEY[0];
	assign go = ~KEY[1];

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x_wire),
			.y(y_wire),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

	wire [1:0]finish_wire;
    // Instansiate datapath
	datapath d0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.finish(finish_wire),
		.offset_x(offset_x),
		.offset_y(offset_y),

		.x(x_wire),
		.y(y_wire)
		);

    // Instansiate FSM control
     control c0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.go(go),

		// Outputs that are being put into the datapath and the VGA
		.finish(finish_wire),
		.offset_x(offset_x),
		.offset_y(offset_y),
		.colour(colour),
		.plot(writeEn)
		);

endmodule

module datapath(clk,
	 	resetn,
		finish,
		offset_x,
		offset_y,
		x,
		y);

	// Declaring the inputs and outputs of the module
	input clk;
	input resetn;
	input [1:0]finish;
	input [4:0]offset_x;
	input [3:0]offset_y;
	output reg [7:0] x;
	output reg [6:0] y;
	// Declare the registers that we will have
	reg [7:0] x_reg;
	reg [6:0] y_reg;
	// Define the two outputs of our ALU unit
	reg [7:0] x_alu;
	reg [6:0] y_alu;

	//Input Logic for Load registers
	always@(posedge clk)
	begin: InputLogic
		if(!resetn) begin
			x_reg <=8'b0;
			y_reg <=7'b0;
		end
		case(finish)
			2'b00:begin // not finished we have to load the same value
				x <= x_reg;
				y<=y_reg;
			end
			2'b01:begin //When we finished the block we add
				x <= x_alu;
				y <= y_alu;
			end
			2'b10:begin //When we finish a line we reset x and add 32 to y
				x <= 8'b0;
				y <= y_reg + 7'd32;
			end

		endcase
	end

	// The ALU Implementation
	always@(*)
	begin:ALU
		if(!resetn) begin
			x_alu = 8'b0;
			y_alu = 7'b0;
		end
		else begin
			// We add the two most significant bits to Y and the least to X
			x_alu = x_reg +  offset_x;
			y_alu = y_reg + offset_y;
		end
	end
endmodule

module control(clk,
		resetn,
		go,
		x,
		y,
		finish,
		offset_x,
		offset_y,
		colour,
		plot);
		
		input resetn;
		input clk;
		input go;
		input [8:0] x;
		input [7:0] y;
		output reg [1:0] finish;
		output reg [4:0] offset_x;
		output reg [3:0] offset_y;
		output reg [2:0] colour;
		output reg plot;
	// Declare the State table to refer to it later
	localparam START_STATE = 3'd0,
		   PAINT_BLOCK = 3'd1,
		   PAINT_LAST = 3'd2,
		   PAINT_FIRST = 3'd3,
		   PAINT_FINAL = 3'd6;

	reg [2:0] current_state, next_state;

	// Create the always block for the next state logic
	always@(*)
	begin: state_table
	   case(current_state)
		START_STATE:next_state = go? PAINT_BLOCK:START_STATE;	//loop in its state until go signal goes high again
		PAINT_BLOCK:
			begin // After painting blue you have to check if you will go out of bounds
		           if(x == 9'd304 && y == 8'd240) // meaning if you are one block before last
				next_state = PAINT_FINAL;
		       	   else if(x == 9'd304) // Paint the end of a line
				next_state = PAINT_LAST;
		       	   else  //keep painting the colour will be given by the register
		                next_state = PAINT_BLOCK;
			end
		PAINT_LAST:  next_state = PAINT_FIRST; // At the end of the line print the next line block
		PAINT_FIRST: next_state = PAINT_BLOCK; //loop in its state until go signal goes high again
		PAINT_FINAL: next_state = PAINT_FINAL; //loop in the end state until hardware is reset
		endcase
	end
	//Selecting the colour that we will need
	always@(posedge clk)
	begin:ColourReg
				case(current_state)
					START_STATE:colour <= 3'b001;
					PAINT_BLOCK: colour <= 3'b001;
					//	if(colour == 3'b001)
					//		begin //If it was blue, paint green
					//		colour <= 3'b010;
					//		end
					//	else if(colour == 3'b001)
					//		begin	//If it was green paint black
					//		colour <= 3'b111;
					//		end
					//	else if(colour == 3'b111) //If it was black paint blue
					//		begin
					//		colour <= 3'b001;
					//		end
					PAINT_LAST: colour <= 3'b010; //The last of each line will always be green
					PAINT_FIRST: colour <=3'b001; // The first of each line wil always be blue
					PAINT_FINAL: colour <= 3'b001; // The last one will be blue
				endcase
	end
	// Logic for the counter to be sent to the ALU
	reg [8:0] counter;
	always@(posedge clk)
	begin:CounterLogic
		if (!resetn)
		   counter <= 9'd0;
		else if(counter == 9'd196)
		   counter <= 9'd0;
		else
		   counter <= counter + 1; //Count up every time
	end
	
	assign x_offset = counter[4:0];
	assign y_offset = counter[8:5];
	// Finish signal Logic goes here
	always@(*)
	begin:Finish
		if(!resetn || counter != 9'd196)
			finish <= 2'b00; //Send a 00 meaning not finished
		else if(counter == 9'd196)
			finish <= 2'b01;
		else if(x == 9'd320)// If we are on the last pixel, switch to next line
			finish <= 2'b10;
	end
	//Output logic, everything that the data path will receive as input goes here.
	always@(*)
	begin:OutLogic
	// Set all of them to zero
	   plot = 1'b0;
	   case(current_state)
		START_STATE: plot = 1'b1;
		PAINT_BLOCK: plot = 1'b1;
		PAINT_LAST: plot = 1'b1;
		PAINT_FIRST: plot = 1'b1;
		PAINT_FINAL: plot = 1'b1;
	   endcase
	end

	//CUrrent state registers logic on positive clock edge
	always@(posedge clk)
	begin: StateFFs
		if(!resetn)
			current_state <= START_STATE;
		else
			current_state <= next_state;
	end // THis is the state FFs that we will use

	//Register for our Color
//	always@(*)
//	begin: ColourRegister
//		if(!resetn)
//			colour = 3'b001; //On reset set solor to blue
//		else if(colour == 3'b001)
//			colour = 3'b010; //Become green if you were blue
//		else if(colour == 3'b010) //Become black if you weere green
//			colour = 3'b000;
//	end
endmodule
