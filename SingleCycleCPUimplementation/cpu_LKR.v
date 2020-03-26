///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: Lee Kyeong Ryong (kryongleesec@gmail.com)
// Description: 

// DEFINITIONS

// INCLUDE files
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions

// MODULE DECLARATION
module cpu (
  output reg readM,                       // read from memory
  output [`WORD_SIZE-1:0] address,    // current address for data
  inout [`WORD_SIZE-1:0] data,        // data being input or output
  input inputReady,                   // indicates that data is ready from the input port
  input reset_n,                      // active-low RESET signal
  input clk,                          // clock signal

  // for debuging/testing purpose
  output reg [`WORD_SIZE-1:0] num_inst,   // number of instruction during execution
  output [`WORD_SIZE-1:0] output_port // this will be used for a "WWD" instruction
  );


  // ... fill in the rest of the code

    // instruction wire
    wire [`WORD_SIZE - 1 : 0] inst_addr;
    reg [`instruction_bitno - 1 : 0] instruction;

    // decompose instruction by usage
    wire [`opcode_bitno - 1 : 0] opcode;
    wire [`R_funct_bitno -1 : 0] R_funct;
    wire [`J_target_bitno - 1 : 0] J_target;
    wire [`opcode_loc_r - 1 : 0] opinstruction;

    // control wires
    wire Jump;
    wire [3:0] ALU_OP;
    wire ALUSrc;
    wire RegDst;
    wire RegWrite;
    wire output_active;
    
    wire [`WORD_SIZE - 1 : 0] output_data;
    
    reg execute; // indicating if instruction is fetched and is to be executed
    
    Control Ct_UUT (opcode,R_funct,Jump,ALU_OP,ALUSrc,RegDst,RegWrite,output_active);
    
    assign opcode = instruction[ `opcode_loc_l : `opcode_loc_r ];
    assign R_funct = instruction[ `funct_loc_l : `funct_loc_r ];
    assign J_target = instruction[ `target_loc_l : `target_loc_r ];
    assign opinstruction = instruction[ `opcode_loc_r - 1 : 0];

    // Program Counter computes instruction address
    ProgramCounter PC_UUT ( Jump, J_target, reset_n, clk, inst_addr);

    assign output_port = ( output_active && execute ? output_data : 0);

    assign address = ( ~execute ? inst_addr : `WORD_SIZE'hzzzz ) ; // fetch instruction at high clock
    
    Datapath DT_UUT ( reset_n, clk, opinstruction, Jump, ALU_OP, ALUSrc, RegDst, RegWrite, output_data);

    always @(posedge clk) begin

        if(~reset_n) num_inst = 0;
        
        execute = 0;
        readM = 1;

        num_inst = num_inst + 1;

    end

    always @(posedge inputReady) begin
    
    if(~execute) begin
        instruction = data;
        readM = 0;
        execute = 1;
    end
    else begin
        readM = 0;
    end
    
    end

endmodule
//////////////////////////////////////////////////////////////////////////
