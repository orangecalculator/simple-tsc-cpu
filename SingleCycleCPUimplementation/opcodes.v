`define FUNC_ADD 6'd0
`define FUNC_SUB 6'd1
`define FUNC_AND 6'd2
`define FUNC_ORR 6'd3
`define FUNC_NOT 6'd4
`define FUNC_TCP 6'd5
`define FUNC_SHL 6'd6
`define FUNC_SHR 6'd7
`define FUNC_WWD 6'd28

`define OPCODE_ADI 4'd4
`define OPCODE_ORI 4'd5
`define OPCODE_LHI 4'd6
`define OPCODE_LWD 4'd7
`define OPCODE_SWD 4'd8
`define OPCODE_BNE 4'd0
`define OPCODE_BEQ 4'd1
`define OPCODE_BGZ 4'd2
`define OPCODE_BLZ 4'd3
`define OPCODE_JMP 4'd9
`define OPCODE_JAL 4'd10
`define OPCODE_Rty 4'hf

`define WORD_SIZE 16 // used for memory address bit no

`define instruction_bitno 16

`define opcode_bitno 4
`define addr_bitno 2
`define R_funct_bitno 6
`define I_imm_bitno 8
`define J_target_bitno 12

`define opcode_loc_l (`instruction_bitno - 1)
`define opcode_loc_r (`instruction_bitno - `opcode_bitno)
`define rs_loc_l (`opcode_loc_r - 1)
`define rs_loc_r (`opcode_loc_r - `addr_bitno)
`define rt_loc_l (`rs_loc_r - 1)
`define rt_loc_r (`rs_loc_r - `addr_bitno)
`define rd_loc_l (`rt_loc_r - 1)
`define rd_loc_r (`rt_loc_r - `addr_bitno)
`define funct_loc_l (`R_funct_bitno - 1)
`define funct_loc_r (0)
`define imm_loc_l (`I_imm_bitno - 1)
`define imm_loc_r (0)
`define target_loc_l (`J_target_bitno - 1)
`define target_loc_r (0)

// ALU instructions
// Arithmetic
`define	OP_ADD	4'b0000
`define	OP_SUB	4'b0001
//  Bitwise Boolean operation
`define	OP_ID		4'b0010
`define	OP_NAND	4'b0011
`define	OP_NOR	4'b0100
`define	OP_XNOR	4'b0101
`define	OP_NOT	4'b0110
`define	OP_AND	4'b0111
`define	OP_OR		4'b1000
`define	OP_XOR	4'b1001
// Shifting
`define	OP_LRS	4'b1010
`define	OP_ARS	4'b1011
`define	OP_RR		4'b1100
`define	OP_LHI	4'b1101
`define	OP_ALS	4'b1110
`define	OP_RL		4'b1111