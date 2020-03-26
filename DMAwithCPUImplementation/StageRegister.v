`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/04/29 21:46:17
// Design Name: 
// Module Name: StageRegister
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

`include "constants.v"
`include "custom_opcodes.v"

// IF/ID pipeline register
module IFIDRegister(
        input reset_n,
        input clk,
        input stall,
        input flush,
        input [`opcode_bitno - 1 : 0] IF_inst_addr_MSB,
        input [`WORD_SIZE - 1 : 0] IF_inst_addr_seq,
        input [`WORD_SIZE - 1 : 0] IF_instruction,        
        input [`WORD_SIZE - 1 : 0] IF_num_inst,
        //input jump_decision,
        output reg [`opcode_bitno - 1 : 0] ID_inst_addr_MSB,
        output reg [`WORD_SIZE - 1 : 0] ID_inst_addr_seq,
        output reg [`WORD_SIZE - 1 : 0] ID_instruction,
        output reg [`WORD_SIZE - 1 : 0] ID_num_inst
        //,reg ID_jump_decision;
    );
    
    
    
    always @(posedge clk) begin
        if(~reset_n || flush) begin // reset on reset or flush
            ID_inst_addr_MSB = 0;
            ID_inst_addr_seq = 0;
            ID_instruction = `INST_FLUSH;
            ID_num_inst = 0;
            //ID_jump_decision = 0;
        end
        else if(~stall) begin // proceed on not stall and not flush
            ID_inst_addr_MSB = IF_inst_addr_MSB;
            ID_inst_addr_seq = IF_inst_addr_seq;
            ID_instruction = IF_instruction;
            ID_num_inst = IF_num_inst;
            //ID_jump_decision = jump_decision;
        end
    end
    
endmodule

// ID/EX pipeline register
module IDEXRegister(
        input reset_n,
        input clk,
        input stall,
        input flush,
        input [`WORD_SIZE - 1 : 0] ID_inst_addr_seq,
        input [`WORD_SIZE - 1 : 0] ID_rs_value,
        input [`WORD_SIZE - 1 : 0] ID_rt_value,
        input [`WORD_SIZE - 1 : 0] ID_I_imm,
        input [`target_loc_l : `target_loc_r] ID_J_target,
        input [`addr_bitno - 1 : 0] ID_write_addr,
        input [`WORD_SIZE - 1 : 0] EX_rs_forwarded_value,
        input [`WORD_SIZE - 1 : 0] EX_rt_forwarded_value,
        output reg [`WORD_SIZE - 1 : 0] EX_inst_addr_seq,
        output reg [`WORD_SIZE - 1 : 0] EX_rs_value,
        output reg [`WORD_SIZE - 1 : 0] EX_rt_value,
        output reg [`WORD_SIZE - 1 : 0] EX_I_imm,
        output reg [`target_loc_l : `target_loc_r] EX_J_target,
        output reg [`addr_bitno - 1 : 0] EX_write_addr
    );
    
    always @(posedge clk) begin
        if(~reset_n || flush) begin // reset on reset or flush
            EX_inst_addr_seq = 0;
            EX_rs_value = 0;
            EX_rt_value = 0;
            EX_I_imm = 0;
            EX_J_target = 0;
            EX_write_addr = 0;
        end
        else if(~stall) begin // proceed on not stall and not flush
            EX_inst_addr_seq = ID_inst_addr_seq;
            EX_rs_value = ID_rs_value;
            EX_rt_value = ID_rt_value;
            EX_I_imm = ID_I_imm;
            EX_J_target = ID_J_target;
            EX_write_addr = ID_write_addr;
        end
        else begin
            EX_rs_value = EX_rs_forwarded_value;
            EX_rt_value = EX_rt_forwarded_value;
        end
    end
        
endmodule

// EX/MEM pipeline register
module EXMEMRegister(
        input reset_n,
        input clk,
        input stall,
        input flush,
        input [`WORD_SIZE - 1 : 0] EX_ALU_OUT,
        input [`WORD_SIZE - 1 : 0] EX_rt_value,
        input [`addr_bitno - 1 : 0] EX_write_addr,
        input [`WORD_SIZE - 1 : 0] MEM_rt_forwarded_value,
        output reg [`WORD_SIZE - 1 : 0] MEM_ALU_OUT,
        output reg [`WORD_SIZE - 1 : 0] MEM_rt_value,
        output reg [`addr_bitno - 1 : 0] MEM_write_addr
    );
    
    always @(posedge clk) begin
        if(~reset_n || flush) begin // reset on reset or flush
            MEM_ALU_OUT = 0;
            MEM_rt_value = 0;
            MEM_write_addr = 0;
        end
        else if(~stall) begin // proceed on not stall and not flush
            MEM_ALU_OUT = EX_ALU_OUT;
            MEM_rt_value = EX_rt_value;
            MEM_write_addr = EX_write_addr;
        end
        else MEM_rt_value = MEM_rt_forwarded_value;
    end
    
endmodule

// MEM/WB pipeline register
module MEMWBRegister(
        input reset_n,
        input clk,
        input stall,
        input flush,
        input [`WORD_SIZE - 1 : 0] MEM_read_data,
        input [`WORD_SIZE - 1 : 0] MEM_ALU_OUT,
        input [`addr_bitno - 1 : 0] MEM_write_addr,
        output reg [`WORD_SIZE - 1 : 0] WB_read_data,
        output reg [`WORD_SIZE - 1 : 0] WB_ALU_OUT,
        output reg [`addr_bitno - 1 : 0] WB_write_addr
    );
    
    always @(posedge clk) begin
        if(~reset_n || flush) begin // reset on reset or flush
            WB_read_data = 0;
            WB_ALU_OUT = 0;
            WB_write_addr = 0;
        end
        else if(~stall) begin // proceed on not stall and not flush
            WB_read_data = MEM_read_data;
            WB_ALU_OUT = MEM_ALU_OUT;
            WB_write_addr = MEM_write_addr;
        end
    end
    
endmodule

// EX stage control signal register
module EXControlRegister(
        input reset_n,
        input clk,
        input stall,
        input flush,
        input IN_ALUPathIntercept,
        input [1:0] IN_ALUSrc,
        input [`ALU_opcode_bitno - 1 : 0] IN_ALU_OP,
        output reg OUT_ALUPathIntercept,
        output reg [1:0] OUT_ALUSrc,
        output reg [`ALU_opcode_bitno - 1 : 0] OUT_ALU_OP
    );
    
    always @(posedge clk) begin
        if(~reset_n || flush) begin // reset on reset or flush
            OUT_ALUPathIntercept = 0;
            OUT_ALUSrc = 0;
            OUT_ALU_OP = 0;
        end
        else if(~stall) begin // proceed on not stall and not flush
            OUT_ALUPathIntercept = IN_ALUPathIntercept;
            OUT_ALUSrc = IN_ALUSrc;
            OUT_ALU_OP = IN_ALU_OP;
        end
    end

endmodule

// MEM stage control signal register
module MEMControlRegister(
        input reset_n,
        input clk,
        input stall,
        input flush,
        input IN_MemRead,
        input IN_MemWrite,
        output reg OUT_MemRead,
        output reg OUT_MemWrite
    );
    
    always @(posedge clk) begin
        if(~reset_n || flush) begin // reset on reset or flush
            OUT_MemRead = 0;
            OUT_MemWrite = 0;
        end
        else if(~stall) begin // proceed on not stall and not flush
            OUT_MemRead = IN_MemRead;
            OUT_MemWrite = IN_MemWrite;
        end
    end
    
endmodule

// WB stage control signal register
module WBControlRegister(
        input reset_n,
        input clk,
        input stall,
        input flush,
        input IN_MemtoReg,
        input IN_RegWrite,
        input IN_is_halted,
        output reg OUT_MemtoReg,
        output reg OUT_RegWrite,
        output reg OUT_is_halted
    );
    
    always @(posedge clk) begin
        if(~reset_n || flush) begin // reset on reset or flush
            OUT_MemtoReg = 0;
            OUT_RegWrite = 0;
            OUT_is_halted = 0;
        end
        else if(~stall) begin // proceed on not stall and not flush
            OUT_MemtoReg = IN_MemtoReg;
            OUT_RegWrite = IN_RegWrite;
            OUT_is_halted = IN_is_halted;
        end
    end
    
endmodule

// pipeline register for output port of CPU
module OutputRegister(
        input reset_n,
        input clk,
        input stall,
        input flush,
        input IN_output_update,
        input [`WORD_SIZE - 1 : 0] IN_num_inst,
        input [`WORD_SIZE - 1 : 0] IN_output_value,
        input [`WORD_SIZE - 1 : 0] IN_output_forwarded_value,
        output reg OUT_output_update,
        output reg [`WORD_SIZE - 1 : 0] OUT_num_inst,
        output reg [`WORD_SIZE - 1 : 0] OUT_output_value
    );
    
    always @(posedge clk) begin
        if(~reset_n || flush) begin // reset on reset or flush
            OUT_output_update = 0;
            OUT_num_inst = 0;
            OUT_output_update = 0;
        end
        else if(~stall) begin // proceed on not stall and not flush
            OUT_output_update = IN_output_update;
            OUT_num_inst = IN_num_inst;
            OUT_output_value = IN_output_value;
        end
        else OUT_output_value = IN_output_forwarded_value;
    end
    
endmodule

// pipeline register for hazard detection
module HazardRegister(
        input reset_n,
        input clk,
        input stall,
        input flush,
        input [`addr_bitno - 1 : 0] IN_rs_addr,
        input IN_rs_use,
        input [1:0] IN_rs_use_stage,
        input [`addr_bitno - 1 : 0] IN_rt_addr,
        input IN_rt_use,
        input [1:0] IN_rt_use_stage,
        input [1:0] IN_write_valid_stage,
        input IN_nop,
        output reg [`addr_bitno - 1 : 0] OUT_rs_addr,
        output reg OUT_rs_use,
        output reg [1:0] OUT_rs_use_stage,
        output reg [`addr_bitno - 1 : 0] OUT_rt_addr,
        output reg OUT_rt_use,
        output reg [1:0] OUT_rt_use_stage,
        output reg [1:0] OUT_write_valid_stage,
        output reg OUT_nop
    );
    
    always @(posedge clk) begin
        if(~reset_n || flush) begin // reset on reset or flush
            OUT_rs_addr = 0;
            OUT_rs_use = 0;
            OUT_rs_use_stage = 0;
            OUT_rt_addr = 0;
            OUT_rt_use = 0;
            OUT_rt_use_stage = 0;
            OUT_write_valid_stage = 0;
            OUT_nop = 1'b1;
        end
        else if(~stall) begin // proceed on not stall and not flush
            OUT_rs_addr = IN_rs_addr;
            OUT_rs_use = IN_rs_use;
            OUT_rs_use_stage = IN_rs_use_stage;
            OUT_rt_addr = IN_rt_addr;
            OUT_rt_use = IN_rt_use;
            OUT_rt_use_stage = IN_rt_use_stage;
            OUT_write_valid_stage = IN_write_valid_stage;
            OUT_nop = IN_nop;
        end
    end
    
endmodule