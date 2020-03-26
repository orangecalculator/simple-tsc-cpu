`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/26 17:03:16
// Design Name: 
// Module Name: RegisterFile
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


`define ADDR_BISIZE (`addr_bitno)
`define MEM_SIZE (1<<`ADDR_BISIZE)

module RF (
	input write,
	input clk,
	input reset_n,
	input [(`ADDR_BISIZE-1):0] addr1,
	input [(`ADDR_BISIZE-1):0] addr2,
	input [(`ADDR_BISIZE-1):0] addr3,
	output [(`WORD_SIZE-1):0] data1,
	output [(`WORD_SIZE-1):0] data2,
	input [(`WORD_SIZE-1):0] data3
	);

reg [`WORD_SIZE-1:0] memory[(`MEM_SIZE-1):0];

integer it;

// read is independent of clock; implemented by combinational assign
assign data1 = memory[addr1];
assign data2 = memory[addr2];

always @(posedge clk) begin

	if (reset_n) begin // reset_n high means not reset
		if(write) memory[addr3] = data3;
	end // execute write if write is high
	
	else begin // reset_n low means execute reset
		for( it=0; it<`MEM_SIZE; it = it + 1) memory[it]=0;
	end // reset all memory
	
end

endmodule
