module random_painting(clk, resetn, go, x, y, plot, colour,done_out,plot);
     input clk, resetn, go;
     output [7:0] x;
     output [6:0] y;
     output plot, done_out;
     output [2:0] colour;

     assign colour = 3'b111;
     //Declare the wires that our modules will need
	wire [7:0] x_random_wire;
	wire [6:0] y_random_wire;
     //Declare the wires that go from the control to the datapath
	wire ld_x_wire, ld_y_wire, add_wire;
     //Declare wires from the control to the draw box
	wire go_wire;
     //Declare wires that go from the draw box to the control
        wire done_control;
     //Declare wires from datapath to control
	wire finish_wire;
     //Declasre wires from the datapath to the draw
	wire [7:0] x_in_wire;
	wire [6:0] y_in_wire;
	

	house_delivery h1(
	.clk(clk),
	.resetn(resetn),
	.x_out(x_random_wire),
	.y_out(y_random_wire)
	);

	control_random cont(
	.clk(clk),
	.resetn(resetn),
	.finish(finish_wire),
	.go_in(go),
	.done(done_control),
	.ld_x(ld_x_wire),
	.ld_y(ld_y_wire),
	.add(add_wire),
	.go(go_wire),
	.done_out(done_out)
	);	
	
	datapath_random data(
	.clk(clk),
	.resetn(resetn),
	.ld_x(ld_x_wire),
	.ld_y(ld_y_wire),
	.add(add_wire),
	.x_in(x_random_wire),
	.y_in(y_random_wire),
	.x_out(x_in_wire),
	.y_out(y_in_wire),
	.finish(finish_wire)
	);
	
	draw_box d1(
	.clk(clk),
	.resetn(resetn),
	.go(go_wire),
	.x_in(x_in_wire),
	.y_in(y_in_wire),
	.x(x),
	.y(y),
	.plot(plot),
	.done(done_control)
	);
	
endmodule


module control_random(clk, resetn, finish, go_in, done, ld_x, ld_y, add, go, done_out);
	input clk, resetn;
	input finish; //Signal from the datapath meaning we have counted x random boxes
	input go_in; //Input from user indicating we should start the computation
	input done; // When the box has been succesfully drew
	output reg ld_x, ld_y; //Signals to load x and y from the random generators
	output reg add; // Indicate to count up
	output reg go; // Indicate to the draw box to draw again
	output reg done_out; //Indicate to the top most module we already painted 8 boxes

	localparam START_STATE = 3'd0,
		   PAINT_BOX = 3'd1,
		   ADD_ONE = 3'd2,
		   ADD_ONE_WAIT = 3'd3,
		   LOAD_X_Y = 3'd4,
		   LOAD_X_Y_WAIT = 3'd5,
		   FINISH = 3'd6;
	reg [2:0] current_state, next_state;

	//Always block for the next state logic
	always@(*)
	begin:NextState
 	case(current_state)
		START_STATE: next_state = go_in? PAINT_BOX: START_STATE; //loop into start state until go_in is high
		PAINT_BOX: next_state = done? ADD_ONE: PAINT_BOX;
		ADD_ONE: next_state = ADD_ONE_WAIT; //Send a signal to count up on the next clock edge
		ADD_ONE_WAIT: next_state = LOAD_X_Y; //THis means we will count up now
		LOAD_X_Y: next_state = LOAD_X_Y_WAIT;
		LOAD_X_Y_WAIT: next_state = done_out? FINISH:PAINT_BOX; //When we finished painting x number of boxes stay in finish
		FINISH: next_state = go? START_STATE: FINISH; //When go is high again we can paint more random boxes
	endcase	
	end

	//Output Logic for the datapath
	always@(*)
	begin:OutputLog
	//Make all the signals low until we will set them in each state
		ld_x = 1'b0;
		ld_y = 1'b0;
		add = 1'b0;
		go = 1'b0;
		done_out = 1'b0;
		case(current_state)
			START_STATE: begin
			      ld_x = 1'b1;
			      ld_y = 1'b1;
			     end
			PAINT_BOX: begin
			        go = 1'b1;
		 		   end
			ADD_ONE: begin
				    add = 1'b1;
				  end
			ADD_ONE_WAIT: begin
				   add = 1'b1;
				  end
			LOAD_X_Y: begin
				   ld_x = 1'b1;
				   ld_y = 1'b1;
				   end
		endcase
	end

	//CHange of states
	always@(posedge clk)
	begin: States
	  if(!resetn)
		current_state <= START_STATE;
	  else
 		current_state <= next_state;
	end
endmodule



