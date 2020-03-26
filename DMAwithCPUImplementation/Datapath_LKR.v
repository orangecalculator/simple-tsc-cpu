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
`include "custom_opcodes.v"
`include "constants.v"

module Datapath(
        input reset_n,
        input clk,
        // IF stage
        input [`opcode_bitno - 1 : 0] IF_inst_addr_MSB,
        input [`WORD_SIZE - 1 : 0] IF_inst_addr_seq,
        input [`WORD_SIZE - 1 : 0] IF_instruction,
        input [`WORD_SIZE - 1 : 0] IF_num_inst,
        
        // ID stage
        
        output [`opcode_bitno - 1 : 0] ID_opcode,
        output [`R_funct_bitno - 1 : 0] ID_funct,
        
        input [1:0] ID_RegDst,
        input [2:0] ID_Jump,
        input ID_ALUPathIntercept,
        input [1:0] ID_ALUSrc,
        input [3:0] ID_ALU_OP,
        input ID_MemRead,
        input ID_MemWrite,
        input ID_RegWrite,
        input ID_MemtoReg,
        input ID_output_update,
        input ID_is_halted,
        
        input ID_rs_use,
        input [1:0] ID_rs_use_stage,
        input ID_rt_use,
        input [1:0] ID_rt_use_stage,
        input [1:0] ID_write_valid_stage,
        
        output ID_Jump_decision_pass,
        output reg [`WORD_SIZE - 1 : 0] ID_Jump_target,
        output [`WORD_SIZE - 1 : 0] ID_num_inst,
        
        // MEM stage
        output [`WORD_SIZE - 1 : 0] MEM_addr,
        output MEM_MemRead,
        output MEM_MemWrite,
        input [`WORD_SIZE - 1 : 0] MEM_read_data,
        output [`WORD_SIZE - 1 : 0] MEM_write_data,
        
        // WB stage
        output WB_output_update,
        output [`WORD_SIZE - 1 : 0] WB_num_inst,
        output [`WORD_SIZE - 1 : 0] WB_output_value, // provide RF value for jr
        output WB_is_halted,
        
        // Hazard detection
        //output reg IF_hazard_detected,
        output reg ID_hazard_detected,
        output reg EX_hazard_detected,
        output reg MEM_hazard_detected,
        output WB_hazard_detected,
        input ID_nop,
        output EX_nop,
        output MEM_nop,
        output WB_nop,
        
        // Hazard resolve
        input IFID_stall,
        input IFID_flush,
        input IDEX_stall,
        input IDEX_flush,
        input EXMEM_stall,
        input EXMEM_flush,
        input MEMWB_stall,
        input MEMWB_flush
    );
    
    
    
    //assign output_data = RF_rs;

//-------------------------------------------------------------------------------------------------------------------------------------------
    
    // IF wire

    // IF control wire
    //input IFID_stall
    //input IFID_flush
    
    // ID wire
    // instruction information
    wire [`WORD_SIZE - 1 : 0] ID_instruction;
    wire [`opcode_bitno - 1 : 0] ID_inst_addr_MSB;
    wire [`WORD_SIZE - 1 : 0] ID_inst_addr_seq;
    
    // instruction decomposition
    wire [`addr_bitno - 1 : 0] ID_rs;
    wire [`addr_bitno - 1 : 0] ID_rt;
    wire [`addr_bitno - 1 : 0] ID_rd;
    wire [`WORD_SIZE /*I_imm_bitno*/ - 1 : 0] ID_I_imm;
    wire [`J_target_bitno - 1 : 0] ID_J_target;
    wire [`WORD_SIZE - 1 : 0] RF_rs_value;
    wire [`WORD_SIZE - 1 : 0] RF_rt_value;
    reg [`WORD_SIZE - 1 : 0] ID_rs_value;
    reg [`WORD_SIZE - 1 : 0] ID_rt_value;
    
    // logic wire
    wire [`addr_bitno - 1 : 0] ID_write_addr;
    
    wire [`WORD_SIZE - 1 : 0] ID_write_value;
    
    // ID control wire
    //wire ID_RegDst;
    //wire IDEX_stall;
    //wire IDEX_flush;
    
    // wire [2:0] ID_Jump; // declared on input
    //wire [1:0] ID_ALUSrc;
    //wire [`ALU_opcode_bitno - 1 : 0] ID_ALU_OP;
    
    //wire ID_MemRead;
    //wire ID_MemWrite;
    
    //wire ID_MemtoReg;
    //wire ID_num_inst;
    //wire ID_output_update;
    //wire ID_is_halted;
    reg ID_Jump_decision;

    wire ID_need_rs;
    wire ID_need_rt;
    wire ID_write_data_valid;
    
    // EX wire
    // instruction information
    //wire [`opcode_bitno - 1 : 0] EX_inst_addr_MSB;
    wire [`WORD_SIZE - 1 : 0] EX_inst_addr_seq;
    
    wire [`WORD_SIZE - 1 : 0] EX_rs_passed_value;
    wire [`WORD_SIZE - 1 : 0] EX_rt_passed_value;
    reg [`WORD_SIZE - 1 : 0] EX_rs_value;
    reg [`WORD_SIZE - 1 : 0] EX_rt_value;
    wire [`WORD_SIZE - 1 : 0] EX_ALU_in_1;
    wire [`WORD_SIZE - 1 : 0] EX_ALU_in_2;
    wire [`WORD_SIZE - 1 : 0] EX_ALU_OUT;
    //wire [`WORD_SIZE - 1 : 0] EX_Jump_target;
    wire [`WORD_SIZE /*I_imm_bitno*/ - 1 : 0] EX_I_imm;
    wire [`J_target_bitno - 1 : 0] EX_J_target;
    
    wire [`WORD_SIZE - 1 : 0] EX_write_value;
    
    //wire [`addr_bitno - 1 : 0] EX_write_addr;
    
    // EX control wire
    wire EX_ALU_Compare;
    //wire EXMEM_stall;
    //wire EXMEM_flush;
    
    //wire [2:0] EX_Jump;
    wire EX_ALUPathIntercept;
    wire [1:0] EX_ALUSrc;
    wire [`ALU_opcode_bitno - 1 : 0] EX_ALU_OP;
    
    wire EX_MemRead;
    wire EX_MemWrite;
    
    wire EX_RegWrite;
    wire [`addr_bitno - 1 : 0] EX_write_addr;
    
    wire EX_MemtoReg;
    wire [`WORD_SIZE - 1 : 0] EX_num_inst;
    wire EX_is_halted;
    
    wire EX_output_update;
    wire [`WORD_SIZE - 1 : 0] EX_output_value;
    
    wire [`addr_bitno - 1 : 0] EX_rs;
    wire EX_rs_use;
    wire [1:0] EX_rs_use_stage;
    wire [`addr_bitno - 1 : 0] EX_rt;
    wire EX_rt_use;
    wire [1:0] EX_rt_use_stage;
    wire [1:0] EX_write_valid_stage;
    
    wire EX_need_rs;
    wire EX_need_rt;
    wire EX_write_data_valid;
    
    // MEM wire
    wire [`WORD_SIZE - 1 : 0] MEM_ALU_OUT;
    reg [`WORD_SIZE - 1 : 0] MEM_rt_value;
    //wire [`WORD_SIZE - 1 : 0] MEM_read_data;
    
    //wire [`addr_bitno - 1 : 0] MEM_write_addr;
    
    wire [`WORD_SIZE - 1 : 0] MEM_rt_passed_value;
    wire [`WORD_SIZE - 1 : 0] MEM_write_value;
    
    // MEM control wire
    //wire MEMWB_stall;
    //wire MEMWB_flush;
    
    //wire MEM_MemRead;
    //wire MEM_MemWrite;
    
    wire MEM_RegWrite;
    wire [`addr_bitno - 1 : 0] MEM_write_addr;
    
    wire MEM_MemtoReg;
    wire [`WORD_SIZE - 1 : 0] MEM_num_inst;
    wire MEM_is_halted;
    
    wire MEM_output_update;
    wire [`WORD_SIZE - 1 : 0] MEM_output_passed_value;
    reg [`WORD_SIZE - 1 : 0] MEM_output_value;
    
    wire [`addr_bitno - 1 : 0] MEM_rs;
    wire MEM_rs_use;
    wire [1:0] MEM_rs_use_stage;
    wire [`addr_bitno - 1 : 0] MEM_rt;
    wire MEM_rt_use;
    wire [1:0] MEM_rt_use_stage;
    wire [1:0] MEM_write_valid_stage;
    
    wire MEM_need_rs;
    wire MEM_need_rt;
    wire MEM_write_data_valid;
    
    // WB wire
    wire [`WORD_SIZE - 1 : 0] WB_read_data;
    wire [`WORD_SIZE - 1 : 0] WB_ALU_OUT;
    wire [`addr_bitno - 1 : 0] WB_write_addr;
    
    wire [`WORD_SIZE - 1 : 0] WB_write_value;
    
    // WB control wire
    wire WB_RegWrite;
    wire WB_MemtoReg;
    //wire WB_num_inst;
    //wire WB_output_update;
    //wire WB_is_halted;
    
    wire [`addr_bitno - 1 : 0] WB_rs;
    wire WB_rs_use;
    wire [1:0] WB_rs_use_stage;
    wire [`addr_bitno - 1 : 0] WB_rt;
    wire WB_rt_use;
    wire [1:0] WB_rt_use_stage;
    wire [1:0] WB_write_valid_stage;
    
    wire WB_write_data_valid;
    
    // IF stage
    IFIDRegister IFID_UUT(reset_n,clk,IFID_stall,IFID_flush,IF_inst_addr_MSB,IF_inst_addr_seq,IF_instruction,IF_num_inst,
                                                            ID_inst_addr_MSB,ID_inst_addr_seq,ID_instruction,ID_num_inst);
    
    // control hazard
    //always @(*) IF_hazard_detected = ID_Jump_decision;
    
    // ID stage
    
    // datapath instruction decomposition
    assign ID_opcode = ID_instruction[`opcode_loc_l:`opcode_loc_r];
    assign ID_funct = ID_instruction[`funct_loc_l:`funct_loc_r];
    assign ID_rs = ID_instruction[ `rs_loc_l : `rs_loc_r ];
    assign ID_rt = ID_instruction[ `rt_loc_l : `rt_loc_r ];
    assign ID_rd = ID_instruction[ `rd_loc_l : `rd_loc_r ];
    assign ID_I_imm = { {8{ID_instruction[`imm_loc_l]}},ID_instruction[ `imm_loc_l : `imm_loc_r ]};
    assign ID_J_target = ID_instruction[ `target_loc_l : `target_loc_r ];
    
    assign ID_write_addr = ( ID_RegDst==`RegDst_rd ? ID_rd :
                                ID_RegDst==`RegDst_rt ?ID_rt :
                                ID_RegDst==`RegDst_Link ? 2'b10 :
                                                            2'bxx);

    RF RF_UUT ( WB_RegWrite, ~clk, reset_n, ID_rs, ID_rt, WB_write_addr, RF_rs_value, RF_rt_value, WB_write_value ) ;
    
    // Forwarding
    assign ID_write_value = ID_inst_addr_seq;
    
    always @(*) begin
        if(EX_RegWrite && EX_write_addr == ID_rs) ID_rs_value = EX_write_value;
        else if(MEM_RegWrite && MEM_write_addr == ID_rs) ID_rs_value = MEM_write_value;
        else if(WB_RegWrite && WB_write_addr == ID_rs) ID_rs_value = WB_write_value;
        else ID_rs_value = RF_rs_value;
    end
    
    always @(*) begin
        if(EX_RegWrite && EX_write_addr == ID_rt) ID_rt_value = EX_write_value;
        else if(MEM_RegWrite && MEM_write_addr == ID_rt) ID_rt_value = MEM_write_value;
        else if(WB_RegWrite && WB_write_addr == ID_rt) ID_rt_value = WB_write_value;
        else ID_rt_value = RF_rt_value;
    end
    // End of Forwarding
    
    assign ID_Jump_decision_pass = ID_Jump_decision;
    
    // Jump logic on ID
    always @(*) begin
        if(`Branch_Predictor_Enable) begin // branch predictor enabled
            if(ID_Jump == `Jump_JR) ID_Jump_decision = 1'b1;
            else if(ID_Jump == `Jump_J) ID_Jump_decision = 1'b1;
            else if(ID_Jump == `Jump_BEQ) ID_Jump_decision = (ID_rs_value == ID_rt_value);
            else if(ID_Jump == `Jump_BNE) ID_Jump_decision = (ID_rs_value != ID_rt_value);
            else if(ID_Jump == `Jump_BGZ) ID_Jump_decision = (~ID_rs_value[`WORD_SIZE - 1] && ID_rs_value != `WORD_SIZE'h0);
            else if(ID_Jump == `Jump_BLZ) ID_Jump_decision = (ID_rs_value[`WORD_SIZE - 1]);
            else if(ID_Jump == `Jump_idle) ID_Jump_decision = 1'b0;
            else ID_Jump_decision = 1'b0;
        end
        else begin // branch predictor disabled
            ID_Jump_decision = (ID_Jump != `Jump_idle);
        end
    end

    always @(*) begin
        if(`Branch_Predictor_Enable) begin // branch predictor enabled
            if(ID_Jump == `Jump_JR) ID_Jump_target = ID_rs_value;
            else if(ID_Jump == `Jump_J) ID_Jump_target = {ID_inst_addr_MSB,ID_J_target};
            else if(ID_Jump == `Jump_BEQ) ID_Jump_target = ID_inst_addr_seq + ID_I_imm;
            else if(ID_Jump == `Jump_BNE) ID_Jump_target = ID_inst_addr_seq + ID_I_imm;
            else if(ID_Jump == `Jump_BGZ) ID_Jump_target = ID_inst_addr_seq + ID_I_imm;
            else if(ID_Jump == `Jump_BLZ) ID_Jump_target = ID_inst_addr_seq + ID_I_imm;
            else ID_Jump_target = ID_inst_addr_seq;
        end
        else begin // branch predictor disabled
            if(ID_Jump == `Jump_JR) ID_Jump_target = ID_rs_value;
            else if(ID_Jump == `Jump_J) ID_Jump_target = {ID_inst_addr_MSB,ID_J_target};
            else if(ID_Jump == `Jump_BEQ) ID_Jump_target = (ID_rs_value == ID_rt_value ? ID_inst_addr_seq + ID_I_imm : ID_inst_addr_seq);
            else if(ID_Jump == `Jump_BNE) ID_Jump_target = (ID_rs_value != ID_rt_value ? ID_inst_addr_seq + ID_I_imm : ID_inst_addr_seq);
            else if(ID_Jump == `Jump_BGZ) ID_Jump_target = (~ID_rs_value[`WORD_SIZE - 1] && ID_rs_value != `WORD_SIZE'h0 ? ID_inst_addr_seq + ID_I_imm : ID_inst_addr_seq);
            else if(ID_Jump == `Jump_BLZ) ID_Jump_target = (ID_rs_value[`WORD_SIZE - 1] ? ID_inst_addr_seq + ID_I_imm : ID_inst_addr_seq);
            else ID_Jump_target = ID_inst_addr_seq;
        end
    end
    // jump logic on ID stage
    
    // Hazard detection logic ID
    assign ID_need_rs = (ID_rs_use && ID_rs_use_stage == `STAGE_ID);
    assign ID_need_rt = (ID_rt_use && ID_rt_use_stage == `STAGE_ID);
    assign ID_write_data_valid = ({1'b0,ID_write_valid_stage} <{1'b0,`STAGE_ID} );
    
    reg ID_rs_hazard;
    reg ID_rt_hazard;
    always @(*) begin
        if(ID_need_rs) begin
            if(EX_RegWrite && EX_write_addr == ID_rs) ID_rs_hazard = ~EX_write_data_valid;
            else if(MEM_RegWrite && MEM_write_addr == ID_rs) ID_rs_hazard = ~MEM_write_data_valid;
            else if(WB_RegWrite && WB_write_addr == ID_rs) ID_rs_hazard = ~WB_write_data_valid;
            else ID_rs_hazard = 1'b0;
        end
        else ID_rs_hazard = 1'b0;
        
        if(ID_need_rt) begin
            if(EX_RegWrite && EX_write_addr == ID_rt) ID_rt_hazard = ~EX_write_data_valid;
            else if(MEM_RegWrite && MEM_write_addr == ID_rt) ID_rt_hazard = ~MEM_write_data_valid;
            else if(WB_RegWrite && WB_write_addr == ID_rt) ID_rt_hazard = ~WB_write_data_valid;
            else ID_rt_hazard = 1'b0;
        end
        else ID_rt_hazard = 1'b0;
        
        ID_hazard_detected = (ID_rs_hazard || ID_rt_hazard);
    end
    
    // end Hazard detection logic ID
    
    OutputRegister IDEX_OUTControl(reset_n,clk,IDEX_stall,IDEX_flush,ID_output_update,ID_num_inst,ID_rs_value,EX_output_value,EX_output_update,EX_num_inst,EX_output_value);
    HazardRegister IDEX_HazardControl(reset_n,clk,IDEX_stall,IDEX_flush,ID_rs,ID_rs_use,ID_rs_use_stage,ID_rt,ID_rt_use,ID_rt_use_stage,ID_write_valid_stage,ID_nop,
                                                                        EX_rs,EX_rs_use,EX_rs_use_stage,EX_rt,EX_rt_use,EX_rt_use_stage,EX_write_valid_stage,EX_nop);
    EXControlRegister IDEX_EXControl(reset_n,clk,IDEX_stall,IDEX_flush,ID_ALUPathIntercept,ID_ALUSrc,ID_ALU_OP,EX_ALUPathIntercept,EX_ALUSrc,EX_ALU_OP);
    MEMControlRegister IDEX_MEMControl(reset_n,clk,IDEX_stall,IDEX_flush,ID_MemRead,ID_MemWrite,EX_MemRead,EX_MemWrite);
    WBControlRegister IDEX_WBControl(reset_n,clk,IDEX_stall,IDEX_flush,ID_MemtoReg,ID_RegWrite,ID_is_halted,EX_MemtoReg,EX_RegWrite,EX_is_halted);
    IDEXRegister IDEX_UUT(reset_n,clk,IDEX_stall,IDEX_flush,ID_inst_addr_seq,ID_rs_value, ID_rt_value, ID_I_imm, ID_J_target, ID_write_addr, EX_rs_value, EX_rt_value, 
                                                            EX_inst_addr_seq, EX_rs_passed_value, EX_rt_passed_value, EX_I_imm, EX_J_target, EX_write_addr);
    
    // EX stage
    // Forwarding
    assign EX_write_value = EX_inst_addr_seq;
    
    always @(*) begin
        if(MEM_RegWrite && MEM_write_addr == EX_rs) EX_rs_value = MEM_write_value;
        else if(WB_RegWrite && WB_write_addr == EX_rs) EX_rs_value = WB_write_value;
        else EX_rs_value = EX_rs_passed_value;
    end
    
    always @(*) begin
        if(MEM_RegWrite && MEM_write_addr == EX_rt) EX_rt_value = MEM_write_value;
        else if(WB_RegWrite && WB_write_addr == EX_rt) EX_rt_value = WB_write_value;
        else EX_rt_value = EX_rt_passed_value;
    end
    // End of Forwarding
    
    assign EX_ALU_in_1 = (EX_ALUPathIntercept ? EX_inst_addr_seq : EX_rs_value);
    
    assign EX_ALU_in_2 = (EX_ALUSrc == `ALUSrc_rt ? EX_rt_value :
                            EX_ALUSrc == `ALUSrc_imm ? EX_I_imm :
                            /* BGZ, BLZ */      `WORD_SIZE'h0);
    
    ALU ALU_UUT (EX_ALU_in_1,EX_ALU_in_2,EX_ALU_OP,EX_ALU_OUT,EX_ALU_Compare);

    //assign Jump_target = EX_Jump_target;
    
    //assign EXMEM_stall = WB_is_halted;
    //assign EXMEM_flush = 0;
    
    // Hazard detection logic EX
    assign EX_need_rs = (EX_rs_use && EX_rs_use_stage == `STAGE_EX);
    assign EX_need_rt = (EX_rt_use && EX_rt_use_stage == `STAGE_EX);
    assign EX_write_data_valid = ({1'b0,EX_write_valid_stage} <{1'b0,`STAGE_EX} );
    
    reg EX_rs_hazard;
    reg EX_rt_hazard;
    always @(*) begin
        if(EX_need_rs) begin
            if(MEM_RegWrite && MEM_write_addr == EX_rs) EX_rs_hazard = ~MEM_write_data_valid;
            else if(WB_RegWrite && WB_write_addr == EX_rs) EX_rs_hazard = ~WB_write_data_valid;
            else EX_rs_hazard = 1'b0;
        end
        else EX_rs_hazard = 1'b0;
        
        if(ID_need_rt) begin
            if(MEM_RegWrite && MEM_write_addr == EX_rt) EX_rt_hazard = ~MEM_write_data_valid;
            else if(WB_RegWrite && WB_write_addr == EX_rt) EX_rt_hazard = ~WB_write_data_valid;
            else EX_rt_hazard = 1'b0;
        end
        else EX_rt_hazard = 1'b0;
        
        EX_hazard_detected = (EX_rs_hazard || EX_rt_hazard);
    end
    
    // end Hazard detection logic EX
    
    OutputRegister EXMEM_OUTControl(reset_n,clk,EXMEM_stall,EXMEM_flush,EX_output_update,EX_num_inst,EX_output_value,MEM_output_value,MEM_output_update,MEM_num_inst,MEM_output_passed_value);
    HazardRegister EXMEM_HazardControl(reset_n,clk,EXMEM_stall,EXMEM_flush,EX_rs,EX_rs_use,EX_rs_use_stage,EX_rt,EX_rt_use,EX_rt_use_stage,EX_write_valid_stage,EX_nop,
                                                                        MEM_rs,MEM_rs_use,MEM_rs_use_stage,MEM_rt,MEM_rt_use,MEM_rt_use_stage,MEM_write_valid_stage,MEM_nop);
    MEMControlRegister EXMEM_MEMControl(reset_n,clk,EXMEM_stall,EXMEM_flush,EX_MemRead,EX_MemWrite,MEM_MemRead,MEM_MemWrite);
    WBControlRegister EXMEM_WBControl(reset_n,clk,EXMEM_stall,EXMEM_flush,EX_MemtoReg,EX_RegWrite,EX_is_halted,MEM_MemtoReg,MEM_RegWrite,MEM_is_halted);
    EXMEMRegister EXMEM_UUT(reset_n,clk,EXMEM_stall,EXMEM_flush,EX_ALU_OUT,EX_rt_value,EX_write_addr,MEM_rt_value,
                                                            MEM_ALU_OUT,MEM_rt_passed_value,MEM_write_addr);
    // MEM stage
    assign MEM_addr = MEM_ALU_OUT;
    assign MEM_write_data = MEM_rt_value;
    
    assign MEMWB_stall = WB_is_halted;
    assign MEMWB_flush = 0;
    
    // Hazard detection logic MEM
    assign MEM_need_rs = (MEM_rs_use && MEM_rs_use_stage == `STAGE_MEM);
    assign MEM_need_rt = (MEM_rt_use && MEM_rt_use_stage == `STAGE_MEM);
    assign MEM_write_data_valid = ({1'b0,MEM_write_valid_stage} <{1'b0,`STAGE_MEM} );
    
    reg MEM_rs_hazard;
    reg MEM_rt_hazard;
    always @(*) begin
        if(MEM_need_rs) begin
            if(WB_RegWrite && WB_write_addr == MEM_rs) MEM_rs_hazard = ~WB_write_data_valid;
            else MEM_rs_hazard = 1'b0;
        end
        else MEM_rs_hazard = 1'b0;
        
        if(ID_need_rt) begin
            if(WB_RegWrite && WB_write_addr == MEM_rt) MEM_rt_hazard = ~WB_write_data_valid;
            else MEM_rt_hazard = 1'b0;
        end
        else MEM_rt_hazard = 1'b0;
        
        MEM_hazard_detected = (MEM_rs_hazard || MEM_rt_hazard);
    end
    
    // Forwarding
    assign MEM_write_value = MEM_ALU_OUT;
    
    always @(*) begin
        if(WB_RegWrite && WB_write_addr == MEM_rt) MEM_rt_value = WB_write_value;
        else MEM_rt_value = MEM_rt_passed_value;
    end
    
    always @(*) begin
        if(WB_RegWrite && MEM_rs == WB_write_addr) MEM_output_value = WB_write_value;
        else MEM_output_value = MEM_output_passed_value;
    end
    // End of Forwarding
    
    // end Hazard detection logic MEM
    
    OutputRegister MEMWB_OUTControl(reset_n,clk,MEMWB_stall,MEMWB_flush,MEM_output_update,MEM_num_inst,MEM_output_value,WB_output_value,WB_output_update,WB_num_inst,WB_output_value);
    HazardRegister MEMWB_HazardControl(reset_n,clk,MEMWB_stall,MEMWB_flush,MEM_rs,MEM_rs_use,MEM_rs_use_stage,MEM_rt,MEM_rt_use,MEM_rt_use_stage,MEM_write_valid_stage,MEM_nop,
                                                                        WB_rs,WB_rs_use,WB_rs_use_stage,WB_rt,WB_rt_use,WB_rt_use_stage,WB_write_valid_stage,WB_nop);
    WBControlRegister MEMWB_WBControl(reset_n,clk,MEMWB_stall,MEMWB_flush,MEM_MemtoReg,MEM_RegWrite,MEM_is_halted,WB_MemtoReg,WB_RegWrite,WB_is_halted);
    MEMWBRegister MEMWB_UUT(reset_n,clk,MEMWB_stall,MEMWB_flush,MEM_read_data,MEM_ALU_OUT,MEM_write_addr,
                                                            WB_read_data,WB_ALU_OUT,WB_write_addr);
    
    // WB stage
    assign WB_write_value = (WB_MemtoReg ? WB_ALU_OUT : WB_read_data);
    
    // Hazard detection logic WB
    
    assign WB_write_data_valid = ({1'b0,WB_write_valid_stage} <{1'b0,`STAGE_WB} );
    assign WB_hazard_detected = 0;
    
    // end Hazard detection logic WB
    
    //
    //
    //
endmodule
