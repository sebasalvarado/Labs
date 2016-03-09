module clock50_counter(SW, CLOCK_50,HEX0);
    input CLOCK_50;
    input [9:7]SW;// Signal for Enable SW[9] Signal for clear SW[8]
    input [1:0]SW; //Switches to indicate chosen frequency of clock
    input [5:2]SW; //These are the switches that make a current load
    output [6:0]HEX0;


endmodule

module displaycounter(clock, enable, clear, parLoad, HEX0);
    input clock;
    input enable;
    input clearl
    output HEX0;
    
endmodule
module ratedivider(options,clock,load, enable,clear,load,q);
    input clock;
    input [1:0]options;
    input load;
    input enable;
    input clear;
    output pulse;
    wire [27:0]wire1;

    // We will load a value depending on the input that we get

    reg [27:0]count;
    always@(posedge clock)
    begin
        if(enable == 1'b1)
            count<=count-1;
        if(clear == 1'b0)
            count<=0;
        else if(load ==1'b1 && options[1] == 1'b0 && options[0] == 1'b1)
            //load it with 50 million - 1 for 1 HZ
            count<=28'b0010111110101111000001111111;
        else if(load ==1'b1 && options[1] == 1'b1 && options[0] == 1'b0)
            //Load with 100 million - 1 for 0.5Hz
            count<=28'b101111101011110000011111111;
        else if(load ==1'b1 && options[1] == 1'b1 && options[0] == 1'b1)
            //Load with 200 million -1 for 0.25Hz
            count<=28'b1011111010111100000111111111;
    end

    assign wire1 = count;

    // in count we have the current number depending on our four cases
    // we will wish that our pulse signal follow that

    reg pulse;
    //In this always block we will give the output of the pulse
    always@(posedge clock)
     begin
        if(options[1] == 1'b1 && options[0] == 1'b0)
            // We just make pulse 1 everytime
            pulse = 1'b1;
        else if(wire1 == 28'b0)
	//If we have reached zero then we
		pulse = 1'b1;
     end

endmodule