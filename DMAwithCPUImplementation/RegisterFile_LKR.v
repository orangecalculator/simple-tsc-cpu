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
`define REG_SIZE (1<<`ADDR_BISIZE)

module RF (
	input RegWrite,
	input clk,
	input reset_n,
	input [(`ADDR_BISIZE-1):0] read_addr_1,
	input [(`ADDR_BISIZE-1):0] read_addr_2,
	input [(`ADDR_BISIZE-1):0] write_addr,
	output [(`WORD_SIZE-1):0] read_data_1,
	output [(`WORD_SIZE-1):0] read_data_2,
	input [(`WORD_SIZE-1):0] write_data
	);

reg reset_rest;

reg [`WORD_SIZE-1:0] Register[(`REG_SIZE-1):0];

integer it;

// read is independent of clock; implemented by combinational assign
assign read_data_1 = Register[read_addr_1];
assign read_data_2 = Register[read_addr_2];

always @(posedge clk) begin

	if (reset_n) begin // reset_n high means not reset
        reset_rest = 1'b1;
        if(RegWrite) Register[write_addr] = write_data;
	end // execute write if write is high
	
	else if(reset_rest) begin
        reset_rest = 1'b1;
        if(RegWrite) Register[write_addr] = write_data;
	end
	
	else begin // reset_n low means execute reset
		for( it=0; it<`REG_SIZE; it = it + 1) Register[it]=0;
	end // reset all memory
	
end

endmodule
