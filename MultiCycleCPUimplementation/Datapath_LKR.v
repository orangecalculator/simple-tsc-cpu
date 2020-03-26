`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/04/12 12:40:48
// Design Name: 
// Module Name: Datapath
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// `include "opcodes.v"
// `include "custom_opcodes.v"
`include "constants.v"

module Datapath(
    input reset_n,
    input clk,
    input [`opcode_loc_r - 1 : 0] opinstruction,
    input [`WORD_SIZE - 1 : 0] MemData,
    input [`WORD_SIZE - 1 : 0] inst_seq_next_addr,
    input [`WORD_SIZE - 1 : 0] inst_addr,
    input [3 : 0] ALU_OP,
    input RegDst,
    input RegWrite,
    input [1:0] RegWriteSrc,
    input [1:0] ALUSrcA,
    input [1:0] ALUSrcB,
    output [1:0] ALU_Compare,
    output [`WORD_SIZE - 1 : 0] output_data,
    output [`WORD_SIZE - 1 : 0] RF_addr,
    output [`WORD_SIZE - 1 : 0] RF_data,
    output [`WORD_SIZE - 1 : 0] ALU_OUT
    );
    
    wire [`addr_bitno - 1 : 0] rs;
    wire [`addr_bitno - 1 : 0] rt;
    wire [`addr_bitno - 1 : 0] rd;
    wire [`WORD_SIZE /*I_imm_bitno*/ - 1 : 0] I_imm;
    wire [`J_target_bitno - 1 : 0] J_target;
    
    // Register File wires
    wire [`WORD_SIZE - 1 : 0] RF_rs;
    wire [`WORD_SIZE - 1 : 0] RF_rt;
    wire [`WORD_SIZE - 1 : 0] RF_write;
    wire [`addr_bitno - 1 : 0] write_addr;
    
    // ALU wires
    wire [`WORD_SIZE - 1 : 0] ALU_in_1;
    wire [`WORD_SIZE - 1 : 0] ALU_in_2;
    //wire [`WORD_SIZE - 1 : 0] ALU_OUT;
    wire ALU_Overflow;
    
    // datapath instruction decomposition
    assign rs = opinstruction[ `rs_loc_l : `rs_loc_r ];
    assign rt = opinstruction[ `rt_loc_l : `rt_loc_r ];
    assign rd = opinstruction[ `rd_loc_l : `rd_loc_r ];
    assign I_imm = { {8{opinstruction[`imm_loc_l]}},opinstruction[ `imm_loc_l : `imm_loc_r ]};
    assign J_target = opinstruction[ `target_loc_l : `target_loc_r ];
    
    // write address calculated by MJX (RegDst)
    assign write_addr = ( RegWriteSrc == `RegWriteSrc_PC ? 2'b10 :
                            RegDst ? rd : rt );
    
    // RF writing data
    // MUX to be added (MemtoReg)
    assign RF_write = (RegWriteSrc == `RegWriteSrc_ALU ? ALU_OUT :
                        RegWriteSrc == `RegWriteSrc_PC ? inst_seq_next_addr :
                        RegWriteSrc == `RegWriteSrc_Memory ? MemData : `WORD_SIZE'bx);

    // ALU second operand calculated by MUX (ALUSrc)
    assign ALU_in_1 = (ALUSrcA == `ALUSrcA_Reg ? RF_rs :
                        ALUSrcA == `ALUSrcA_Inst ? inst_addr : inst_seq_next_addr );
    assign ALU_in_2 = (ALUSrcB==`ALUSrcB_Reg ? RF_rt :
                        ALUSrcB==`ALUSrcB_Offset ? I_imm :
                        ALUSrcB==`ALUSrcB_Seq ? `WORD_SIZE'h0001:
                         /* ALUSrcB==`ALUSrcB_Zero */      0 );
    
    assign RF_addr = RF_rs;
    assign RF_data = RF_rt;
    
    RF RF_UUT ( RegWrite, clk, reset_n, rs, rt, write_addr, RF_rs, RF_rt, RF_write ) ;
    
    ALU ALU_UUT (ALU_in_1,ALU_in_2,1'b0,ALU_OP,ALU_OUT,ALU_Overflow,ALU_Compare);
    
    assign output_data = RF_rs;
    
endmodule
