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

module Datapath(
    input reset_n,
    input clk,
    input [`opcode_loc_r - 1 : 0] opinstruction,
    input Jump,
    input [3 : 0] ALU_OP,
    input ALUSrc,
    input RegDst,
    input RegWrite,
    output [`WORD_SIZE - 1 : 0] output_data
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
    wire [`WORD_SIZE - 1 : 0] ALU_in_2;
    wire [`WORD_SIZE - 1 : 0] ALU_OUT;
    wire ALU_Overflow;
    
    assign rs = opinstruction[ `rs_loc_l : `rs_loc_r ];
    assign rt = opinstruction[ `rt_loc_l : `rt_loc_r ];
    assign rd = opinstruction[ `rd_loc_l : `rd_loc_r ];
    assign I_imm = { {8{opinstruction[`imm_loc_l]}},opinstruction[ `imm_loc_l : `imm_loc_r ]};
    assign J_target = opinstruction[ `target_loc_l : `target_loc_r ];
    
    assign write_addr = ( RegDst ? rd : rt );
    assign RF_write = ALU_OUT;

    assign ALU_in_2 = ( ALUSrc ? I_imm : RF_rt);
    
    RF RF_UUT ( RegWrite, clk, reset_n, rs, rt, write_addr, RF_rs, RF_rt, RF_write ) ;
    
    ALU ALU_UUT (RF_rs,ALU_in_2,1'b0,ALU_OP,ALU_OUT,ALU_Overflow);
    
    assign output_data = RF_rs;
    
endmodule
