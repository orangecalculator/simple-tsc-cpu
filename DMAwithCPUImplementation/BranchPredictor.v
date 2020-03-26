`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/04/29 17:19:57
// Design Name: 
// Module Name: BranchPredictor
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

`define BTBtag_bitno (`WORD_SIZE - `BTBidx_bitno)

`define BTBtag_initial ({`BTBtag_bitno{1'b1}})

`define BTBsize (1<<`BTBidx_bitno)
`define Predictor_takenmax ({`Predictor_bitno{1'b1}}) // indicate 111...1
`define Predictor_takenmin ({1<<(`Predictor_bitno-1)}) // indicate 111...1
`define Predictor_nottakenmmax (`Predictor_takenmin-`Predictor_bitno'h1) // indicate 0000
`define Predictor_nottakenmin (`Predictor_bitno'h0) // indicate 0000
`define Predictor_initial_nottaken ((1<<(`Predictor_bitno - 1)) - `Predictor_bitno'h1) // initializa as not taken
`define Predictor_initial_taken (1<<(`Predictor_bitno - 1)) // initializa as not taken
 
module BranchPredictor(
        input reset_n,
        input clk,
        input stall,
        input ID_nop,
        input jump_decision,
        input [`WORD_SIZE - 1 : 0] jump_target,
        input [`WORD_SIZE - 1 : 0] inst_addr,
        input [`WORD_SIZE - 1 : 0] next_addr_seq,
        output reg prediction_miss,
        output reg [`WORD_SIZE - 1 : 0] next_addr
    );
    
    // decompose current instruction address into tag and idx
    wire [`BTBtag_bitno - 1 : 0] addr_tag;
    wire [`BTBidx_bitno - 1 : 0] addr_idx;
    
    assign addr_tag = inst_addr[`WORD_SIZE - 1 : `WORD_SIZE - `BTBtag_bitno];
    assign addr_idx = inst_addr[`BTBidx_bitno - 1 : 0];
    
    // machine state register
    reg [`WORD_SIZE - 1 : 0] BranchTarget[`BTBsize - 1 : 0];
    reg [`Predictor_bitno - 1 : 0] PredictorState[`BTBsize - 1 : 0];
    reg [`BTBtag_bitno - 1 : 0] TagTable[`BTBsize - 1 : 0];
    
    // save update history for prediction miss
    wire Prediction_history;
    reg [`Predictor_bitno - 1 : 0] Predictor_history;
    reg [`BTBidx_bitno - 1 : 0] addr_idx_history;
    reg [`BTBtag_bitno - 1 : 0] addr_tag_history;
    reg [`WORD_SIZE - 1 : 0] Prediction_address_history;
    reg [`WORD_SIZE - 1 : 0] next_addr_seq_history;
    
    // predictor machine MSB is prediction
    assign Prediction_history = Predictor_history[`Predictor_bitno - 1];
    
    // prediction for current address
    wire Prediction_current;
    
    // which prediction method controlled by enable parameter
    assign Prediction_current = ( (TagTable[addr_idx] == addr_tag) && 
                                    (`Branch_Prediction_alwaystaken ? 1'b1 :
                                        `Branch_Prediction_alwaysnottaken ? 1'b0 :
                                        PredictorState[addr_idx][`Predictor_bitno - 1]) );
    
    // next address based on prediction
    wire [`WORD_SIZE - 1 : 0] next_pred_addr;
    
    assign next_pred_addr = (Prediction_current ? BranchTarget[addr_idx] :
                                                    next_addr_seq );
    
    // combinational logic for next state
    reg [`BTBidx_bitno - 1 : 0] update_idx;
    reg [`BTBtag_bitno - 1 : 0] update_tag;
    reg [`Predictor_bitno - 1 : 0] original_Pred_state;
    reg [`Predictor_bitno - 1 : 0] update_Pred_state;
    reg update_decision;
    reg reset_on_miss;
    reg [`WORD_SIZE - 1 : 0] update_addr_seq;
    
    always @(*) begin
        // prediction miss detection if prediction is wrong for jump
        if( ( (~jump_decision && (Prediction_address_history != next_addr_seq_history) )
            || (jump_decision && (Prediction_address_history != jump_target) ) ) && ~ID_nop) begin
            prediction_miss = 1'b1;
            update_idx = addr_idx_history;
            update_tag = addr_tag_history;
            reset_on_miss = (TagTable[update_idx] != update_tag);
            original_Pred_state = Predictor_history;
            update_decision = jump_decision;
            next_addr = (jump_decision ? jump_target : next_addr_seq_history);
            update_addr_seq = next_addr_seq_history;
        end
        else begin // on normal proceed
            prediction_miss = 1'b0;
            update_idx = addr_idx;
            update_tag = addr_tag;
            reset_on_miss = 1'b0;
            original_Pred_state = PredictorState[addr_idx];
            update_decision = PredictorState[addr_idx][`Predictor_bitno - 1];
            next_addr = next_pred_addr;
            update_addr_seq = next_addr_seq;
        end
        
        if(reset_on_miss) begin // correction on miss
            update_Pred_state = (update_decision ? `Predictor_initial_taken : `Predictor_initial_nottaken);
        end
        else if(update_tag != TagTable[update_idx]) update_Pred_state = original_Pred_state; // nothing happens on different tag
        else if(`Branch_Prediction_counter) begin // saturation counter prediction
            if(update_decision) begin
                if(original_Pred_state == `Predictor_takenmax) update_Pred_state = `Predictor_takenmax;
                else update_Pred_state = original_Pred_state + `Predictor_bitno'h1;
            end
            else begin
                if(original_Pred_state == `Predictor_nottakenmin) update_Pred_state = `Predictor_nottakenmin;
                else update_Pred_state = original_Pred_state - `Predictor_bitno'h1;
            end
        end
        else if(`Branch_Prediction_hysteric) begin // hysteresis counter prediction
            if(update_decision) begin
                if(original_Pred_state == `Predictor_takenmax || original_Pred_state == `Predictor_nottakenmmax) update_Pred_state = `Predictor_takenmax;
                else update_Pred_state = original_Pred_state + `Predictor_bitno'h1;
            end
            else begin
                if(original_Pred_state == `Predictor_nottakenmin || original_Pred_state == `Predictor_takenmin) update_Pred_state = `Predictor_nottakenmin;
                else update_Pred_state = original_Pred_state - `Predictor_bitno'h1;
            end
        end
        
    
    end
    
    //assign jump_decision = update_decision;
    
    // loop variable declaration
    integer it;
    
    always @(posedge clk) begin
        if(~reset_n) begin
            for(it=0;it<`BTBsize;it=it+1) begin
                BranchTarget[it] = 0;
                PredictorState[it] = `Predictor_initial_nottaken;
                TagTable[it] = `BTBtag_initial;
            end
        end
        else if(prediction_miss) begin // correction on prediction miss
            Predictor_history = Predictor_history;
            addr_idx_history = update_idx;
            addr_tag_history = update_tag;
            Prediction_address_history = next_addr;
            next_addr_seq_history = update_addr_seq;
            
            if(reset_on_miss) TagTable[update_idx] = update_tag;
            PredictorState[update_idx] = update_Pred_state;
            BranchTarget[update_idx] = jump_target;
        end
        else if(~stall) begin // normally proceed on not stall
            Predictor_history = PredictorState[update_idx];
            addr_idx_history = update_idx;
            addr_tag_history = update_tag;
            Prediction_address_history = next_addr;
            next_addr_seq_history = update_addr_seq;
            
            PredictorState[update_idx] = update_Pred_state;
            
        end
    end
    
endmodule
