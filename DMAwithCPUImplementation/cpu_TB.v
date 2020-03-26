/*************************************************
* testbench (cpu_TB.v)
* You should NOT change the name of the variables and the instance name
* You can (or may have to) change the type and length of I/O ports 
* (e.g., wire -> reg) if you want 
* Do not add more ports! 
* Please copy and paste below codes in your testbench.
* Then, adjust the settings as you wish following above constrains.
* Also, please increase the memory size from 256 to 512.
*************************************************/

`define WORD_SIZE 16
`define MEMORY_SIZE 512 /* Orignally, 256 */

reg [`WORD_SIZE - 1 : 0] memory [`MEMORY_SIZE - 1 : 0];

wire BG;
wire cmd;
wire BR;
wire [4 * `WORD_SIZE - 1 : 0] edata;
wire dma_READ;
wire [`WORD_SIZE - 1 : 0] dma_addr;
wire [`WORD_SIZE * 4 - 1 : 0] dma_data;
wire [1:0] dma_offset;
wire dma_end_int;
wire dma_start_int;

DMA DMA(.CLK(CLK), .BG(BG),  .edata(edata), .cmd(cmd), .BR(BR), .READ(dma_READ),
    .addr(dma_addr), .data(dma_data), .offset(dma_offset), .interrupt(dma_end_int));
external_device edevice(.offset(offset), .interrupt(dma_start_int), .data(edata));