
`define DMA_Task_Address (`WORD_SIZE'h01f4)
`define DMA_Task_Length (`WORD_SIZE'd0012)

module DMAhandler(
        input reset_n,
        input clk,

        input DMA_begin,
        input DMA_end,
        input Bus_Request,
        output Bus_Grant,

        output [2 * `WORD_SIZE : 0] DMA_command,

        // Memory communication
        output MEMORY_readM,
        output MEMORY_writeM,
        output [`WORD_SIZE - 1 : 0] MEMORY_address,
        inout [`WORD_SIZE - 1 : 0] MEMORY_data,
        
        // CPU Memory Task
        input CPU_readM,
        input CPU_writeM,
        input [`WORD_SIZE - 1 : 0] CPU_address,
        inout [`WORD_SIZE - 1 : 0] CPU_data,
        
        output CPU_ready
);

    // DMA handler activation FSM
    reg DMA_pending;
    
    reg Bus_Grant_hist;

    reg DMA_command_valid;
    // DMA command with valid bit, address, length
    // note that address and length is fixed for this project
    assign DMA_command = {DMA_command_valid,`DMA_Task_Address,`DMA_Task_Length};

    // pass cache signal if Bus is not granted
    assign MEMORY_readM = ( ~Bus_Grant ? CPU_readM : 0 );
    assign MEMORY_writeM = ( ~Bus_Grant ? CPU_writeM : 1'hz );
    assign MEMORY_address = ( ~Bus_Grant ? CPU_address : `WORD_SIZE'hz );
    assign MEMORY_data = ( ~Bus_Grant ? ( MEMORY_writeM ? CPU_data : `WORD_SIZE'hz) : `WORD_SIZE'hz );
        // pass memory data to CPU on read
    assign CPU_data = ( ~Bus_Grant ? ( CPU_readM ? MEMORY_data : `WORD_SIZE'hz) : `WORD_SIZE'hz );

    // Bus Grant signal HIGH on Bus Request and CPU memory operation idle
    assign Bus_Grant = `DMA_Activate && Bus_Request && ( Bus_Grant_hist || (~CPU_readM && ~CPU_writeM) );
    assign CPU_ready = ~Bus_Grant;

    always @(posedge clk) begin
        
        // Bus Grant history for Bus Grant
        Bus_Grant_hist = Bus_Grant;
        
        // DMA command valid bit is synchronized on DMA begin
        DMA_command_valid = DMA_begin;
    
    end

endmodule