`define WORD_SIZE 16
/*************************************************
* DMA module (DMA.v)
* input: clock (CLK), bus request (BR) signal, 
*        data from the device (edata), and DMA command (cmd)
* output: bus grant (BG) signal 
*         READ signal
*         memory address (addr) to be written by the device, 
*         offset device offset (0 - 2)
*         data that will be written to the memory
*         interrupt to notify DMA is end
* You should NOT change the name of the I/O ports and the module name
* You can (or may have to) change the type and length of I/O ports 
* (e.g., wire -> reg) if you want 
* Do not add more ports! 
*************************************************/

`define offset_bitno 2
`define wordidx_bitno 2
`define counter_bitno (`offset_bitno + `wordidx_bitno)

module DMA (
    input CLK,
    input BG,
    input [4 * `WORD_SIZE - 1 : 0] edata,
    input [2 * `WORD_SIZE : 0] cmd,
    output reg BR,
    output READ,
    output [`WORD_SIZE - 1 : 0] addr, 
    output [`WORD_SIZE - 1 : 0] data,
    output [1:0] offset,
    output reg interrupt
    );

    /* Implement your own logic */

    // state machine for Cycle Steal
    reg BR_rest;

    // DMA command receive register
    reg [`WORD_SIZE - 1 : 0] DMA_command_address;
    reg [`WORD_SIZE - 1 : 0] DMA_command_length;
    
    // write address offset counter
    reg [`WORD_SIZE - 1 : 0] addr_count;
    
    // address offset counter decomposition wire
    wire [`wordidx_bitno - 1 : 0] wordidx;

    // write signal on bus grant
    // note that only write on this project
    assign READ = (BG ? 1'b1 : 1'bz);

    // write address is sum of base and counter
    assign addr = (BG ? DMA_command_address + addr_count : `WORD_SIZE'hz);
    
    // address offset counter decomposition
    assign wordidx = addr_count[`wordidx_bitno - 1 : 0];
    assign offset = addr_count[`offset_bitno + `wordidx_bitno - 1 : `wordidx_bitno];
    //assign interrupt = (DMA_command_length == addr_count);

    // data extracted from external device data signal
    assign data = (BG ? edata[wordidx*`WORD_SIZE +: `WORD_SIZE] : `WORD_SIZE'hz);
    

    always @(posedge CLK) begin
        if(BR) begin
            if(BG) begin
                // end of write
                if(addr_count + `WORD_SIZE'h1 == DMA_command_length) begin
                    BR = 1'b0;
                    interrupt = 1'b1;
                    //$finish;
                end
                // go to rest state for cycle steal
                else if(`Cycle_Steal_Activate && wordidx == {`wordidx_bitno{1'b1}}) begin
                    BR = 1'b0;
                    BR_rest = 1'b1;
                end
                // address offset counter on Bus Grant signal
                addr_count = addr_count + `WORD_SIZE'h1;
            end
        end
        // Bus Request rest only one cycle for cycle steal
        else if(`Cycle_Steal_Activate && BR_rest) begin
            BR_rest = 1'b0;
            BR = 1'b1;
        end
        // DMA command receive if command valid
        else if(cmd[2 * `WORD_SIZE]) begin
            DMA_command_address = cmd[2 * `WORD_SIZE - 1 : `WORD_SIZE];
            DMA_command_length = cmd[`WORD_SIZE - 1 : 0];
            BR = 1'b1;
            BR_rest = 1'b0;
            addr_count = 0;
            interrupt =1'b0;
        end
        // set to 0 on idle state
        else begin
            BR = 0;
            BR_rest = 0;
            DMA_command_address = 0;
            DMA_command_length = 0;
            addr_count = 0;
            interrupt =1'b0;
        end

    end    

endmodule

