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

// `include "opcodes.v"
// `include "custom_opcodes.v"

module Control(
    input [`opcode_bitno - 1 : 0] opcode,
    input [`R_funct_bitno - 1 : 0] funct,
    input [1:0] ALU_Compare,
    input reset_n,
    input clk,
    output writeM,
    output reg [3 : 0] ALU_OP,
    output reg RegDst,
    output reg RegWrite,
    output reg readM,
    output reg MemWrite,
    output reg [1:0] RegWriteSrc,
    output reg [1:0] ALUSrcA,
    output reg [1:0] ALUSrcB,
    output reg IorD,
    output reg PVSWrite, // PC controller
    output reg PCRegWrite,
    output reg [1:0] PCSource,
    output reg JumpReg,
    output output_active, // output controller
    output is_halted
    );
    
    reg [2:0] stage;
    reg reset_rest; // used for throwing away reset cycle
    
    // instruction type indicator
    wire Rtype_Arithmetic;
    wire Rtype_Special;
    wire Rtype_Halt;
    wire Itype_Arithmetic;
    wire Itype_Branch;
    wire Itype_Memory;
    wire Jtype_Jump;
    
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
    // indicate if instruction is Special Rtype instruction
    assign Rtype_Special = ( (opcode == `OPCODE_Rtype)
                            &&( (funct == `FUNC_WWD)
                            ||(funct == `FUNC_JPR)
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

    // special output assignment
    assign output_active = ( stage == `STAGE_ID && opcode == `OPCODE_Rtype && funct == `FUNC_WWD );
    assign is_halted = ( stage != `STAGE_IF && Rtype_Halt );
    assign writeM = ( stage == `STAGE_MEM && opcode == `OPCODE_SWD );
    
    always @(*) begin
    //ALU_OP to be developed
        if( stage == `STAGE_IF ) ALU_OP = `OP_ADD;
        else if( stage == `STAGE_ID ) ALU_OP = `OP_ADD;
        else begin
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
            else if( Itype_Arithmetic ) begin
                if( opcode == `OPCODE_ADI ) ALU_OP = `OP_ADD;
                else if( opcode == `OPCODE_ORI ) ALU_OP = `OP_ORR;
                else if( opcode == `OPCODE_LHI ) ALU_OP = `OP_LHI;
            end
            else if( Itype_Branch ) ALU_OP = `OP_SUB;
            else if( Itype_Memory ) ALU_OP = `OP_ADD;
            else ALU_OP = 4'bx;
        end
    end
    
    always @(*) begin // readM logic
        if(reset_rest) readM = 1'b0;
        else if(stage==`STAGE_IF) readM = 1'b1; // activate at instruction fetch
        else if(stage==`STAGE_MEM && opcode == `OPCODE_LWD) readM = 1'b1; // activate at mem read
        else readM = 0;
    end
    
    always @(*) begin // RegDst logic
        // 0 : rt, 1 : rd
        RegDst = (opcode == `OPCODE_Rtype ? 1'b1 : 0); //activate if arithmetic R type
    end
    
    always @(*) begin
        if( opcode == `OPCODE_JAL || (opcode == `OPCODE_Rtype && funct == `FUNC_JRL) ) RegWriteSrc = `RegWriteSrc_PC;
        else if( opcode == `OPCODE_LWD ) RegWriteSrc = `RegWriteSrc_Memory;
        else RegWriteSrc = `RegWriteSrc_ALU; // activate at mem load
    end
    
    always @(*) begin
        if(stage == `STAGE_IF) ALUSrcA = `ALUSrcA_Inst; //  activate at IF stage, compute sequential PC
        else if(stage == `STAGE_ID && Itype_Branch) ALUSrcA = `ALUSrcA_Inst_Seq; // activate at ID on branch instruction
        else ALUSrcA = `ALUSrcA_Reg; // else ALU is using data
    end
    
    always @(*) begin
        // get sequential address on IF
        if(stage == `STAGE_IF) ALUSrcB = `ALUSrcB_Seq;
        // get offset target on ID
        else if(stage == `STAGE_ID) ALUSrcB = `ALUSrcB_Offset;
        else if(stage == `STAGE_EX) begin
            if( opcode == `OPCODE_BNE || opcode == `OPCODE_BEQ ) ALUSrcB = `ALUSrcB_Reg;
            else if( opcode == `OPCODE_BGZ || opcode == `OPCODE_BLZ ) ALUSrcB = `ALUSrcB_Zero;
        end
        else if( Rtype_Arithmetic) ALUSrcB = `ALUSrcB_Reg;
        else if( Itype_Arithmetic || Itype_Memory ) ALUSrcB = `ALUSrcB_Offset;
    end
    
    always @(*) begin
        IorD = ( stage == `STAGE_IF ? 1'b0 : 1'b1 );
    end
    
    always @(*) begin
        if(stage == `STAGE_IF) PCSource = `PCaddr_Seq; // for sequential instructino address
        else if(stage == `STAGE_ID) begin
            if( Itype_Branch ) PCSource = `PCaddr_Offset; // for conditional branch target register
            else if( Jtype_Jump ) PCSource = `PCaddr_Given; // unconditional jump gets given address
            else if( opcode == `OPCODE_Rtype && (funct == `FUNC_JPR || funct == `FUNC_JRL) ) PCSource = `PCaddr_Given; // JPR gets given address
            else if( opcode == `OPCODE_Rtype && funct == `FUNC_WWD ) PCSource = `PCaddr_Seq;
            else PCSource = 2'b01;
        end
        else if(stage == `STAGE_EX) begin
            if( opcode == `OPCODE_BNE ) PCSource = {1'b0, ALU_Compare != 2'b00 };
            else if( opcode == `OPCODE_BEQ ) PCSource = {1'b0, ALU_Compare == 2'b00 };
            else if( opcode == `OPCODE_BGZ ) PCSource = {1'b0, ALU_Compare == 2'b10 };
            else if( opcode == `OPCODE_BLZ ) PCSource = {1'b0, ALU_Compare == 2'b11 };
            else PCSource = 0;
        end
        else PCSource = 0;
    end
    
    always @(*) begin
        if( opcode == `OPCODE_Rtype && (funct == `FUNC_JPR || funct == `FUNC_JRL)) JumpReg = 1'b1;
        else if( opcode == `OPCODE_JMP || opcode == `OPCODE_JAL ) JumpReg = 1'b0;
    end
    
    always @(negedge clk) begin // write signals are edited on negative edge for stability
        RegWrite = ( stage == `STAGE_WB // reg write on WB stage or JRL ID stage
                    || (stage == `STAGE_ID && 
                            ( (opcode == `OPCODE_Rtype && funct == `FUNC_JRL) 
                            || opcode == `OPCODE_JAL ) )? 1'b1 : 1'b0 );
        // write on SWD MEM stage
        MemWrite = ( stage == `STAGE_MEM && opcode == `OPCODE_SWD ? 1'b1 : 1'b0 );
        PVSWrite = ( ( // if instruction finishes
                        ( stage == `STAGE_ID && // Special or Jump finish at ID
                            ( Rtype_Special || Jtype_Jump) ) // don't proceed on HLT
                      || ( stage == `STAGE_EX && Itype_Branch ) // Branch finish at EX
                      ||( stage == `STAGE_MEM && (opcode == `OPCODE_SWD)) // SWD finish
                      ||( stage == `STAGE_WB && 
                            ( opcode == `OPCODE_LWD || Rtype_Arithmetic || Itype_Arithmetic )) // if at WB stage, all finish
                    ) ? 1'b1 : 1'b0 );
        
        // write PCReg at IF stage or Branch ID stage
        if( stage == `STAGE_IF || (stage == `STAGE_ID && Itype_Branch ) ) PCRegWrite = 1'b1;
        else PCRegWrite = 1'b0;
        
        if(is_halted) begin
            RegWrite = 0;
            MemWrite = 0;
            PVSWrite = 0;
        end
    end
    
    always @(posedge clk) begin
    
    if(~reset_n) begin
        reset_rest = 1'b1;
        stage = `STAGE_IF;
    end
    else if(reset_rest) begin
        reset_rest = 0;
        stage = `STAGE_IF;
    end
    
    else
    case(stage)
        `STAGE_IF: stage = `STAGE_ID; // always go to decode stage
        
        `STAGE_ID:
            // unconditional jump and special Rtype instructino finish at ID
            if( Jtype_Jump || Rtype_Special ) stage = `STAGE_IF;
            // HALT INSTRUCTION HALTS
            else if( Rtype_Halt ) stage = `STAGE_ID;
            // else proceed to execution
            else stage = `STAGE_EX;
         `STAGE_EX: 
            // Branch instruction finish
            if( Itype_Branch ) stage = `STAGE_IF;
            // Memory instruction goes to MEM
            else if( Itype_Memory ) stage = `STAGE_MEM;
            // Arithmetic instruction goes to WB
            else if( Itype_Arithmetic || Rtype_Arithmetic ) stage = `STAGE_WB;
         `STAGE_MEM:
            // load instruction goes to WB
            if( opcode == `OPCODE_LWD ) stage = `STAGE_WB;
            // store instruction finishes
            else if(opcode == `OPCODE_SWD) stage = `STAGE_IF;
            
            // WB is always the end of instruction
         `STAGE_WB: stage = `STAGE_IF;
    endcase
    
    end
    
endmodule