`timescale 1ns / 1ns // `timescale time_unit/time_precision


module bit8register(SW, KEY, LEDR, HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    input [9:0] SW;
    input [3:0] KEY;
    output [7:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [3:0]B;
    wire [7:0] connection;
    wire [7:0] final;

    // Set HEX1 HEX2 and HEX 3 to 0
    assign HEX1[6:0] = 7'b100_0000;
    assign HEX2[6:0] = 7'b100_0000;
    assign HEX3[6:0] = 7'b100_0000;

    //Display the input in HEX0 given in SW[3:0]
    hex_decoder hex0(
            .hex_digit(SW[3:0]),
            .segments(HEX0[6:0])
    );
    //instantiate the ALU and connect its output to the register again
    alulogical alu(
        .A(SW[3:0]),
        .B(B),
        .option(KEY[3:1]),
        .out(connection)
    );
    //connect the output to anotther register

         register8bit secondregister(
            .clock(KEY[0]),
            .reset(SW[9]),
            .d(connection),
            .q(B),
            .q2(final)
        );

        assign LEDR[7:0] = final;
    hex_decoder output1(
        .hex_digit(final[3:0]),
        .segments(HEX4[6:0])
    );
    hex_decoder output2(
        .hex_digit(final[7:4]),
        .segments(HEX5[6:0])
        );

endmodule
module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;

    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'h7f;
        endcase
endmodule

module register8bit(clock,reset,d,q,q2);

    input clock;
    input reset;
    input [7:0]d;
    output [3:0]q;
    output [7:0] q2;
    dpositiveflipflop d1(
        .clock(clock),
        .reset(reset),
        .d(d[7]),
        .q(q2[7])
    );
    dpositiveflipflop d2(
        .clock(clock),
        .reset(reset),
        .d(d[6]),
        .q(q2[6])
    );
    dpositiveflipflop d3(
        .clock(clock),
        .reset(reset),
        .d(d[5]),
        .q(q2[5])
    );
    dpositiveflipflop d4(
        .clock(clock),
        .reset(reset),
        .d(d[4]),
        .q(q2[4])

    );
    dpositiveflipflop d5(
        .clock(clock),
        .reset(reset),
        .d(d[3]),
        .q(q2[3])

    );
    dpositiveflipflop d6 (
        .clock(clock),
        .reset(reset),
        .d(d[2]),
        .q(q2[2])
    );
    dpositiveflipflop d7(
        .clock(clock),
        .reset(reset),
        .d(d[1]),
        .q(q2[1])
    );
    dpositiveflipflop d8(
        .clock(clock),
        .reset(reset),
        .d(d[0]),
        .q(q2[0])
    );
    assign q = q2[3:0];

endmodule
module dpositiveflipflop(clock, reset,d,q);
    input clock;
    input reset;
    input d;
    output q;
    reg q;
    always@(posedge clock)
        begin
        if (reset == 1'b0)
            q<=0;
        else
            q<=d;
        end
endmodule
module full4adder(out,A,B);
    	input [3:0] A;
	input [3:0] B;
	output [7:0] out;
	wire connection1, connection2, connection3;

	 fulladder a1(
		.a(A[0]),
		.b(B[0]),
		.c0(1'b0),
		.s(out[0]),
		.c1(connection1)
	 );

	 fulladder a2(
		.a(A[1]),
		.b(B[1]),
		.c0(connection1),
		.s(out[1]),
		.c1(connection2)
	 );

	 fulladder a3(
		.a(A[2]),
		.b(B[2]),
		.c0(connection2),
		.s(out[2]),
		.c1(connection3)
	 );

	 fulladder a4(
		.a(A[3]),
		.b(B[3]),
		.c0(connection3),
		.s(out[3]),
		.c1(out[4])
	 );
endmodule

module fulladder(a,b,c0,s,c1);
    input a,b,c0;
    output s,c1;
    assign s = ~b&~a&c0 | ~b&a&~c0 | b&~a&~c0 | b&a&c0;
    assign c1 =b&c0 | a&c0 | a&b;
endmodule
module alulogical(A,B,option,out);
    input [3:0] A;
    input [3:0] B;
    input [2:0] option;
    output [7:0] out;
    reg [7:0] out;
    wire [7:0] adder;
    full4adder a1 (
	.out(adder),
	.A(A),
	.B(B)
);
    always@(*)
    begin
        case(option)
        3'b000: out = adder;
        3'b001: out = A +B;
        3'b010: out = {A |B, A ^B};
        3'b011: out = {7'b0000000,((|A) | (|B))};
        3'b100: out = {7'b0000000,((&A) & (&B))};
        3'b101: out = B << A;
        3'b110: out = B >>> A;
        3'b111:out = A * B;
        default:out = 8'b00000000;
	endcase
	end
endmodule
