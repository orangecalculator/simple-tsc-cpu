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

module Control(
    input [`opcode_bitno - 1 : 0] opcode,
    input [`R_funct_bitno - 1 : 0] funct, 
    output reg Jump,
    output reg [3 : 0] ALU_OP,
    output reg ALUSrc,
    output reg RegDst,
    output reg RegWrite,
    output outputdata
    );
    
    assign outputdata = ( opcode == `OPCODE_Rty && funct == `FUNC_WWD );

    always @(*) begin
    
    case(opcode)
        `OPCODE_Rty: begin
            Jump = 0;
            ALUSrc = 0;
            RegDst = 1;
            RegWrite = 1;
                case(funct)
                    `FUNC_ADD: begin
                        ALU_OP = `OP_ADD;
                    end
                    `FUNC_WWD: begin
                        ALU_OP = `OP_ID;
                        RegWrite = 0;
                    end
                endcase
        end
        `OPCODE_ADI: begin
            Jump = 0;
            ALUSrc = 1;
            RegDst = 0;
            RegWrite = 1;
            ALU_OP = `OP_ADD;
        end
        `OPCODE_LHI: begin
            Jump = 0;
            ALUSrc = 1;
            RegDst = 0;
            RegWrite = 1;
            ALU_OP = `OP_LHI;
        end
        `OPCODE_JMP: begin
            Jump = 1;
            ALUSrc = 0;
            RegDst = 1'bx;
            RegWrite = 0;
        end
        
      endcase
    
    end
    
endmodule