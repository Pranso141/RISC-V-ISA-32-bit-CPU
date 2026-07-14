`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 10:25:55
// Design Name: 
// Module Name: wb_mux
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


module wb_mux(
input [1:0] sel,
input [31:0] C1,
input [31:0] C2,
input [31:0] C3,
input [31:0] C4,
output reg [31:0] out
    );
    
    always @ (*) begin
        case (sel)
            2'b00: out = C1;
            2'b01: out = C2;
            2'b10: out = C3;
            2'b11: out = C4;
            default: out = 32'b0;
        endcase
    end
endmodule
