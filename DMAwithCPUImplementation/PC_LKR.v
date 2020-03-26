
`include "opcodes.v"

module ProgramCounter(
        input reset_n,
        input clk,
        input stall,
        input ID_nop,
        input jump,
        input [`WORD_SIZE - 1 : 0] jump_target,
        input [`WORD_SIZE - 1 : 0] jump_num_inst,
        output reg [`WORD_SIZE - 1 : 0] inst_addr,
        output [`WORD_SIZE - 1 : 0] inst_seq_next_addr,
        output hazard_detected,
        output reg [`WORD_SIZE - 1 : 0] num_inst
    );
    
    // BranchPredictor -> PC
    wire [`WORD_SIZE - 1 : 0] next_addr;
    wire prediction_miss;
    
    // next sequential address to be used for PC, BranchPredictor, ID stage branch target calculation
    assign inst_seq_next_addr = inst_addr + `WORD_SIZE'h1;
    
    // BranchPredictor wire connection
    BranchPredictor BP_UUT(reset_n,clk,stall,ID_nop,jump,jump_target,inst_addr,inst_seq_next_addr,
                                                prediction_miss,next_addr);
    
    // Branch Predictor enable control interface
    assign hazard_detected = (`Branch_Predictor_Enable ? prediction_miss : jump);
    
    always @(posedge clk) begin
        
        if(~reset_n) begin // reset stage, note that reset is controlled by cpu idle stage machine
            inst_addr = 0;
            num_inst = 0;
        end
        else if(`Branch_Predictor_Enable) begin // if branch predictor enabled
            if(prediction_miss) begin // prediction miss override everything
                inst_addr = next_addr;
                num_inst = jump_num_inst + `WORD_SIZE'h1;
            end
            else if(~stall) begin // proceed on no stall
                inst_addr = next_addr;
                num_inst = num_inst + `WORD_SIZE'h1;
            end
            else begin
            inst_addr = inst_addr;
            num_inst = num_inst;
            end
        end
        else begin // if branch predictor disabled
            if(jump) begin // jump instruction overrides stall
                inst_addr = jump_target;
                num_inst = jump_num_inst + `WORD_SIZE'h1;
            end
            else if(~stall) begin // proceed on not stall
                inst_addr = inst_seq_next_addr;
                num_inst = num_inst + `WORD_SIZE'h1;
            end
            else begin
                inst_addr = inst_addr;
                num_inst = num_inst;
            end
        end
        
    
    end

endmodule