module ALU #(
	parameter STACK_BEGIN = 16'h0010,
	parameter INPUT_BEGIN = 16'h0000,
	parameter SEG1_BEGIN = 16'h0001
)(
	input  wire clock,
	output wire[15:0] address_ram,
	input  wire[15:0] q_ram,
	output wire wren_ram,
	output wire[15:0] data_ram,
	output wire[15:0] address_rom,
	input  wire[15:0] q_rom,

	input wire SW[9:0],
	input wire KEY[1:0],
  	output wire[15:0] SEG1,
  	output wire[15:0] SEG2,
	
	output wire[15:0] out1,
	output wire[15:0] out2,
	output wire[15:0] out3,
	output wire[15:0] out4,
	output wire[15:0] out5,
	output wire[15:0] out6
);

reg[15:0] pc = 16'b0;
assign address_rom = pc;
reg[15:0] addr = 16'h0000;
assign address_ram = addr;
reg[15:0] data = 16'h0000;
assign data_ram = data;
reg[15:0] sp = STACK_BEGIN;
reg[15:0] fp = STACK_BEGIN;
reg wren = 0;
assign wren_ram = wren;

reg[15:0] mula, mulb;

wire[15:0] mul_out;
assign mul_out = mula * mulb;


typedef enum bit[15:0] {
	NOP   = 16'h0000,
	IGN   = 16'h0001,
	IMM   = 16'h0002,
	STOM  = 16'h0003,
	LOADM = 16'h0004,
	STOL  = 16'h0005,
	LOADL = 16'h0006,
	CP    = 16'h0007,
	JMP   = 16'h1000,
	BRA   = 16'h1001,
	SYNC  = 16'h1006,
	ADD   = 16'h2000,
	SUB   = 16'h2001,
	MUL   = 16'h2002,
	GRET  = 16'h2005,
	LESS  = 16'h2006,
	EQ    = 16'h2007,
	NEQ   = 16'h2008,
	AND   = 16'h2009,
	OR    = 16'h200a,
	XOR   = 16'h200b,
	NOT   = 16'h200c
} OPCODE;
OPCODE opcode;

enum bit[15:0] {
	INIT,
	PRE_FETCH_OPCODE,
	FETCH_OPCODE,
	READY,
	PRE_FETCH_OPERAND,
	FETCH_OPERAND,
	FETCHED_OPERAND,
	PRE_FETCH_STACK,
	FETCH_STACK,
	FETCHED_STACK,
	POST_FETCH_STACK,
	COMPLETE_STORE,
	ERROR = 16'hffff
} state = INIT;

reg[15:0] seg1;
reg[15:0] seg2;
assign SEG1 = seg1;
assign SEG2 = seg2;

reg[15:0] pc_dump;
reg[15:0] state_dump;
reg[15:0] opcode_dump;
reg[15:0] rom_dump;
reg[15:0] sp_dump;
reg[15:0] addr_dump;
assign out1 = pc_dump;
assign out2 = state_dump;
assign out3 = opcode_dump;
assign out4 = rom_dump;
assign out5 = sp_dump;
assign out6 = addr_dump;

always_ff @( posedge clock ) begin
	pc_dump <= pc;
	state_dump <= state;
	opcode_dump <= opcode;
	rom_dump <= q_rom;
	sp_dump <= sp;
	addr_dump <= addr;
end

reg[15:0] arg1;
reg[15:0] arg2;

