`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/13 17:58:31
// Design Name: 
// Module Name: Cache
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

`include "custom_opcodes.v"

`define Cache_Idx_size (1<<`CacheIdx_bitno)
`define Block_word_no (1<<`Block_bitno)
`define Block_last_wordidx {`Block_bitno{1'b1}}

// NOTE: stored in little endian
// Write through with Write no-allocate

module Cache (
        input reset_n,
        input clk,
        input stall,
        
        // Memory communication
        output reg MEMORY_readM,
        output reg MEMORY_writeM,
        output reg [`WORD_SIZE - 1 : 0] MEMORY_address,
        inout [`WORD_SIZE - 1 : 0] MEMORY_data,
        input MEMORY_ready,
        
        // CPU communication
        input CPU_readM,
        input CPU_writeM,
        input [`WORD_SIZE - 1 : 0] CPU_address,
        inout [`WORD_SIZE - 1 : 0] CPU_data,
        
        output CPU_ready
        
    );
    
    // write data passline for cache active
    reg [`WORD_SIZE - 1 : 0] MEMORY_write_data;
    
    // Memory reading work register
    reg Ready_State;
    wire Hit;
    reg Miss_Handled;
    
    // Cache Miss Handling
    reg [`Block_bitno - 1 : 0] MEMORY_read_wordidx;
    reg [1:0] Pending_action;
    reg [`WORD_SIZE - 1 : 0] Pending_address;
    wire [`WORD_SIZE -1 : (`CacheIdx_bitno + `Block_bitno + 2)] Pending_address_MSB;
    wire [`CacheIdx_bitno - 1 : 0] Pending_address_idx;
    wire [`Block_bitno - 1 : 0] Pending_address_wordidx;
    
    reg [`WORD_SIZE -1 : `CacheIdx_bitno + `Block_bitno + 2] Cache_Tag[`Cache_Idx_size - 1 : 0];
    reg [`WORD_SIZE - 1 : 0] Cache_Data[`Cache_Idx_size - 1 : 0][`Block_word_no - 1 : 0];
    reg Cache_Valid[`Cache_Idx_size - 1 : 0];
    reg Cache_Dirty[`Cache_Idx_size - 1 : 0];
    
    wire [`WORD_SIZE -1 : `CacheIdx_bitno + `Block_bitno + 2] CPU_address_MSB;
    wire [`CacheIdx_bitno - 1 : 0] CPU_address_idx;
    wire [`Block_bitno - 1 : 0] CPU_address_wordidx;
    
    assign Hit = (Cache_Tag[CPU_address_idx] == CPU_address_MSB && Cache_Valid[CPU_address_idx]);
    
    // Pending address decomposition
    assign Pending_address_MSB = Pending_address[`WORD_SIZE -1 : `CacheIdx_bitno + `Block_bitno];
    assign Pending_address_idx = Pending_address[`CacheIdx_bitno + `Block_bitno -1 : `Block_bitno];
    assign Pending_address_wordidx = Pending_address[`Block_bitno -1 : 0];
    
    // reference address decomposition
    assign MEMORY_data = ( MEMORY_writeM ? MEMORY_write_data : `WORD_SIZE'hz);
    assign CPU_address_MSB = CPU_address[`WORD_SIZE -1 : `CacheIdx_bitno + `Block_bitno];
    assign CPU_address_idx = CPU_address[`CacheIdx_bitno + `Block_bitno -1 : `Block_bitno];
    assign CPU_address_wordidx = CPU_address[`Block_bitno -1 : 0];
    
    //combinational output assignment
    assign CPU_data = ( CPU_readM ? (`Cache_Latency_Apply && `Cache_Activate ? Cache_Data[CPU_address_idx][CPU_address_wordidx] : MEMORY_data) :
                             `WORD_SIZE'hz );
    assign CPU_ready = ( ~`Cache_Latency_Apply ? ( ~(CPU_readM || CPU_writeM) || MEMORY_ready ) :
                            `Cache_Activate ? 
			`Cache_Write_Through ? (Ready_State ? (~CPU_readM || Hit) && ( ~CPU_writeM || ( (Hit || ~`Cache_Write_Latency_Active) && MEMORY_ready ) || Miss_Handled) : 1'b0) :
			(Ready_State ? (~(CPU_readM || CPU_writeM) || Hit) : 1'b0) :
                       /* Cache not active */ ( ~(CPU_readM || CPU_writeM) 
                       || (Pending_address == CPU_address && 
                            (Pending_action == `Pending_Read && CPU_readM || 
                                Pending_action == `Pending_Write && CPU_writeM))) );
    
    // iteration variable
    integer it, itw;
    
    always @(*) begin
        if(~`Cache_Latency_Apply) begin
            MEMORY_readM = CPU_readM;
            MEMORY_writeM = CPU_writeM;
            MEMORY_address = CPU_address;
            MEMORY_write_data = CPU_data;
        end
        else if(`Cache_Activate) begin
            if(`Cache_Write_Through) begin
                if(CPU_writeM) begin
                    MEMORY_readM = 1'b0;
                    MEMORY_writeM = 1'b1;
                    MEMORY_address = CPU_address;
                    MEMORY_write_data = CPU_data;
                end
                else if(Ready_State == 1'b0) begin
                    MEMORY_readM = 1'b1;
                    MEMORY_writeM = 1'b0;
                    MEMORY_address = {Pending_address_MSB,Pending_address_idx,MEMORY_read_wordidx};
                end
                else begin
                    MEMORY_readM = 1'b0;
                    MEMORY_writeM = 1'b0;
                end
            end
            else if(`Cache_Write_Back) begin
                if(Ready_State == 1'b0) begin
                    if(Cache_Dirty[Pending_address_idx]) begin
                    MEMORY_readM = 1'b0;
                    MEMORY_writeM = 1'b1;
                    MEMORY_address = {Cache_Tag[Pending_address_idx],Pending_address_idx,MEMORY_read_wordidx};
                    MEMORY_write_data = Cache_Data[Pending_address_idx][MEMORY_read_wordidx];
			end
			else begin

                    MEMORY_readM = 1'b1;
                    MEMORY_writeM = 1'b0;
                    MEMORY_address = {Pending_address_MSB,Pending_address_idx,MEMORY_read_wordidx};
			end
                end
                else begin
                    MEMORY_readM = 1'b0;
                    MEMORY_writeM = 1'b0;
                end
            end
        end
        else /* Cache not active */ begin
            MEMORY_readM = CPU_readM;
            MEMORY_writeM = CPU_writeM;
            MEMORY_address = CPU_address;
            MEMORY_write_data = CPU_data;
        end
    end
    
    always @(posedge clk) begin
        if(~reset_n) begin
            for(it=0;it<`Cache_Idx_size;it=it+1) begin
                Cache_Tag[it] = 0;
                for(itw=0;itw<`Block_word_no;itw=itw+1) Cache_Data[it][itw] = 0;
                Cache_Valid[it] = 0;
                Cache_Dirty[it] = 0;
            end
            Ready_State = 1'b1;
            Pending_address = 0;
            Pending_action = `Pending_Idle;
        end
        if(`Cache_Activate) begin
		if(`Cache_Write_Through) begin
            if(CPU_writeM) begin
                if( Hit ) 
                        Cache_Data[CPU_address_idx][CPU_address_wordidx] = CPU_data;
            end
            if( ~Ready_State ) begin
                if(MEMORY_ready) begin
                    if(MEMORY_read_wordidx == `Block_last_wordidx) begin
                        Ready_State = 1'b1;
                        Miss_Handled = 1'b1;
                        if(Pending_action == `Pending_Read) begin
                            Cache_Tag[Pending_address_idx] = Pending_address_MSB;
                            Cache_Valid[Pending_address_idx] = 1'b1;
                        end
                    end
                    if(Pending_action == `Pending_Read) Cache_Data[Pending_address_idx][MEMORY_read_wordidx] = MEMORY_data;
                    MEMORY_read_wordidx = MEMORY_read_wordidx + `Block_bitno'h1;
                end
            end
            else begin
                if(stall) Miss_Handled = Miss_Handled;
                else Miss_Handled = 1'b0;
                
                if(CPU_readM) begin
                // Miss handle
                    if( ~Hit ) begin
                        Pending_action = `Pending_Read;
                        Pending_address = CPU_address;
                        MEMORY_read_wordidx = 0;
                        Ready_State = 1'b0;
                    end
                end
                else if(CPU_writeM) begin
                    if( Hit ) 
                            Cache_Data[CPU_address_idx][CPU_address_wordidx] = CPU_data;
                    else if(`Cache_Write_Latency_Active) begin
                        Pending_action = `Pending_Write;
                        Pending_address = CPU_address;
                        Ready_State = 1'b0;
                    end
                end
            end
		end
		else if(`Cache_Write_Back) begin

            if( ~Ready_State ) begin
                if(MEMORY_ready) begin
                    if(MEMORY_read_wordidx == `Block_last_wordidx) begin
                        if(Cache_Dirty[Pending_address_idx]) Cache_Dirty[Pending_address_idx] = 1'b0;
                        else begin
                            Cache_Tag[Pending_address_idx] = Pending_address_MSB;
                            Cache_Valid[Pending_address_idx] = 1'b1;
                            Ready_State = 1'b1;
                        end
                    end
                    
                    if(~Cache_Dirty[Pending_address_idx]) Cache_Data[Pending_address_idx][MEMORY_read_wordidx] = MEMORY_data;
                    MEMORY_read_wordidx = MEMORY_read_wordidx + `Block_bitno'h1;

                end
            end
            else begin
                if( CPU_writeM && Hit ) begin
                    Cache_Data[CPU_address_idx][CPU_address_wordidx] = CPU_data;
                    Cache_Dirty[CPU_address_idx] = 1'b1;
                end
                else if( (CPU_readM || CPU_writeM) && ~Hit) begin
                // Miss handle
                        Pending_address = CPU_address;
                        MEMORY_read_wordidx = 0;
                        Ready_State = 1'b0;
                end
            end

		end
        end
        else /* Cache not active */ begin
            if(MEMORY_ready) begin
                Pending_address = ( (CPU_writeM || CPU_readM)? CPU_address : -1);
                Pending_action = (CPU_readM ? `Pending_Read :
                                    CPU_writeM ? `Pending_Write :
                                                `Pending_Idle);
            end
        end
        
    end
    
    
endmodule