
`include "opcodes.v"

module ProgramCounter(
input [1:0] PCSource, // jump address 00:sequential 01:offset jump 10: absolute jump
input [`WORD_SIZE - 1 : 0] next_target, // provide sequential or jump target
input PCRegWrite,
input PVSWrite, // PC proceed or not, raised at end of instruction execution
input reset_n,
input clk,
output [`WORD_SIZE - 1 : 0] next_PC_sequential,
output reg [`WORD_SIZE - 1 : 0] inst_addr
);

reg [`WORD_SIZE - 1 : 0] next_PC_sequential; // next sequential PC address register
reg [`WORD_SIZE - 1 : 0] next_PC_branch; // next sequential PC address register
reg reset_rest; // used for throwing away reset cycle

always @(posedge clk) begin

if(~reset_n) begin
inst_addr = 0;
reset_rest = 1; // raise on reset
end

else if(reset_rest) reset_rest = 0; // lower when reset is over

// proceed if PVSWrite is high
// PCSource is used as jump or not 0: sequential proceed 1: jump
else if(PVSWrite) inst_addr = ( PCSource == `PCaddr_Seq ? next_PC_sequential : // sequential proceed
                                PCSource == `PCaddr_Offset ? next_PC_branch : // branch execute
                                /* unconditional jump */ next_target ); // unconditional jump

// temporary save on register
else if(PCRegWrite) begin
inst_addr = inst_addr;
if(PCSource == `PCaddr_Seq) next_PC_sequential = next_target; // save next sequential PC address
else if(PCSource == `PCaddr_Offset) next_PC_branch = next_target;
end

end



endmodule