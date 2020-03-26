
 `include "opcodes.v"
 `include "custom_opcodes.v"
 `include "constants.v"

module ALU(
input [15:0] A,
input [15:0] B,
input Cin,
input [3:0] OP,
output [15:0] C,
output Cout,
output [1:0] Compare
);

    wire [15:0] Arithmetic;
    wire Overflow;

    // activate Cout on arithmetic opertion +/-
    // implemented using the fact that OP_add is 0000 and OP_sub is 0001
    assign {Overflow,Arithmetic} = ( OP==`OP_ADD ? {1'b0,A[15:0]}+({1'b0,B[15:0]}+{15'b0,Cin}) : 
                                             OP==`OP_SUB ? {1'b0,A[15:0]}-({1'b0,B[15:0]}+{15'b0,Cin}) :
                                             /* else */ 0 );

    assign Cout = Overflow;
    
    // 00 : same, 10 : bigger(>), 11 : smaller(<)
    assign Compare = ( OP==`OP_SUB ? ( Arithmetic == `WORD_SIZE'h0 ? 2'b00 : {1'b1,Arithmetic[`WORD_SIZE - 1]} ) : 2'b00 );
    
    // implemented the main stream of ALU by a long chain of ternary opertor
    assign C = OP==`OP_ADD ? Arithmetic :
               OP==`OP_SUB ? Arithmetic :
               OP==`OP_TCP ? -A :
               OP==`OP_NOT ? ~A :
               OP==`OP_AND ? (A&B) :
               OP==`OP_ORR ? (A|B) :
               OP==`OP_SHL ? {A[`WORD_SIZE - 2 : 0],1'b0} :
               OP==`OP_SHR ? {A[`WORD_SIZE - 1],A[`WORD_SIZE - 1 : 1]} :
               OP==`OP_LHI ? {B[`WORD_SIZE/2 - 1 : 0],{(`WORD_SIZE/2){1'b0}} } :
               `WORD_SIZE'hx;
    
endmodule