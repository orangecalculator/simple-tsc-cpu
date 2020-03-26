///////////////////////////////////////////////////////////////////////////
// MODULE: Multi Cycle CPU for TSC microcomputer: cpu.v
// Author: Lee Kyeong Ryong (kryongleesec@gmail.com)
// Description: 

// DEFINITIONS

// INCLUDE files
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions
`include "custom_opcodes.v"
`include "constants.v"

// MODULE DECLARATION
module cpu (
        input Clk, 
        input Reset_N, 

	// Instruction memory interface
        output i_readM, 
        output i_writeM, 
        output [`WORD_SIZE-1:0] i_address, 
        inout [`WORD_SIZE-1:0] i_data, 

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [`WORD_SIZE-1:0] d_data, 
    
    // DMA handler
        input DMA_begin,
        input DMA_end,
        input Bus_Request,
        output Bus_Grant,
        output [2 * `WORD_SIZE : 0] DMA_command,
    
        // for debuging/testing purpose
      output reg [`WORD_SIZE-1:0] num_inst, // number of instruction during execution
      output reg [`WORD_SIZE-1:0] output_port, // this will be used for a "WWD" instruction
      output reg is_halted // 1 if the cpu is halted
  );


  // ... fill in the rest of the code
    
    // connect the old names with new names
    wire clk;
    wire reset_n;
    
    assign clk = Clk;
    assign reset_n = Reset_N;
    
    // zero stage machine
    reg reset_rest; // used for throwing away reset cycle
    
    // CPU <-> Memory wire
    wire [`WORD_SIZE - 1 : 0] IF_instruction;
    wire [`WORD_SIZE - 1 : 0] MEM_addr; // datapath -> Memory
    wire MEM_MemRead;
    wire MEM_MemWrite;
    wire WB_output_update;

    // wire ProgramCounter -> Datapath
    wire [`WORD_SIZE - 1 : 0] inst_addr;
    wire [`WORD_SIZE - 1 : 0] inst_seq_next_addr;
    wire [`WORD_SIZE - 1 : 0] IF_num_inst;
    wire [`opcode_bitno - 1 : 0] inst_addr_MSB;

    // wire ProgramCounter -> Control
    wire Branch_prediction_miss;

    // wire Control -> ProgramCounter
    wire IF_stall;

    // wire Control -> Datapath
    wire IFID_stall;
    wire IFID_flush;
    wire IDEX_stall;
    wire IDEX_flush;
    wire EXMEM_stall;
    wire EXMEM_flush;
    wire MEMWB_stall;
    wire MEMWB_flush;
    
    wire [1:0] ID_RegDst;
    wire [2:0] ID_Jump;
    wire ID_ALUPathIntercept;
    wire [1:0] ID_ALUSrc;
    wire [3:0] ID_ALU_OP;
    wire ID_MemRead;
    wire ID_MemWrite;
    wire ID_RegWrite;
    wire ID_MemtoReg;
    wire ID_output_active;
    wire ID_is_halted;
    
    wire ID_rs_use;
    wire [1:0] ID_rs_use_stage;
    wire ID_rt_use;
    wire [1:0] ID_rt_use_stage;
    wire [1:0] ID_write_valid_stage;
    
    // wire Datapath -> ProgramCounter
    wire ID_Jump_decision;
    wire [`WORD_SIZE - 1 : 0] ID_Jump_target;
    wire [`WORD_SIZE - 1 : 0] ID_num_inst;
    
    // wire Datapath -> Control
    wire [`opcode_bitno - 1 : 0] ID_opcode;
    wire [`R_funct_bitno - 1 : 0] ID_funct;
    
    // wire Datapath output
    wire [`WORD_SIZE - 1 : 0] MEM_write_data;
    wire [`WORD_SIZE - 1 : 0] MEM_read_data;
    wire [`WORD_SIZE - 1 : 0] WB_num_inst; // debugging wire WB
    wire WB_output_active;
    wire [`WORD_SIZE - 1 : 0] WB_output_write;
    wire WB_is_halted;
    
    wire ID_hazard_detected;
    wire EX_hazard_detected;
    wire MEM_data_hazard_detected;
    wire WB_hazard_detected;
    
    wire ID_nop;
    wire EX_nop;
    wire MEM_nop;
    wire WB_nop;
    
    // wire Cache -> CPU
    wire ICache_ready;
    wire DCache_ready;
    
    // wire Cache -> Datapath
    wire [`WORD_SIZE - 1 : 0] MEM_data;
    
    // wire CPU -> Control
    wire IF_hazard_detected;
    wire MEM_hazard_detected;
    
    // D_Cache -> DMAhandler
    wire dN_readM;
    wire dN_writeM;
    wire [`WORD_SIZE - 1 : 0] dN_address;
    wire [`WORD_SIZE - 1 : 0] dN_data;
    wire dN_ready;
    
    assign IF_hazard_detected = (Branch_prediction_miss || ~ICache_ready);
    assign MEM_hazard_detected = (MEM_data_hazard_detected || ~DCache_ready);
    
    assign MEM_data = (MEM_MemWrite ? MEM_write_data : `WORD_SIZE'hz);
    assign MEM_read_data = MEM_data;
    
    
    Cache I_Cache_UUT (reset_rest, clk, IF_stall, i_readM, i_writeM, i_address, i_data, 1'b1, 1'b1, 1'b0, inst_addr, IF_instruction , ICache_ready);
    Cache D_Cache_UUT (reset_rest, clk, EXMEM_stall, dN_readM, dN_writeM, dN_address, dN_data, dN_ready, MEM_MemRead, MEM_MemWrite, MEM_addr, MEM_data , DCache_ready);
    
    DMAhandler DMA_ex_UUT (reset_rest, clk, DMA_begin, DMA_end, Bus_Request, Bus_Grant, DMA_command, d_readM, d_writeM, d_address, d_data, dN_readM, dN_writeM, dN_address, dN_data, dN_ready );
    
    // Program Counter gives instruction address
    ProgramCounter PC_UUT ( reset_rest, clk, IF_stall, ID_nop, ID_Jump_decision, ID_Jump_target, ID_num_inst, inst_addr, inst_seq_next_addr, Branch_prediction_miss, IF_num_inst);

    // Control unit wire connection
    Control Ct_UUT (ID_opcode,ID_funct,
        ID_RegDst,ID_Jump,ID_ALUPathIntercept,ID_ALUSrc,ID_ALU_OP,ID_MemRead,ID_MemWrite,ID_RegWrite,ID_MemtoReg,ID_output_active,ID_is_halted,
        ID_rs_use,ID_rs_use_stage,ID_rt_use,ID_rt_use_stage,ID_write_valid_stage,
        IF_hazard_detected,ID_hazard_detected,EX_hazard_detected,MEM_hazard_detected,WB_hazard_detected,
        ID_nop,EX_nop,MEM_nop,WB_nop,
        IF_stall,IFID_stall,IFID_flush,IDEX_stall,IDEX_flush,EXMEM_stall,EXMEM_flush,MEMWB_stall,MEMWB_flush,WB_is_halted);

    // instruction address MSB passed for jump on ID
    assign inst_addr_MSB = inst_addr[`opcode_loc_l:`opcode_loc_r];

    // Datapath wire connection
    Datapath Dp_UUT (reset_rest, clk,
                        inst_addr_MSB, inst_seq_next_addr, IF_instruction, IF_num_inst, ID_opcode, ID_funct,
                        ID_RegDst,ID_Jump,ID_ALUPathIntercept,ID_ALUSrc,ID_ALU_OP,ID_MemRead,ID_MemWrite,ID_RegWrite,ID_MemtoReg,ID_output_active,ID_is_halted, 
                        ID_rs_use,ID_rs_use_stage,ID_rt_use,ID_rt_use_stage,ID_write_valid_stage,ID_Jump_decision,ID_Jump_target, ID_num_inst,
                        MEM_addr,MEM_MemRead,MEM_MemWrite,MEM_read_data,MEM_write_data,
                        WB_output_update,WB_num_inst,WB_output_write,WB_is_halted,
                        /*IF_hazard_detected,*/ID_hazard_detected,EX_hazard_detected,MEM_data_hazard_detected,WB_hazard_detected,
                        ID_nop,EX_nop,MEM_nop,WB_nop,
                        IFID_stall, IFID_flush, IDEX_stall,IDEX_flush,EXMEM_stall,EXMEM_flush,MEMWB_stall,MEMWB_flush
                        );
                        
    always @(posedge clk) begin

        if(~reset_n) begin // reset stage
            reset_rest = 1'b0;
            num_inst = 0;
            output_port = 0;
            is_halted = 0;
        end
        else if(~reset_rest) begin // idle stage
            reset_rest = 1'b1;
            num_inst = 0;
            output_port = 0;
            is_halted = 0;
        end
        else begin // execution of instruction, control registers commited from WB stage
            num_inst = WB_num_inst;
            if(WB_output_update) output_port = WB_output_write;
            is_halted = WB_is_halted;
        end

    end

// Branch Prediciton Statistics extraction (used for debugging)
// prints out the instruction execution history with memory address and branch prediction
`define Action_Idle 2'b00
`define Action_Read 2'b01
`define Action_Write 2'b10

    reg [`WORD_SIZE - 1 : 0] it;

    reg [`WORD_SIZE - 1 : 0] instruction_history [10'h3ff : 0];
    reg [`WORD_SIZE - 1 : 0] address_history [10'h3ff : 0];
    reg address_prediction_history_written [10'h3ff : 0];
    reg [`WORD_SIZE - 1 : 0] address_prediction_history [10'h3ff : 0];
    
    reg end_simulation;
    reg disp_I;
    reg disp_D;

// I-Cache Statistics extraction (used for debugging)
// prints out the Instruction Cache access execution history with memory address and Hit/Miss

    reg [`WORD_SIZE - 1 : 0] I_memory_address_history [10'h3ff : 0];
    reg [1:0] I_cache_action_history [10'h3ff : 0];
    reg [10'h3ff : 0] I_cache_hitmiss_history ;
    reg [10'h3ff : 0] I_cache_hitmiss_history_written ;

// D-Cache Statistics extraction (used for debugging)
// prints out the Instruction Cache access execution history with memory address and Hit/Miss

    reg [`WORD_SIZE - 1 : 0] D_memory_address_history [10'h3ff : 0];
    reg [1:0] D_cache_action_history [10'h3ff : 0];
    reg D_cache_hitmiss_history [10'h3ff : 0];
    reg D_cache_hitmiss_history_written [10'h3ff : 0];
    
    wire [`WORD_SIZE - 1 : 0] MEM_num_inst;
    assign MEM_num_inst = Dp_UUT.MEM_num_inst;
    
    always @(negedge clk) begin
        if(~reset_rest) begin
            for(it=0;it<`WORD_SIZE'h400;it = it + 1) begin
                instruction_history[it] = 0;
                address_history[it] = 0;
                address_prediction_history_written[it] = 0;
                address_prediction_history[it] = 0;
            end
            end_simulation = 0;
            for(it=0;it<`WORD_SIZE'h400;it = it + 1) begin
                I_memory_address_history[it] = 0;
                I_cache_action_history[it] = `Action_Idle;
                I_cache_hitmiss_history[it] = 0;
                I_cache_hitmiss_history_written[it] = 0;
            end
            disp_I = 0;
            for(it=0;it<`WORD_SIZE'h400;it = it + 1) begin
                D_memory_address_history[it] = 0;
                D_cache_action_history[it] = `Action_Idle;
                D_cache_hitmiss_history[it] = 0;
                D_cache_hitmiss_history_written[it] = 0;
            end
            disp_D = 0;
        end
        else if(~is_halted) begin
            instruction_history[IF_num_inst] = IF_instruction;
            address_history[IF_num_inst] = inst_addr;
            
            if(~address_prediction_history_written[IF_num_inst-`WORD_SIZE'h1]) begin
                address_prediction_history_written[IF_num_inst-`WORD_SIZE'h1] = 1'b1;
                address_prediction_history[IF_num_inst-`WORD_SIZE'h1] = inst_addr;
            end
            
            if(~I_cache_hitmiss_history_written[IF_num_inst] || I_memory_address_history[IF_num_inst] != inst_addr) begin
                I_cache_hitmiss_history_written[IF_num_inst] = 1'b1;
                I_memory_address_history[IF_num_inst] = inst_addr;
                I_cache_action_history[IF_num_inst]=`Action_Read;
                I_cache_hitmiss_history[IF_num_inst]=ICache_ready;
            end
            
            if(~D_cache_hitmiss_history_written[MEM_num_inst] || D_memory_address_history[MEM_num_inst] != MEM_addr) begin
                D_cache_hitmiss_history_written[MEM_num_inst] = 1'b1;
                D_memory_address_history[MEM_num_inst] = MEM_addr;
                D_cache_action_history[MEM_num_inst]= (MEM_MemRead ? `Action_Read : 
                                                        MEM_MemWrite ? `Action_Write :
                                                                    `Action_Idle);
                D_cache_hitmiss_history[MEM_num_inst]=DCache_ready;
            end
        end
        else if(is_halted && ~end_simulation) begin
                end_simulation = 1'b1;
                disp_I = 1'b1;
                for(it=0;it<`WORD_SIZE'h400;it = it + 1) begin
                    $display("%d %b %b %b %b %s %s %b %s %s",it, instruction_history[it],address_history[it],address_prediction_history[it],
                                                I_memory_address_history[it],(I_cache_action_history[it]==`Action_Read ? "R" : 
                                                                                    I_cache_action_history[it]==`Action_Write ? "W" :
                                                                                                                                  "X" ),
                                                                                    (I_cache_action_history[it]==`Action_Idle ? "X" : 
                                                                                    I_cache_hitmiss_history[it] ? "H" : "M"),
                                                D_memory_address_history[it],(D_cache_action_history[it]==`Action_Read ? "R" : 
                                                                                    D_cache_action_history[it]==`Action_Write ? "W" :
                                                                                                                                  "X" ),
                                                                                    (D_cache_action_history[it]==`Action_Idle ? "X" : 
                                                                                    D_cache_hitmiss_history[it] ? "H" : "M"));
                end
            end
    end
    // End of Statistics Analyzer
endmodule
//////////////////////////////////////////////////////////////////////////
