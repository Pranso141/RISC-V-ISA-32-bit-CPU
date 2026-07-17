`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 21:37:21
// Design Name: 
// Module Name: instrct_mem
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


`timescale 1ns / 1ps

module instrct_mem(
    input clk,
    input reset,
    input [31:0] read_add,
    output [31:0] instruction
);

    // The 1KB macro has 256 words, requiring an 8-bit address
    wire [7:0] word_addr = read_add[9:2];

    // Instantiate the Sky130 1KB SRAM Macro as Read-Only
    sky130_sram_1kbyte_1rw1r_32x256_8 inst_ram_block (
        .clk0(~clk),                    // Negative edge trick for single-cycle
        .csb0(1'b0),                    // Active-low Chip Select (Always 0 to enable)
        .web0(1'b1),                    // Active-low Write Enable (Always 1 for Read-Only)
        .wmask0(4'b0000),               // Write mask (Disabled)
        .addr0(word_addr),              // 8-bit instruction address
        .din0(32'b0),                   // Data Input (Tied to ground)
        .dout0(instruction),            // Outputs directly to your CPU's instruction bus

        // Port 1 (Unused)
        .clk1(1'b0),
        .csb1(1'b1),
        .addr1(8'b0),
        .dout1()
    );

endmodule
