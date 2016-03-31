
//Possible Errors: Line 198 maybe go is 1 when we press it try switching sides of cases
module testpizza
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
	X,
	Y,
	PLOT,
	COLOUR
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	// Declare your inputs and outputs here
	output [7:0] X;
	output [6:0] Y;
	output PLOT;
	output [2:0] COLOUR;
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [1:0] direction;
	wire [7:0] x_wire;
	wire [6:0] y_wire;
	wire writeEn;
	wire go, resetn;
	//Assign corresponding keys into the wires.
	assign resetn = KEY[0];
	assign  go = KEY[1];
	assign direction = SW[1:0];

	move m0(
	.clk(CLOCK_50),
	.resetn(resetn),
	.go(go),
	.direction(direction),
	.x(X),
	.y(Y),
	.plot(PLOT),
	.colour(COLOUR)
	);
endmodule
module move(clk, resetn, go,direction, x,y,plot,colour);
  input clk, resetn, go;
  input [1:0] direction;
  output [7:0] x;
  output [6:0] y;
  output plot;
  output [2:0]colour;

//Declare the wires that we are going to need for the control and datapath
wire ld_x_wire, ld_y_wire,colour_signal_wire,dis_enable_wire;
wire [1:0] direction_wire;
//Declare wires from the FSM to the draw_box
wire go_draw;
//Declare wires from draw_box to FSM
wire done_wire;
//Declare wires from the datapath to the draw_box
wire [7:0] x_value;
wire [6:0] y_value;
//Declare wires from datapath to control
wire delay_signal_wire;
 control_move c0(
	.clk(clk),
	.resetn(resetn),
 	.done(done_wire),
        .go_in(go),
        .direction_in(direction),
        .curr_x(x_value),
        .curr_y(y_value),
        .delay_signal(delay_signal_wire),
        .colour_signal(colour_signal_wire),
	.direction(direction_wire),
        .display_enable(dis_enable_wire),
        .go(go_draw),
        .ld_x(ld_x_wire),
        .ld_y(ld_y_wire)
	);
  datapath_move data(
	.clk(clk),
        .resetn(resetn),
        .direction(direction_wire),
        .ld_x(ld_x_wire),
        .ld_y(ld_y_wire),
        .colour_signal(colour_signal_wire),
        .display_enable(dis_enable_wire),
        .colour_out(colour),
        .x_out(x_value),
	.y_out(y_value),
	.delay_signal(delay_signal_wire)
       );
   draw_box drawing(
	.clk(clk),
	.resetn(resetn),
	.go(go_draw),
	.x_in(x_value),
	.y_in(y_value),
	.x(x),
	.y(y),
	.plot(plot),
	.done(done_wire)
	);
