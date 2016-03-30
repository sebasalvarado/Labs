//Possible Errors: Line 198 maybe go is 1 when we press it try switching sides of cases
module pizzadelivery
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
	wire [2:0] colour;
	wire [7:0] x_wire;
	wire [6:0] y_wire;
	wire [6:0] INPUT;
	wire writeEn;
	wire go, resetn, load_enable;
	//Assign corresponding keys into the wires.
	assign resetn = KEY[0];
	assign colour = SW[9:7];
	assign  go = ~KEY[1];
	assign load_enable = ~KEY[3];
	assign INPUT = SW[6:0];

	// ALl the wires that we need to connect control and datapath
	wire load_x, load_y, load_r, load_c, ld_alu_out;
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
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
endmodule

module control_move(clk, resetn,done, direction_in, delay_signal,colour_signal,frames,direction,go);
 input clk, resetn, delay_signal;//Delay signal is high every time that we have counted 1/60th of a second
 input done; //The draw_box module indictes when it has finished painting
 input [1:0] direction_in; //Has the direction given by the user

 output reg colour_signal; //Indicate if we want to draw, 1 or erase 0
 output display_enable; // Signal to indicate to the delay counter to start counting
 output reg go; //Indicates to the draw box to draw a new box
 output reg frames; //Frames indicate when we have counted 15 frames
 output reg [1:0] direction;

 localparam START_STATE = 3'd0,
            PAINT_BOX = 3'd1,
	    COUNT_FRAMES = 3'd2,
	    ERASE_BOX = 3'd3,
	    LOAD_X = 3'd4,
	    LOAD_X_WAIT = 3'd5,
	    LOAD_Y = 3'd6,
	    LOAD_Y_WAIT = 3'd7;

  //Declare the registers that we will use in our implementation
        reg [1:0] direction_register;
	reg [3:0] frame_counter;
	reg [2:0] current_state, next_state;
	reg [1:0] seconds_counter; // Will count up to 4 signifying that a second has elapsed

	//State Table and Transition Logic
	always@(*)
	begin:StateTable
	  case(current_state)
	   START_STATE:next_state = (!resetn)?PAINT_BOX:START_STATE; //loop in START until we press reset
	   PAINT_BOX: next_state = done? COUNT_FRAMES: PAINT_BOX; //loop in PAINT until the draw_box module drew the box
	   COUNT_FRAMES: next_state = frames? ERASE_BOX; COUNT_FRAMES; //loop in counting until we finish counting them
	   ERASE_BOX: next_state = done? LOAD_X:ERASE_BOX; //loop in erasing the box until the draw_box indicates otherwise
	   LOAD_X: next_state = LOAD_X_WAIT;
	   LOAD_X_WAIT: next_state = LOAD_Y;
	   LOAD_Y: next_state = LOAD_Y_WAIT;
	   LOAD_Y_WAIT: next_state = PAINT_BOX; // After my registers have been loaded I have to paint a new box again
	 endcase
	end


    //Seconds Counter
    always@(*)
    begin:SecondCounter
      if(!resetn)
        seconds_counter <= 2'd0;
      else begin
         if(frames)
	   seconds_counter <= seconds_counter + 2'd1;


    //Direction Registers
    always @(*)
    begin:Direction
      if(!resetn)
        direction_register <= 2'b00;
      else if(frames)
        direction_register <= direction_in; //Load direction when we counted 15 frames
    end

    //Frame counter logic
    always@(posedge clk)
    begin:FrameCount
      if(!resetn)
        frame_counter <= 4'd0; //Indicating we have not finished counting
	frames <= 1'b0;
      if(frame_counter == 4'd15)
         frame_counter <= 4'd0; // Indicate that we finished counting
         frames <= 1'b1;
      else begin
        if(delay_signal)
	  frame_counter <= frame_counter + 4'd1;
	  frames <= 1'b0;
	end
    end

    //Output Logic,signals for the datapath
    always@(*)
    begin:OutputLogic
    colour_signal = 1'b0;
    display_enable = 1'b0;
    go = 1'b0;
    frames = 1'b0;
    direction = 2'b00;
    case(current_state)
      START_STATE:begin
        colour_signal = 1'b1; // We want to paint
	go = 1'b1;



endmodule

/* Module that implements the datapath of the movement it also gives the colour to the VGA
 * and gives the (x,y) position for the draw_box module
 */
module datapath_move(clk, resetn,direction,colour_signal,display_enable, colour_out, x_out, y_out);
input clk, resetn,colour_signal,frames;
input display_enable; //Indicate that we have to count delay again
input [1:0] direction;
output reg delay_signal; //Tell the control unit that we counted 1/60th of a second
output reg [2:0] colour_out;
output reg [7:0] x_out;
output reg [6:0] y_out;

reg [7:0] x_reg;
reg [6:0] y_reg;
//Logic for loading the X and Y register according to the direction we will travel
always@(posedge clk)
  begin:InputLogic
  if(!resetn)
    x_reg <= 8'd0; // Starting position will be zero
    y_reg <= 7'd21; //Initial position is (0,21)
  case(direction)
    2'b00:begin //We move to the right
        if(frames)
	 x_reg <= x_reg + 8'd1; //Add 1 to the right
	 end
    2'b01:begin
        if(frames)
         y_reg <= y_reg + 7'd1; //We are moving down add 1 to y
	 end
    2'b10: begin
        if(frames)
	  x_reg <= x_reg - 7'd1; //Moving to the left
	  end
    2'b11: begin
        if(frames)
	  y_reg <= y_reg - 7'd1; //Moving Up so we substract 1
	end
   endcase
   end


reg [19:0] delay_counter;
//Count up to 1/60th of a second
always@(posedge clk)
  begin:DelayCounter
  if(!resetn)
    delay_counter <= 20'd0;
  if(delay_counter == 20'd833333)
    delay_signal <= 1'b1; //Indicate the FSM that we count 1/60th of a second
    delay_counter <= 20'd0;
  if(!display_enable)
    delay_counter <= 20'd0; //When control has to reset the delay counter
  else
    delay_counter <= delay_counter + 20'd1; //Add one every clock edge
  end


//Output Logic of the Module
always@(*)
  begin:OutputLogic
  x_out = x_reg;
  y_out = y_reg;
  end

// Colour Logic Always block
 always@(posedge clk)
   begin:ColourLogic
     if(!resetn)
       colour_out <= 3'b011; //Load yellow when we reset the system
     if(colour_out)
       colour_out <= 3'b011; //Load yellow when we indicate that we will paint
     else begin
       if(!colour_out)
       colour_out <= 3'b000; //Load black when we want to erase
	end
   end
endmodule


module draw_box(clk,resetn,go,x_in, y_in,x,y,plot,done);
	input clk;
	input resetn;
	input restart;
	input go;
	input [7:0] x_in;
	input [6:0] y_in;
	output [7:0] x;
	output [6:0] y;
	output plot;
	output done;
	//Declare the wires to connect control to datapath
	wire ld_x,ld_y, ld_r, ld_c;

	datapath_draw d0 (
	  .clk(clk),
	  .resetn(resetn),
	  .load_x(ld_x),
	  .load_y(ld_y),
	  .load_r(ld_r),
	  .load_c(ld_c),
	  .x_in(x_in),
	  .y_in(y_in),
	  .done(done),
	  .x(x),
	  .y(y)
	);

	control_draw c0(
	  .clk(clk),
	  .resetn(resetn),
	  .go(go),
	  .load_x(ld_x),
	  .load_y(ld_y),
	  .load_r(ld_r),
	  .load_c(ld_c),
	  .plot(plot)
	);


endmodule
module datapath_draw(clk,
	 	resetn,
		load_x,
		load_y,
		load_r,
		load_c,
		x_in,
		y_in,
		done,
		x,
		y);

	// Declaring the inputs and outputs of the module
	input clk;
	input resetn;
	input load_x;
	input load_y;
	input load_r;
	input load_c;
	input ld_alu_out;
	input [7:0] x_in;
	input [6:0] y_in;
	output reg done;
	output reg [7:0] x;
	output reg [6:0] y;
	// Declare the registers that we will have
	reg [7:0] x_reg;
	reg [6:0] y_reg;
	reg [4:0] counter;
	// Define the two outputs of our ALU unit
	reg [7:0] x_alu;
	reg [6:0] y_alu;

	//Input Logic for Load registers
	always@(posedge clk)
	begin: InputLogic
		if(!resetn) begin
			x_reg <=7'b0;
			y_reg <=6'b0;
		end
		else begin
		     if(load_x)
		    // Set x depending on the signal of ldu_alu_out, first 8 bits of the alu_out
				x_reg <= x_in;
		     if(load_y)
				y_reg <= y_in;
		end
	end

	//Output Result Register
	always@(posedge clk)
	begin:Output
		if(!resetn) begin
			x <= 7'b0;
			y <= 6'b0;
		end
		else
		   begin
		   if(load_r)
			x <=  x_alu;	// Indicate that we want to send the output
			y <=  y_alu; // Indicate that we want to send the output
	           end
	end

	//LOgic for the Counter register
	always@(posedge clk)
	begin:COUNTERLOGIC
		if(counter == 5'd25)
		    done <= 1'b0;
		    counter <= 5'd0;
		    done <= 1'b1; //Indicate that we finished counting
		if((!resetn))  //We will make a 5X5 square so count to 25
		    counter <= 5'd0; // When we reach 15 we reset it again and keep counting
		else begin
		    if(load_c == 1'b1)
		    done <= 1'b0;
		    counter <= counter + 1'b1; // add one on every clock edge
		end
	end

	// The ALU Implementation
	always@(*)
	begin:ALU
		if(!resetn) begin
			x_alu = 7'b0;
			y_alu = 6'b0;
		end
		else begin
			// We add the two most significant bits to Y and the least to X
			x_alu = x_reg + {6'd0, counter[1:0]};
			y_alu = y_reg + {4'b0,counter[4:2]};
		end
	end
endmodule

module control_draw(input clk,
		input resetn,
		input go,
		input done,
		output reg load_x, load_y, load_r, load_c,
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
		LOAD_X:	 next_state = go? LOAD_X_WAIT:LOAD_X;	//loop in its state until go signal goes high again
		LOAD_X_WAIT:  next_state = LOAD_Y; //loop in its state until go signal goes high again
		LOAD_Y: next_state = LOAD_Y_WAIT;//loop in its state until go signal goes high again
		LOAD_Y_WAIT: next_state =  DISPLAY_RESULT; //loop in its state until go signal goes high again
		DISPLAY_RESULT: next_state = done? FINISH:DISPLAY_RESULT; //loop in its state until go signal goes high again
		FINISH: next_state = go?LOAD_X:FINISH; //loop in FINISH until we have signal to leave it
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
	    plot = 1'b0;
	   load_c = 1'b0;
	   load_alu_out = 1'b0;
	   case(current_state)
		LOAD_X: begin
		  load_x = 1'b1; // send signal to allow X to be loaded
		  end
		LOAD_Y: begin
		  load_y = 1'b1; // send signal to allow Y to be loaded
		   end
		DISPLAY_RESULT: begin
		  load_x = 1'b0; // When we will perform the computation
		  load_y = 1'b0; // We dont want to load to overwrite values
		  load_r = 1'b1;
		  load_c = 1'b1;
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
