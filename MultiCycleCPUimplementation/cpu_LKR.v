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
  output readM,                       // read from memory
  output writeM,                            // write to memory
  output [`WORD_SIZE-1:0] address,    // current address for data
  inout [`WORD_SIZE-1:0] data,        // data being input or output
  input inputReady,                   // indicates that data is ready from the input port
  input reset_n,                      // active-low RESET signal
  input clk,                          // clock signal

    // for debuging/testing purpose
  output reg [`WORD_SIZE-1:0] num_inst, // number of instruction during execution
  output [`WORD_SIZE-1:0] output_port, // this will be used for a "WWD" instruction
  output is_halted // 1 if the cpu is halted
  );


  // ... fill in the rest of the code
    reg reset_rest; // used for throwing away reset cycle


    // instruction wire
    wire [`WORD_SIZE - 1 : 0] inst_addr;
    reg [`WORD_SIZE - 1 : 0] instruction;

    // decompose instruction by usage
    wire [`opcode_bitno - 1 : 0] opcode;
    wire [`R_funct_bitno -1 : 0] R_funct;
    wire [`J_target_bitno - 1 : 0] J_target;
    wire [`opcode_loc_r - 1 : 0] opinstruction;

    // control wires
    wire Jump;
    wire [3:0] ALU_OP;
    wire RegDst;
    wire RegWrite;
    wire MemWrite;
    wire [1:0] RegWriteSrc;
    wire [1:0] ALUSrcA;
    wire [1:0] ALUSrcB;
    wire IorD;
    wire PCWrite;
    wire PCRegWrite;
    wire [1:0] PCSource;
    wire JumpReg;
    wire output_active;
    
    wire [`WORD_SIZE - 1 : 0] output_data;
    
    wire [`WORD_SIZE - 1 : 0] inst_seq_next_addr;
    
    wire [1:0] ALU_Compare;
    wire [`WORD_SIZE - 1 : 0] ALU_addr;
    wire [`WORD_SIZE - 1 : 0] RF_addr;
    wire [`WORD_SIZE - 1 : 0] RF_data;
    wire [`WORD_SIZE - 1 : 0] calc_next_inst_addr;
    reg [`WORD_SIZE - 1 : 0] data_fetch;
    
    Control Ct_UUT (opcode,R_funct,ALU_Compare,reset_n,clk,
        writeM,ALU_OP,RegDst,RegWrite,readM,MemWrite,RegWriteSrc,ALUSrcA,ALUSrcB,IorD,PCWrite,PCRegWrite,PCSource,JumpReg,output_active,is_halted);
    
    assign opcode = instruction[ `opcode_loc_l : `opcode_loc_r ];
    assign R_funct = instruction[ `funct_loc_l : `funct_loc_r ];
    assign J_target = instruction[ `target_loc_l : `target_loc_r ];
    assign opinstruction = instruction[ `opcode_loc_r - 1 : 0];

    // Program Counter computes instruction address
    ProgramCounter PC_UUT ( PCSource,calc_next_inst_addr,PCRegWrite,PCWrite, reset_n, clk, inst_seq_next_addr, inst_addr);

    assign calc_next_inst_addr = (PCSource == `PCaddr_Seq ? ALU_addr :
                                    PCSource == `PCaddr_Offset ? ALU_addr :
                                 /* PCSource == `PCSource_Given ? */
                                    JumpReg ? RF_addr : {inst_addr[`WORD_SIZE - 1: `target_loc_l + 1],J_target} ) ;
    assign output_port = ( output_active ? output_data : `WORD_SIZE'hz );

    assign address = ( IorD ? ALU_addr : inst_addr ) ; // fetch instruction at high clock
    
    Datapath DT_UUT ( reset_n, clk, opinstruction, data_fetch, inst_seq_next_addr, inst_addr, 
        ALU_OP, RegDst, RegWrite, RegWriteSrc, ALUSrcA, ALUSrcB, ALU_Compare, output_data, RF_addr, RF_data, ALU_addr);

    assign data = (writeM ? RF_data : `WORD_SIZE'hzzzz);

    always @(posedge clk) begin

        if(~reset_n) begin
            num_inst = 0;
            reset_rest = 1'b1;
        end
        else if(reset_rest) begin
            num_inst = num_inst + 1;
            reset_rest = 0;
        end
        else if(PCWrite) num_inst = num_inst + 1;

    end

    always @(posedge inputReady) begin
    
    if(~IorD) begin
        instruction = data;
    end
    else begin
        data_fetch = data;
    end
    
    end

endmodule
//////////////////////////////////////////////////////////////////////////
