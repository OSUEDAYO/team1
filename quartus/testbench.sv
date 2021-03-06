`timescale 10ns / 1ns
module testbench; 
	reg SW[9:0];
	reg KEY[1:0];
	wire LEDR[9:0];
	reg CLK1_50;
	wire [3:0] VGA_R;
	wire [3:0] VGA_G;
	wire [3:0] VGA_B;
	wire VGA_HS;
	wire VGA_VS;
	wire[15:0] PC;
	wire[15:0] STATE;
	wire[15:0] OPCODE;
	wire[15:0] ROM;
	wire[15:0] SP;
	wire[15:0] ADDR;
	wire[7:0] HEX0;
	wire[7:0] HEX1;
	wire[7:0] HEX2;
	wire[7:0] HEX3;
	wire[7:0] HEX4;
	wire[7:0] HEX5;


	CPU DUT(
		.CLK1_50(CLK1_50),
		.SW(SW),
		.KEY(KEY),
		.LEDR(LEDR),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.OUT1(PC),
		.OUT2(STATE),
		.OUT3(OPCODE),
		.OUT4(ROM),
		.OUT5(SP),
		.OUT6(ADDR),
		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX2(HEX2),
		.HEX3(HEX3),
		.HEX4(HEX4),
		.HEX5(HEX5)
	);

	initial begin
		SW[9:0] = '{ 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0 };
		KEY[1:0] = '{1'b1, 1'b0};
	end

	initial begin
		CLK1_50 = 0;
		#5;
		forever begin
			CLK1_50 = 1;
			#5 CLK1_50 = 0;
			#5;
		end
	end

	initial begin
		KEY[0] = 0;
		#1000;
		KEY[0] = 1;
	end

	initial #2000000
		$stop;
endmodule
