
`include "opcodes.v"

module ProgramCounter(
input Jump,
input [`J_target_bitno - 1 : 0] J_target,
input reset_n,
input clk,
output reg [`WORD_SIZE - 1 : 0] inst_addr
);

always @(posedge clk) begin

if(~reset_n) inst_addr = 0;
else if(Jump) inst_addr
		= {inst_addr[`WORD_SIZE - 1 : `WORD_SIZE - 4] , J_target };
else 				inst_addr = inst_addr + `WORD_SIZE'h0001;

end



endmodule