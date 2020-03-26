
`include "opcodes.v"

module ALU(
input [15:0] A,
input [15:0] B,
input Cin,
input [3:0] OP,
output [15:0] C,
output Cout
);

    wire [15:0] Arithmetic;
    wire Overflow;

    // activate Cout on arithmetic opertion +/-
    // implemented using the fact that OP_add is 0000 and OP_sub is 0001
    assign {Overflow,Arithmetic} = ( OP==`OP_ADD ? {1'b0,A[15:0]}+({1'b0,B[15:0]}+Cin) : 
                                             OP==`OP_SUB ? {1'b0,A[15:0]}-({1'b0,B[15:0]}+Cin) :
                                             /* else */ 0 );

    assign Cout = Overflow;
    
    // implemented the main stream of ALU by a long chain of ternary opertor
    assign C = OP==`OP_ADD ? Arithmetic :
               OP==`OP_SUB ? Arithmetic :
               OP==`OP_ID ? A :
               OP==`OP_NAND ? ~(A&B) :
               OP==`OP_NOR ? ~(A|B) :
               OP==`OP_XNOR ? (A~^B) :
               OP==`OP_NOT ? ~A :
               OP==`OP_AND ? (A&B) :
               OP==`OP_OR ? (A|B) :
               OP==`OP_XOR ? (A^B) :
               OP==`OP_LRS ? {1'b0,A[15:1]} : //  used concatenation opertor
               OP==`OP_ARS ? {A[15],A[15:1]} : // for immediate provision of values with mixed order
               OP==`OP_RR ? {A[0],A[15:1]} :
               OP==`OP_LHI ? {B[7:0],8'h00} :
               OP==`OP_ALS ? {A[14:0],1'b0} :
                             {A[14:0],A[15]} ;
    
endmodule