module datapath_random(clk, resetn, ld_x,ld_y,add,x_in,y_in,x_out, y_out, finish);
//Declare inputs and outputs of our module
    input clk, resetn, ld_x,ld_y, add;
    input [7:0] x_in; //The X coordinate given by the random generator
    input [6:0] y_in; //The Y coordinate given by the random generator
    output reg [7:0] x_out;
    output reg [6:0] y_out;
    output reg finish;

   //Declare the Datapath components that we will need
    reg [7:0] x_reg;
    reg [6:0] y_reg; 
    reg [3:0] box_counter;
    
   //Input logic for the load registers
   always@(posedge clk)
   begin:InputLogic
	if(!resetn) begin
	   x_reg <= x_in;
	   y_reg <= y_in;
        end
	else begin
	   if(ld_x && ld_y)
		x_reg <= x_in;
		y_reg <= y_in;
	end
   end
   
  //Output Logic of the module
  always@(*)
   begin:OutputLog
    if(!resetn)
	begin
	x_out <= x_in;
	y_out <= y_in;
	end
     else begin
	x_out <= x_reg;
	y_out <= y_reg;
	end
    end
  //Logic for the box counter
   always@(posedge clk)
   begin:Counter
      if(!resetn)
         box_counter <= 4'd0;
      if(box_counter === 4'd15)
	  box_counter <= 4'd0; //Reset the counter when we already counted 15 boxes
      else begin
          if(add)
	    box_counter <= box_counter + 4'd1;
          if(!add)
            box_counter <= box_counter;
	end
    end

    //Logic for the finish signal
    always@(posedge clk)
    begin:Finish
	  if(!resetn)
	      finish <= 1'b0;
          else begin
	      if(box_counter === 4'd15)
                  finish = 1'b1;
	      if(box_counter !== 4'd15)
		  finish = 1'b0;
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
// Module that chooses a coordinate to the pizza to be delivered
module house_delivery(clk, resetn, x_out, y_out);
	input clk;
	input resetn;
	// The coordinates of the house of the pizza to be delivered
	output reg [7:0]x_out;
	output reg [6:0]y_out;

	// The number that is randomly generated to be map to the coordinates of the house.
	wire [3:0]house_num;

	// Instanciation of the module that crates a 4 bit random number
	random_number RNG(
		.clk(clk),
		.resetn(resetn),
		.data_out(house_num)
		);

// Cases, that selects the coordinates of the house based on the random number
always @(*)
	begin: num_RGB	
	case(house_num)
		4'b0000: begin
			x_out = 8'd4;                       // if the number is 0000, the coordanate is x =4, y =4
			y_out = 7'd4;
			end  	    
		4'b0001: begin
			x_out = 8'd4; 
			y_out = 7'd36;       		    // if the number is 0001, the coordanate is x =4, y =36
			end
		4'b0010: begin
			x_out = 8'd4; 
			y_out = 7'd68;       		    // if the number is 0010, the coordanate is x =4, y =68
			end
		4'b0011: begin
			x_out = 8'd4; 
			y_out = 7'd100;        		    // if the number is 0011, the coordanate is x =4, y =100
			end
		4'b0100: begin 
			x_out = 8'd36; 
			y_out = 7'd4;       		    // if the number is 0100, the coordanate is x =36, y =4
			end
		4'b0101: begin
			x_out = 8'd52; 
			y_out = 7'd36;      		    // if the number is 0101, the coordanate is x =52, y =36
			end
		4'b0110: begin
			x_out = 8'd52; 
			y_out = 7'd68;            	    // if the number is 0110, the coordanate is x =52, y =68
			end
		4'b0111: begin
			x_out = 8'd52; 
			y_out = 7'd100;     		    // if the number is 0111, the coordanate is x =52, y =100
			end
		4'b1000: begin
			x_out = 8'd68; 
			y_out = 7'd4;       		    // if the number is 1000, the coordanate is x =68, y =4
			end
		4'b1001: begin
			x_out = 8'd100; 
			y_out = 7'd36;     		    // if the number is 1001, the coordanate is x =100, y =36
			end
		4'b1010: begin
			x_out = 8'd100; 
			y_out = 7'd68;     		    // if the number is 1010, the coordanate is x =100, y =68
			end
		4'b1011: begin
			x_out = 8'd100; 
			y_out = 7'd100;    		    // if the number is 1011, the coordanate is x =100, y =100
			end
		4'b1100: begin
			x_out = 8'd100; 
			y_out = 7'd4;     		    // if the number is 1100, the coordanate is x =100, y =4
			end
		4'b1101: begin
			x_out = 8'd148; 
			y_out = 7'd36;     		    // if the number is 1101, the coordanate is x =148, y =36
			end
		4'b1110: begin
			x_out = 8'd148; 
			y_out = 7'd68;     		    // if the number is 1110, the coordanate is x =148, y =68
			end
		4'b1111: begin
			x_out = 8'd148; 
			y_out = 7'd100;    		    // if the number is 1111, the coordanate is x =148, y =100
			end
	endcase
	end
endmodule


// Module that generated a random 4 bit number.
module random_number(clk, resetn, data_out);
	input clk;
	input resetn;
	output reg [3:0]data_out;

	always@(posedge clk)
	begin:Random
		data_out <= {28'd0, 4'b1111}&{$random()};
	end
endmodule 