endmodule
module control_move(clk, 
		resetn,
		done,go_in, direction_in,curr_x,curr_y, delay_signal,
		colour_signal,direction,display_enable, go,ld_x,ld_y);
 input clk, resetn, delay_signal;//Delay signal is high every time that we have counted 1/60th of a second
 input [1:0] direction_in; // Direction given from the user
 input [7:0] curr_x;
 input [6:0] curr_y;
 input go_in; //go signal given by the user
 input done; //The draw_box module indictes when it has finished painting
 input [1:0] direction_in; //Has the direction given by the user

 output reg colour_signal,ld_x,ld_y; //Indicate if we want to draw, 1 or erase 0
 output reg display_enable; // Signal to indicate to the delay counter to start countin
 output reg go; //Indicates to the draw box to draw a new box
 output reg [1:0] direction;

 localparam START_STATE = 3'd0,
            PAINT_BOX = 3'd1,
	    COUNT_FRAMES = 3'd2,
	    ERASE_BOX = 3'd3,
	    LOAD_X_Y = 3'd4,
	    LOAD_X_Y_WAIT = 3'd5;

  //Declare the registers that we will use in our implementation
        reg frames; //Frames indicate when we have counted 15 frames
        reg [1:0] direction_register;
	reg [3:0] frame_counter;
	reg [2:0] current_state, next_state;
	reg [2:0] seconds_counter; // Will count up to 4 signifying that a second has elapsed

	//State Table and Transition Logic
	always@(*)
	begin:StateTable
	  case(current_state)
	   START_STATE: next_state = (go_in)?PAINT_BOX:START_STATE; //loop in START until we press reset
	   PAINT_BOX: next_state = done? COUNT_FRAMES: PAINT_BOX; //loop in PAINT until the draw_box module drew the box
	   COUNT_FRAMES: next_state = frames? ERASE_BOX: COUNT_FRAMES; //loop in counting until we finish counting them
	   ERASE_BOX: next_state = done? LOAD_X_Y:ERASE_BOX; //loop in erasing the box until the draw_box indicates otherwise
	   LOAD_X_Y: next_state = LOAD_X_Y_WAIT;
	   LOAD_X_Y_WAIT: next_state = PAINT_BOX; //After I loaded my registers I have to paint the box again
	 endcase
	end


    //Logic for the Frame Signal
    always@(posedge clk)
    begin:FrameSignal
	if(!resetn)
		frames<= 1'b0;
	else begin
	  if((frame_counter) === 4'd15)
		frames <= 1'b1;
	  if((frame_counter) !== 4'd15)
		frames <=1'b0;
	end
   end
    //Frame counter logic
    always@(posedge clk)
    begin:FrameCount
      if(!resetn)
        frame_counter <= 4'd0; //Indicating we have not finished counting
      if((frame_counter) === 4'd15)
	 begin 
         frame_counter <= 4'd0; // Indicate that we finished counting
         end
      else begin
        if(delay_signal === 1'b1)
	  frame_counter <= frame_counter + 3'd1; //COunt up every time we get the signal from Delay Counter
	end
    end

    //Output Logic,signals for the datapath
    always@(*)
    begin:OutputLogic
    ld_x = 1'b0;
    ld_y = 1'b0;
    colour_signal = 1'b0;
    display_enable = 1'b0;
    go = 1'b0;
    direction = 2'b00;
    case(current_state)
      PAINT_BOX: begin
        colour_signal = 1'b1; //Indicate we want to paint
	go = (&(done) == 1'b1)?1'b0: 1'b1; 
	end
      COUNT_FRAMES: begin
        display_enable = 1'b1; //Indicate to keep counting up
        end
      ERASE_BOX: begin
        colour_signal = 1'b0; //Painting black
        go = 1'b1;
        end
      LOAD_X_Y:begin
	direction = direction_in;
	ld_x = 1'b1;
	ld_y = 1'b1;
	end
      LOAD_X_Y_WAIT:begin
	ld_x = 1'b1;
	ld_y = 1'b1;
	end
      endcase
      end
   // Next State Register Logic
   always@(posedge clk)
     begin:StateFFs
       if(!resetn)
         current_state <= START_STATE;
       else
          current_state <= next_state;
     end
endmodule

/* Module that implements the datapath of the movement it also gives the colour to the VGA
 * and gives the (x,y) position for the draw_box module
 */
module datapath_move(clk, resetn,direction,ld_x,ld_y,colour_signal,display_enable, colour_out, x_out, y_out,delay_signal);
input clk, resetn,colour_signal;
input ld_x, ld_y; //Indication to load the X and Y registers
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
    begin
    x_reg <= 8'd0; // Starting position will be zero
    y_reg <= 7'd21; //Initial position is (0,21)
    end
  else begin
  case(direction)
    2'b00:begin //We move to the right
        if(ld_x)
	 x_reg <= x_reg + 8'd1; //Add 1 to the right
	 end
    2'b01:begin
        if(ld_y)
         y_reg <= y_reg + 7'd1; //We are moving down add 1 to y
	 end
    2'b10: begin
        if(ld_x)
	  x_reg <= x_reg - 8'd1; //Moving to the left
	  end
    2'b11: begin
        if(ld_y)
	  y_reg <= y_reg - 7'd1; //Moving Up so we substract 1
	end
   endcase
   end
   end


reg [6:0] delay_counter;
//Count up to 1/60th of a second
always@(posedge clk)
  begin:DelayCounter
  if(!resetn)
    delay_counter <= 7'd0;
  if((delay_counter) === 7'd127)
    delay_counter <= 7'd0;
  if(!display_enable)
    delay_counter <= 7'd0; //When control has to reset the delay counter
  else
    delay_counter <= delay_counter + 7'd1; //Add one every clock edge
  end

//Delay signal logic
always@(posedge clk)
begin:DelaySig
	if(!resetn)
		delay_signal <= 1'b0;
	else begin
	   if((delay_counter) === 7'd63)
		delay_signal <= 1'b1;
	   if((delay_counter) !== 7'd63)
		delay_signal <= 1'b0;
	end
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
     if(&(colour_signal) == 1'b1)
       colour_out <= 3'b011; //Load yellow when we indicate that we will paint
     else begin
       if(&(colour_signal) != 1'b1)
         colour_out <= 3'b000; //Load black when we want to erase
	end
   end
endmodule


module draw_box(clk,resetn,go,x_in, y_in,x,y,plot,done);
	input clk;
	input resetn;
	input go;
	input [7:0] x_in;
	input [6:0] y_in;
	output [7:0] x;
	output [6:0] y;
	output plot;
	output done;
	//Declare the wires to connect control to datapath
	wire ld_x,ld_y, ld_r, ld_c;
	wire [1:0] clock_count;
	//DOne wire between data and FSM
	wire [3:0] counter_wire;

	datapath_draw d0 (
	  .clk(clk),
	  .resetn(resetn),
	  .load_x(ld_x),
	  .load_y(ld_y),
	  .load_r(ld_r),
	  .load_c(ld_c),
	  .x_in(x_in),
	  .y_in(y_in),
	  .clock_count(clock_count),
	  .counter(counter_wire),
	  .x(x),
	  .y(y)
	);

	control_draw c0(
	  .clk(clk),
	  .resetn(resetn),
	  .go(go),
	  .counter(counter_wire),
          .clock_count(clock_count),
	  .done_out(done),
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
		clock_count,
		counter,
		x,
		y);

	// Declaring the inputs and outputs of the module
	input clk;
	input resetn;
	input load_x;
	input load_y;
	input load_r;
	input load_c;
	input [7:0] x_in;
	input [6:0] y_in;
	output reg [3:0] counter;
	output reg [1:0] clock_count;
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
			x_reg <=7'b0;
			y_reg <=6'b0;
		end
		else begin
		     if(load_x && load_y)
			x_reg <= x_in;
			y_reg <= y_in;
		      if(!(load_x && load_y))
			begin
			x_reg <= x_reg;
			y_reg <= y_reg;
			end
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
		if(counter == 4'd15)
		    counter <= 4'd0;
		if((!resetn))  //We will make a 5X5 square so count to 25
		    begin
		    counter <= 4'd0; // When we reach 15 we reset it again and keep counting
		    end
		else begin
		    if(load_c)begin
		    	counter <= counter + 1'b1; // add one on every clock edge
			end
		end
	end
	
	always@(posedge clk)
	begin:CLock
		if(!resetn)
			clock_count <= 2'd0;
		else begin
		     if(clock_count == 2'd2)
			clock_count <= 2'd0;
		     if(load_x)
			clock_count <= clock_count + 2'd1;
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
			y_alu = y_reg + {5'b0,counter[3:2]};
		end
	end
endmodule

module control_draw(input clk,
		input resetn,
		input go,
		input [3:0] counter,
		input [1:0] clock_count,
		output reg done_out,
		output reg load_x, load_y, load_r, load_c,
		output reg plot);
	// Declare the State table to refer to it later
	localparam 
		   START_STATE = 3'd0,
		   LOAD_X_Y = 3'd1,
		   LOAD_X_Y_WAIT = 3'd2,
		   DISPLAY_RESULT = 3'd3,
		   FINISH = 3'd4,
		   WAIT = 3'd5;

	reg [2:0] current_state, next_state;
	reg [1:0] count_second;
	always@(posedge clk)
	begin:countSec
		if(!resetn)
			begin
			count_second <= 2'b00;
			end
		if(&(count_second) == 1'b1)
			count_second <= 2'b00;
		else begin
			count_second <= count_second + 2'b01;
		      end
	end
	// Create the always block for the next state logic
	always@(*)
	begin: state_table
	   case(current_state)
		START_STATE: next_state = go? LOAD_X_Y:START_STATE;
		LOAD_X_Y: next_state = (clock_count == 2'b10)? LOAD_X_Y_WAIT:LOAD_X_Y;	//loop in its state until go signal goes high again
		LOAD_X_Y_WAIT:  next_state = DISPLAY_RESULT; //loop in its state until go signal goes high again
		DISPLAY_RESULT: next_state = (&(counter) == 1'b1)? FINISH:DISPLAY_RESULT; //loop in its state until go signal goes high again
		FINISH: next_state = (&(clock_count) == 1'b1)?WAIT:FINISH; //loop in FINISH until we have signal to leave it
		WAIT: next_state = go? LOAD_X_Y: WAIT; //loop in WAIT until go signal
	   default: next_state = START_STATE;
	   endcase
	end // THis was the state table

	//Output logic, everything that the data path will receive as input goes here.
	always@(*)
	begin:OutLogic
	// Set all of them to zero
	   done_out = 1'b0;
	   load_x = 1'b0;
	   load_y = 1'b0;
           load_r = 1'b0;
	    plot = 1'b0;
	   load_c = 1'b0;
	   case(current_state)
		LOAD_X_Y: begin
		  load_x = 1'b1; // send signal to allow X to be loaded
		  load_y = 1'b1;
		  end
		DISPLAY_RESULT: begin
		  load_x = 1'b0; // When we will perform the computation
		  load_y = 1'b0; // We dont want to load to overwrite values
		  load_r = 1'b1;
		  load_c = 1'b1;
		  plot = 1'b1;
		  end
		FINISH: begin
		 done_out =1'b1;
		end
		WAIT: begin
		  done_out = 1'b0;
		end
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
endmodule
