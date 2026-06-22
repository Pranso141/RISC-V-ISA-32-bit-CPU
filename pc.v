`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 20:49:15
// Design Name: 
// Module Name: pc
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


module pc(
input clk,
input reset,
input [31:0] nextpc,
output reg [31:0] pc
    );
    always @ (posedge clk) begin
        if (reset)
            pc <= 0;
        else
            pc <= nextpc;
    end
endmodule
