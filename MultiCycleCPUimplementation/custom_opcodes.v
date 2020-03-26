// opcode preprocessing macro
`define OPCODE_Rtype 4'hf

// defined in "constants.v"
// `define WORD_SIZE 16 // used for memory address bit no

`define instruction_bitno (`WORD_SIZE)

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
`define    OP_TCP  4'b0010
//  Bitwise Boolean operation
`define	OP_NOT	4'b0110
`define	OP_AND	4'b0111
`define	OP_ORR		4'b1000
// Shifting
`define	OP_SHL	4'b1010
`define	OP_SHR	4'b1011
`define	OP_LHI	4'b1101

// stage control unit encoding
`define STAGE_IF 3'b000
`define STAGE_ID 3'b100
`define STAGE_EX 3'b101
`define STAGE_MEM 3'b110
`define STAGE_WB 3'b111

// ALUSrcB encoding
`define ALUSrcA_Reg 2'b01
`define ALUSrcA_Inst 2'b00
`define ALUSrcA_Inst_Seq 2'b10

// ALUSrcB encoding
`define ALUSrcB_Reg 2'b00
`define ALUSrcB_Offset 2'b01
`define ALUSrcB_Seq 2'b10
`define ALUSrcB_Zero 2'b11


`define RegWriteSrc_PC 2'b10
`define RegWriteSrc_Memory 2'b01
`define RegWriteSrc_ALU 2'b00

`define PCaddr_Seq 2'b00
`define PCaddr_Offset 2'b01
`define PCaddr_Given 2'b11