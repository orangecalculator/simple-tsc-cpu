`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/04/11 08:26:57
// Design Name: 
// Module Name: Control
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

`include "opcodes.v"
`include "custom_opcodes.v"

module Control(
    input [`opcode_bitno - 1 : 0] opcode,
    input [`R_funct_bitno - 1 : 0] funct,
    output reg [1:0] RegDst,
    output reg [2:0] Jump,
    output reg ALUPathIntercept,
    output reg [1:0] ALUSrc,
    output reg [3:0] ALU_OP,
    output reg MemRead,
    output reg MemWrite,
    output reg RegWrite,
    output reg MemtoReg,
    output output_active,
    output is_halted,
    
    // wire for hazard detection
    output reg rs_use,
    output reg [1:0] rs_use_stage,
    output reg rt_use,
    output reg [1:0] rt_use_stage,
    output reg [1:0] write_valid_stage,
    
    // Hazard detection
    input IF_hazard_detected,
    input ID_hazard_detected,
    input EX_hazard_detected,
    input MEM_hazard_detected,
    input WB_hazard_detected,
    
    output ID_nop,
    input EX_nop,
    input MEM_nop,
    input WB_nop,
        
    output reg IF_stall,
    output reg IFID_stall,
    output reg IFID_flush,
    output reg IDEX_stall,
    output reg IDEX_flush,
    output reg EXMEM_stall,
    output reg EXMEM_flush,
    output reg MEMWB_stall,
    output reg MEMWB_flush,
    input WB_is_halted
    );

    reg reset_rest; // used for throwing away reset cycle
    
    // instruction type indicator
    wire defined_instruction;
    
    wire Rtype_Arithmetic;
    wire Rtype_JumpR;
    wire Rtype_Output;
    wire Rtype_Halt;
    wire Itype_Arithmetic;
    wire Itype_Branch;
    wire Itype_Memory;
    wire Jtype_Jump;
    wire Jump_Link;
    wire NOP;
    
    assign defined_instruction = ( Rtype_Arithmetic
                                    || Rtype_JumpR
                                    || Rtype_Output
                                    || Rtype_Halt
                                    || Itype_Arithmetic
                                    || Itype_Branch
                                    || Itype_Memory
                                    || Jtype_Jump );
    assign NOP = ~defined_instruction;
    
    // indicate if instruction is Arithmetic Rtype instruction
    assign Rtype_Arithmetic = (opcode == `OPCODE_Rtype)
                     && ( (funct == `FUNC_ADD)
                         ||(funct == `FUNC_SUB)
                         ||(funct == `FUNC_AND)
                         ||(funct == `FUNC_ORR)
                         ||(funct == `FUNC_NOT)
                         ||(funct == `FUNC_TCP)
                         ||(funct == `FUNC_SHL)
                         ||(funct == `FUNC_SHR) );
    // indicate if instruction is Rtype memory output instruction WWD
    assign Rtype_Output = ( (opcode == `OPCODE_Rtype) &&(funct == `FUNC_WWD) );
    // indicate if instruction is Special Rtype instruction
    assign Rtype_JumpR = ( (opcode == `OPCODE_Rtype)
                            &&( (funct == `FUNC_JPR)
                            ||(funct == `FUNC_JRL) ) );
    // Halt is another special instruction
    assign Rtype_Halt = ( (opcode == `OPCODE_Rtype) && (funct == `FUNC_HLT) );
    // indicate if instruction is Arithmetic Itype instruction
    assign Itype_Arithmetic = (opcode == `OPCODE_ADI)
                ||(opcode == `OPCODE_ORI)
                ||(opcode == `OPCODE_LHI);
    // indicate if instruciton is conditional Branch Instruction
    assign Itype_Branch = ( (opcode == `OPCODE_BNE)
                ||(opcode == `OPCODE_BEQ)
                ||(opcode == `OPCODE_BGZ)
                ||(opcode == `OPCODE_BLZ) );
    // indicate if instruction is Load or Store
    assign Itype_Memory = ( (opcode == `OPCODE_LWD)
                            || (opcode == `OPCODE_SWD) );
    // indicate if instruction is unconditional Jump
    assign Jtype_Jump = ( (opcode == `OPCODE_JMP)
                            || (opcode == `OPCODE_JAL) );
    assign Jump_Link = ( (opcode == `OPCODE_JAL)
                            || ( (opcode == `OPCODE_Rtype)&&(funct == `FUNC_JRL) ) );

    // special output assignment
    assign output_active = ( Rtype_Output );
    assign is_halted = ( Rtype_Halt );
    
    // Register write address
    always @(*) begin
        if(Rtype_Arithmetic) RegDst = `RegDst_rd;
        else if(Itype_Arithmetic) RegDst = `RegDst_rt;
        else if(opcode == `OPCODE_LWD) RegDst = `RegDst_rt;
        else if(Jump_Link) RegDst = `RegDst_Link;
    end
    
    // Jump type indicator
    always @(*) begin
        if(Rtype_JumpR) Jump = `Jump_JR;
        else if(Jtype_Jump) Jump = `Jump_J;
        else if(Itype_Branch) begin
            if(opcode == `OPCODE_BEQ) Jump = `Jump_BEQ;
            else if(opcode == `OPCODE_BNE) Jump = `Jump_BNE;
            else if(opcode == `OPCODE_BGZ) Jump = `Jump_BGZ;
            else if(opcode == `OPCODE_BLZ) Jump = `Jump_BLZ;
        end
        else Jump = `Jump_idle; // idle on not jump or branch
    end
    
    // intercept ALU path on jump link
    always @(*) begin
        if(Jump_Link) ALUPathIntercept = 1'b1;
        else ALUPathIntercept = 1'b0;
    end
    
    // ALU second operand selection
    always @(*) begin
        if(Rtype_Arithmetic) ALUSrc = `ALUSrc_rt;
        else if(Itype_Arithmetic) ALUSrc = `ALUSrc_imm;
        else if(Itype_Memory) ALUSrc = `ALUSrc_imm;
        else if(Itype_Branch) begin
            if(opcode == `OPCODE_BEQ
                || opcode == `OPCODE_BNE) ALUSrc = `ALUSrc_rt;
            else ALUSrc = `ALUSrc_zero;
        end
    end
    
    // ALU operation control
    always @(*) begin
        if( Rtype_Arithmetic ) begin
            if( funct == `FUNC_ADD ) ALU_OP = `OP_ADD;
            else if( funct == `FUNC_SUB ) ALU_OP = `OP_SUB;
            else if( funct == `FUNC_AND ) ALU_OP = `OP_AND;
            else if( funct == `FUNC_ORR ) ALU_OP = `OP_ORR;
            else if( funct == `FUNC_NOT ) ALU_OP = `OP_NOT;
            else if( funct == `FUNC_TCP ) ALU_OP = `OP_TCP;
            else if( funct == `FUNC_SHL ) ALU_OP = `OP_SHL;
            else if( funct == `FUNC_SHR ) ALU_OP = `OP_SHR;
        end
        else if(Rtype_Output) ALU_OP = `OP_ID;
        else if(Itype_Arithmetic) begin
            if( opcode == `OPCODE_ADI ) ALU_OP = `OP_ADD;
            else if( opcode == `OPCODE_ORI ) ALU_OP = `OP_ORR;
            else if( opcode == `OPCODE_LHI ) ALU_OP = `OP_LHI;
        end
        else if(Jump_Link) ALU_OP = `OP_ID;
        else if(Itype_Branch) ALU_OP = `OP_SUB;
        else if(Itype_Memory) ALU_OP = `OP_ADD;
        else ALU_OP = 4'bx;
    end
    
    // MemRead on load
    always @(*) begin
        if(opcode == `OPCODE_LWD) MemRead = 1'b1;
        else MemRead = 1'b0;
    end
    
    // Memwrite on store
    always @(*) begin
        if(opcode == `OPCODE_SWD) MemWrite = 1'b1;
        else MemWrite = 1'b0;
    end
    
    // Register write control
    always @(*) begin
        if(Rtype_Arithmetic) RegWrite = 1'b1;
        else if(Itype_Arithmetic) RegWrite = 1'b1;
        else if(opcode == `OPCODE_LWD) RegWrite = 1'b1;
        else if(Jump_Link) RegWrite = 1'b1;
        else RegWrite = 1'b0;
    end
    
    // Memory to register on load
    always @(*) begin
        if(opcode == `OPCODE_LWD) MemtoReg = 1'b0;
        else if(Rtype_Arithmetic) MemtoReg = 1'b1;
        else if(Rtype_JumpR) MemtoReg = 1'b1;
        else if(Itype_Arithmetic) MemtoReg = 1'b1;
        else if(Rtype_Output) MemtoReg = 1'b1;
    end
    
    // rs data usage indicator for hazard detection
    always @(*) begin
        if( Rtype_Arithmetic
                || Rtype_JumpR
                || Rtype_Output
                || Itype_Arithmetic
                || Itype_Branch
                || Itype_Memory ) rs_use = 1'b1;
        else rs_use = 1'b0;
    end
    /* // full forwarding
    always @(*) begin
        if(Rtype_Arithmetic) rs_use_stage = `STAGE_EX;
        else if(Rtype_JumpR) rs_use_stage = `STAGE_ID;
        else if(Rtype_Output) rs_use_stage = `STAGE_WB;
        else if(Itype_Arithmetic) rs_use_stage = `STAGE_EX;
        else if(Itype_Branch) rs_use_stage = `STAGE_ID; // to be upgraded to ID
        else if(Itype_Memory) rs_use_stage = `STAGE_EX;
        else rs_use_stage = 2'bxx;
    end
    */
     // no forwarding
     // rs use stage indicator for hazard detection
    always @(*) begin
        if(`Forwarding_Enable) begin // forwarding enabled
            if(Rtype_Arithmetic) rs_use_stage = `STAGE_EX;
            else if(Rtype_JumpR) rs_use_stage = `STAGE_ID;
            else if(Rtype_Output) rs_use_stage = `STAGE_WB;
            else if(Itype_Arithmetic) rs_use_stage = `STAGE_EX;
            else if(Itype_Branch) rs_use_stage = `STAGE_ID; // to be upgraded to ID
            else if(Itype_Memory) rs_use_stage = `STAGE_EX;
            else rs_use_stage = 2'bxx;
        end
        else begin // forwardig disabled
            if(Rtype_Arithmetic) rs_use_stage = `STAGE_ID;
            else if(Rtype_JumpR) rs_use_stage = `STAGE_ID;
            else if(Rtype_Output) rs_use_stage = `STAGE_ID;
            else if(Itype_Arithmetic) rs_use_stage = `STAGE_ID;
            else if(Itype_Branch) rs_use_stage = `STAGE_ID; // to be upgraded to ID
            else if(Itype_Memory) rs_use_stage = `STAGE_ID;
            else rs_use_stage = 2'bxx;
        end
    end
    
    // rt data usage indicator for hazard detection
    always @(*) begin
        if( Rtype_Arithmetic
            || opcode == `OPCODE_SWD
            || opcode == `OPCODE_BEQ
            || opcode == `OPCODE_BNE ) rt_use = 1'b1;
        else rt_use = 1'b0;
    end
    /* // full forwarding
    always @(*) begin
        if(Rtype_Arithmetic) rt_use_stage = `STAGE_EX;
        else if(opcode == `OPCODE_SWD) rt_use_stage = `STAGE_MEM;
        else if( opcode == `OPCODE_BEQ
            || opcode == `OPCODE_BNE ) rt_use_stage = `STAGE_ID;
        else rt_use_stage = 2'bxx;
    end
    */
    // no forwarding
    // rt use stage indicator for hazard detection
    always @(*) begin
        if(`Forwarding_Enable) begin // full forwarding enabled
            if(Rtype_Arithmetic) rt_use_stage = `STAGE_EX;
            else if(opcode == `OPCODE_SWD) rt_use_stage = `STAGE_MEM;
            else if( opcode == `OPCODE_BEQ
                || opcode == `OPCODE_BNE ) rt_use_stage = `STAGE_ID;
            else rt_use_stage = 2'bxx;
        end
        else begin // forwarding disabled
            if(Rtype_Arithmetic) rt_use_stage = `STAGE_ID;
            else if(opcode == `OPCODE_SWD) rt_use_stage = `STAGE_ID;
            else if( opcode == `OPCODE_BEQ
                || opcode == `OPCODE_BNE ) rt_use_stage = `STAGE_ID;
            else rt_use_stage = 2'bxx;
        end
    end
    /*
    always @(*) begin
        if(Rtype_Arithmetic) rt_use_stage = `STAGE_EX;
        else if(opcode == `OPCODE_SWD) rt_use_stage = `STAGE_MEM;
        else if( opcode == `OPCODE_BEQ
            || opcode == `OPCODE_BNE ) rt_use_stage = `STAGE_ID;
        else rt_use_stage = 2'bxx;
    end
    */
    /* // full forwarding
    always @(*) begin
        if(Rtype_Arithmetic) write_valid_stage = `STAGE_EX;
        else if(Itype_Arithmetic) write_valid_stage = `STAGE_EX;
        else if(opcode == `OPCODE_LWD) write_valid_stage = `STAGE_MEM;
        else if(Jump_Link) write_valid_stage = `STAGE_ID;
    end
    */
    /* // RF negedge write
    always @(*) begin
        if(Rtype_Arithmetic) write_valid_stage = `STAGE_MEM;
        else if(Itype_Arithmetic) write_valid_stage = `STAGE_MEM;
        else if(opcode == `OPCODE_LWD) write_valid_stage = `STAGE_MEM;
        else if(Jump_Link) write_valid_stage = `STAGE_MEM;
    end
    */
    // no forwarding
    // write data production stage indicator
    always @(*) begin
        if(`Forwarding_Enable) begin // full forwarding enabled
            if(Rtype_Arithmetic) write_valid_stage = `STAGE_EX;
            else if(Itype_Arithmetic) write_valid_stage = `STAGE_EX;
            else if(opcode == `OPCODE_LWD) write_valid_stage = `STAGE_MEM;
            else if(Jump_Link) write_valid_stage = `STAGE_ID;
        end
        else if(`Forwarding_Register) begin // WB on negedge
            if(Rtype_Arithmetic) write_valid_stage = `STAGE_MEM;
            else if(Itype_Arithmetic) write_valid_stage = `STAGE_MEM;
            else if(opcode == `OPCODE_LWD) write_valid_stage = `STAGE_MEM;
            else if(Jump_Link) write_valid_stage = `STAGE_MEM;
        end
        else begin // no forwarding
            if(Rtype_Arithmetic) write_valid_stage = `STAGE_WB;
            else if(Itype_Arithmetic) write_valid_stage = `STAGE_WB;
            else if(opcode == `OPCODE_LWD) write_valid_stage = `STAGE_WB;
            else if(Jump_Link) write_valid_stage = `STAGE_WB;
        end
    end
    
    
    assign ID_nop = NOP;
    
    // stall and flush signal organizer based on hazard detection bit
    always @(*) begin
        if(WB_is_halted) begin
            IF_stall = 1'b1;
            IFID_stall = 1'b1;
            IFID_flush = 1'b0;
            IDEX_stall = 1'b1;
            IDEX_flush = 1'b0;
            EXMEM_stall = 1'b1;
            EXMEM_flush = 1'b0;
            MEMWB_stall = 1'b1;
            MEMWB_flush = 1'b0;
        end
        else begin
            MEMWB_stall = WB_hazard_detected;
            EXMEM_stall = MEM_hazard_detected || (MEMWB_stall && ~MEM_nop);
            IDEX_stall = EX_hazard_detected || (EXMEM_stall && ~EX_nop);
            IFID_stall = ID_hazard_detected || (IDEX_stall && ~ID_nop);
            IF_stall = IF_hazard_detected || (IFID_stall);
            
            IFID_flush = ~IFID_stall && (IF_stall || IF_hazard_detected);
            IDEX_flush = ~IDEX_stall && IFID_stall;
            EXMEM_flush = ~EXMEM_stall && IDEX_stall;
            MEMWB_flush = ~MEMWB_stall && EXMEM_stall;
        end
    end
    
endmodule