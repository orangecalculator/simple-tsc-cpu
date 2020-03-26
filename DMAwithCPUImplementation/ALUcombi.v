
 `include "opcodes.v"
 `include "custom_opcodes.v"
 `include "constants.v"

module ALU(
input [15:0] A,
input [15:0] B,
//input Cin,
input [3:0] OP,
output [15:0] C,
//output Cout,
output Compare
);

    wire [15:0] Arithmetic;

    // activate Cout on arithmetic opertion +/-
    // implemented using the fact that OP_add is 0000 and OP_sub is 0001
    assign Arithmetic = ( OP==`OP_ADD ? A+B :
                            OP==`OP_SUB ? A-B:
                               /* else */ 0 );
    
    // indicates equality when OP_SUB is asserted
    assign Compare = ( /*OP==`OP_SUB &&*/ Arithmetic == `WORD_SIZE'h0 ? 1'b1 : 1'b0 );
    
    // implemented the main stream of ALU by a long chain of ternary opertor
    assign C = OP==`OP_ADD ? Arithmetic :
               OP==`OP_SUB ? Arithmetic :
               OP==`OP_TCP ? -A :
               OP==`OP_ID  ?  A :
               OP==`OP_NOT ? ~A :
               OP==`OP_AND ? (A&B) :
               OP==`OP_ORR ? (A|B) :
               OP==`OP_SHL ? {A[`WORD_SIZE - 2 : 0],1'b0} :
               OP==`OP_SHR ? {A[`WORD_SIZE - 1],A[`WORD_SIZE - 1 : 1]} :
               OP==`OP_LHI ? {B[`WORD_SIZE/2 - 1 : 0],{(`WORD_SIZE/2){1'b0}} } :
               `WORD_SIZE'hx;
    
endmodule