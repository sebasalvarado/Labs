// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on

module part1(
	SW,
	KEY,
	q,
	HEX0,
	HEX2,
	HEX4,
	HEX5
	);
	input	[9:0]SW;
	input	[3:0]KEY;
	output  [3:0] q;
	output	[6:0] HEX4, HEX5, HEX2, HEX0 ;
	
	wire [4:0]address;
	wire clk, wren;
	wire [3:0] input_data;
	wire [3:0] output_wire;
	// Assigning the wires to the input
	assign address = SW[8:4];
	assign clk = KEY[0];
	assign wren = SW[9];
	assign input_data = SW[3:0];

	ram32x4 ram1 (
		.address(address),
		.clock(clk),
		.data(input_data),
		.wren(wren),
		.q(output_wire)
	);
//Display the address as an output on HEX4 and HEX5
	hex_decoder hex4(
		.hex_digit(address[3:0]),
		.segments(HEX4)
	);

// Display the remaining bits of the address
	hex_decoder hex5(
		.hex_digit({3'b0,address[4]}),
		.segments(HEX5)
	);

//Display the input data on HEX2
	hex_decoder hex_data(
		.hex_digit(data),
		.segments(HEX2)
	);

//Display the output of the ram on HEX0
	hex_decoder hex_output(
		.hex_digit(output_data),
		.segments(HEX0)
	);

endmodule
module ram32x4 (
	address,
	clock,
	data,
	wren,
	q
	);
	input [4:0]address;
	input clock;
	input [3:0]data;
	input wren;
	output [3:0]q;
	
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [3:0] sub_wire0;
	wire [3:0] q = sub_wire0[3:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.width_a = 4,
		altsyncram_component.width_byteena_a = 1;


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


