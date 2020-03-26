
// activation setting parameters
    // forwarding unit activation
`define Forwarding_Enable 1'b1 // this overrides register
`define Forwarding_Register 1'b1 // register write negedge (not specific implementation)

    // branch predictor activation
`define Branch_Predictor_Enable 1'b1 // enable branch predictor
`define Branch_Prediction_alwaystaken 1'b0 // this overrides all choices
`define Branch_Prediction_alwaysnottaken 1'b0 // this overrides counter
`define Branch_Prediction_counter 1'b0 // counter <-> hysteric
`define Branch_Prediction_hysteric (1'b1 - `Branch_Prediction_counter)

    // cache activation
`define Cache_Latency_Apply 1'b1 // memory latency 1(ideal) <-> 2(one stall)
`define Cache_Activate 1'b1 // cache active or not
`define Cache_Write_Through 1'b0
`define Cache_Write_Back (1'b1 - (`Cache_Write_Through))
`define Cache_Write_Latency_Active 1'b1 // write miss latency activation on writethrough

    // dma configuration
`define DMA_Activate 1'b1
`define Cycle_Steal_Activate 1'b0

`define BTBidx_bitno 5
`define Predictor_bitno 2

`define Block_bitno 2
`define CacheIdx_bitno 2


// opcode preprocessing macro
`define OPCODE_Rtype 4'hf
`define OPCODE_NOP 4'hc
`define INST_FLUSH ({`OPCODE_NOP,`J_target_bitno'h0})

// defined in "constants.v"
// `define WORD_SIZE 16 // used for memory address bit no

`define instruction_bitno (`WORD_SIZE)

`define opcode_bitno 4
`define addr_bitno 2
`define R_funct_bitno 6
`define I_imm_bitno 8
`define J_target_bitno 12

`define ALU_opcode_bitno 4

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
`define    OP_ID   4'b0011
//  Bitwise Boolean operation
`define	OP_NOT	4'b0110
`define	OP_AND	4'b0111
`define	OP_ORR	4'b1000
// Shifting
`define	OP_SHL	4'b1010
`define	OP_SHR	4'b1011
`define	OP_LHI	4'b1101

// RegDst encoding
`define RegDst_rt 2'b00
`define RegDst_rd 2'b01
`define RegDst_Link 2'b10

//ALUSrc encoding
`define ALUSrc_rt 2'b00
`define ALUSrc_imm 2'b01
`define ALUSrc_zero 2'b10

// ALUcompare
`define ALUcompare_equal 2'b00
`define ALUcompare_positive 2'b10
`define ALUcompare_negative 2'b11

// Jump Indicator
`define Jump_idle 3'b000
`define Jump_JR   3'b001
`define Jump_J    3'b010
`define Jump_BEQ  3'b100
`define Jump_BNE  3'b101
`define Jump_BGZ  3'b110
`define Jump_BLZ  3'b111

// STAGE encoding
`define STAGE_ID  2'b00
`define STAGE_EX  2'b01
`define STAGE_MEM 2'b10
`define STAGE_WB  2'b11

// Cache Pending State encoding

`define Pending_Idle 2'b00
`define Pending_Write 2'b10
`define Pending_Read 2'b01
`define Pending_Ready 2'b11