always_ff @( posedge clock ) begin
	case ( state )
		ERROR: begin
		end
		INIT: begin
			pc <= 16'b0;
			state <= FETCH_OPCODE;
			wren <= 0;
		end
		PRE_FETCH_OPCODE: begin
			state <= FETCH_OPCODE;
		end
		FETCH_OPCODE: begin
			state <= READY;
		end
		default: begin
			if ( state == READY ) begin
				opcode = OPCODE'(q_rom);
				wren <= 0;
			end
			case ( opcode )
				NOP: begin
					case ( state )
						READY: begin
							pc <= pc + 16'b1;
							state <= PRE_FETCH_OPCODE;
						end
					endcase
				end
				IGN: begin
					case ( state )
						READY: begin
							pc <= pc + 16'h1;
							sp <= sp - 16'h1;
							state <= PRE_FETCH_OPCODE;
						end
					endcase
				end
				JMP: begin
					case ( state )
						READY: begin
							pc <= pc + 16'b1;
							state <= PRE_FETCH_OPERAND;
						end
						PRE_FETCH_OPERAND: begin
							state <= FETCH_OPERAND;
						end
						FETCH_OPERAND: begin
							state <= FETCHED_OPERAND;
						end
						FETCHED_OPERAND: begin
							pc <= q_rom;
							state <= PRE_FETCH_OPCODE;
						end
					endcase
				end
				IMM: begin
					case ( state )
						READY: begin
							state <= PRE_FETCH_OPERAND;
							pc <= pc + 16'b1;
						end
						PRE_FETCH_OPERAND: begin
							state <= FETCH_OPERAND;
						end
						FETCH_OPERAND: begin
							state <= FETCHED_OPERAND;
						end
						FETCHED_OPERAND: begin
							state <= PRE_FETCH_OPCODE;
							pc <= pc + 16'b1;
							sp <= sp + 16'b1;
							addr <= sp;
							data <= q_rom;
							wren <= 1;
						end
					endcase
				end
				NOT: begin
					case ( state )
						READY: begin
							state <= PRE_FETCH_STACK;
							addr <= sp - 16'h1;
							wren <= 0;
						end
						PRE_FETCH_STACK: begin
							state <= FETCH_STACK;
						end
						FETCH_STACK: begin
							wren <= 1;
							pc <= pc + 16'h1;
							data <= q_ram ^ 16'hffff;
							state <= PRE_FETCH_OPCODE;
						end
					endcase
				end
				CP: begin
					case ( state )
						READY: begin
							state <= PRE_FETCH_STACK;
							addr <= sp - 16'h1;
							wren <= 0;
						end
						PRE_FETCH_STACK: begin
							state <= FETCH_STACK;
						end
						FETCH_STACK: begin
							wren <= 1;
							addr <= sp;
							sp <= sp + 16'h1;
							pc <= pc + 16'h1;
							data <= q_ram;
							state <= PRE_FETCH_OPCODE;
						end
					endcase
				end
				STOM, STOL: begin
					case ( state )
						READY: begin
							addr <= sp - 16'h1;
							wren <= 0;
							state <= PRE_FETCH_STACK;
						end
						PRE_FETCH_STACK: begin
							state <= FETCH_STACK;
							addr <= sp - 16'h2;
						end
						FETCH_STACK: begin
							state <= FETCHED_STACK;
							arg1 <= q_ram;
						end
						FETCHED_STACK: begin
							sp <= sp - 16'h1;
							pc <= pc + 16'h1;
							wren <= 1;
							state <= PRE_FETCH_OPCODE;
							data <= q_ram;
							case ( opcode )
								STOL:
									addr <= fp + arg1;
								STOM:
									addr <= arg1;
							endcase
						end
					endcase
				end
				LOADL, LOADM: begin
					case ( state )
						READY: begin
							addr <= sp - 16'h1;
							wren <= 0;
							state <= FETCH_STACK;
						end
						FETCH_STACK: begin
							state <= FETCHED_STACK;
						end
						FETCHED_STACK: begin
							case ( opcode )
								LOADL:
									addr <= fp + q_ram;
								LOADM:
									addr <= q_ram;
							endcase
							state <= POST_FETCH_STACK;
						end
						POST_FETCH_STACK: begin
							state <= COMPLETE_STORE;
						end
						COMPLETE_STORE: begin
							pc <= pc + 16'h1;
							state <= PRE_FETCH_OPCODE;
							addr <= sp - 16'h1;
							wren <= 1;
							data <= q_ram;
						end
					endcase
				end
				BRA: begin
					case ( state )
						READY: begin
							addr <= sp - 16'h1;
							wren <= 0;
							state <= PRE_FETCH_STACK;
						end
						PRE_FETCH_STACK: begin
							state <= FETCH_STACK;
							addr <= sp - 16'h2;
						end
						FETCH_STACK: begin
							state <= FETCHED_STACK;
							arg1 <= q_ram;
						end
						FETCHED_STACK: begin
							sp <= sp - 16'h2;
							if ( arg1 != 0 ) begin
								pc <= q_ram;
							end
							else begin
								pc <= pc + 16'b1;
							end
							state <= PRE_FETCH_OPCODE;
						end
					endcase
				end
				MUL: begin
					case ( state )
						READY: begin
							addr <= sp - 16'h1;
							wren <= 0;
							state <= PRE_FETCH_STACK;
						end
						PRE_FETCH_STACK: begin
							state <= FETCH_STACK;
							addr <= sp - 16'h2;
						end
						FETCH_STACK: begin
							state <= FETCHED_STACK;
							arg1 <= q_ram;
						end
						FETCHED_STACK: begin
							mula <= q_ram;
							mulb <= arg1;
							state <= POST_FETCH_STACK;
						end
						POST_FETCH_STACK: begin
							state <= PRE_FETCH_OPCODE;
							sp <= sp - 16'h1;
							pc <= pc + 16'b1;
							addr <= sp - 16'h2;
							wren <= 1;
							data <= mul_out;
						end
					endcase
				end
				ADD, SUB, GRET, LESS, EQ, NEQ, AND, OR, XOR: begin
					case ( state )
						READY: begin
							addr <= sp - 16'h1;
							wren <= 0;
							state <= PRE_FETCH_STACK;
						end
						PRE_FETCH_STACK: begin
							state <= FETCH_STACK;
							addr <= sp - 16'h2;
						end
						FETCH_STACK: begin
							state <= FETCHED_STACK;
							arg1 <= q_ram;
						end
						FETCHED_STACK: begin
							sp <= sp - 16'h1;
							pc <= pc + 16'b1;
							addr <= sp - 16'h2;
							case ( opcode )
								ADD: begin
									data <= q_ram + arg1;
								end
								SUB: begin
									data <= q_ram - arg1;
								end
								GRET: begin
									if ( q_ram > arg1 )
										data <= 1;
									else
										data <= 0;
								end
								LESS: begin
									if ( q_ram < arg1 )
										data <= 1;
									else
										data <= 0;
								end
								EQ: begin
									if ( q_ram == arg1 )
										data <= 1;
									else
										data <= 0;
								end
								NEQ: begin
									if ( q_ram != arg1 )
										data <= 1;
									else
										data <= 0;
								end
								AND: begin
									data <= q_ram & arg1;
								end
								OR: begin
									data <= q_ram | arg1;
								end
								XOR: begin
									data <= q_ram ^ arg2;
								end
							endcase
							wren <= 1;
							state <= PRE_FETCH_OPCODE;
						end
					endcase
				end
				SYNC: begin
					case ( state )
						READY: begin
							addr <= SEG1_BEGIN;
							wren <= 0;
							state <= FETCH_STACK;
						end
						FETCH_STACK: begin
							addr <= INPUT_BEGIN;
							state <= FETCHED_STACK;
						end
						FETCHED_STACK: begin
							seg1 <= q_ram;
							wren <= 1;
							state <= POST_FETCH_STACK;
						end
						POST_FETCH_STACK: begin
							data <= { SW[9], SW[8], SW[7], SW[6], SW[5], SW[4], SW[3], SW[2], SW[1], SW[0], KEY[1], KEY[0] };
							pc <= pc + 16'h1;
							state <= PRE_FETCH_OPCODE;
						end
					endcase
				end
				default: begin
					state <= ERROR;
				end
			endcase
		end
	endcase
end

endmodule
