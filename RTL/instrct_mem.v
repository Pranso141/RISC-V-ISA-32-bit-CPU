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


module instrct_mem(
input clk, reset,
input [31:0] read_add,
output [31:0] instruction
    );
    reg [31:0] memory [0:1023];
    assign instruction = memory[read_add >> 2];
endmodule
