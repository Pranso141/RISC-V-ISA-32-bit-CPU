`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 10:35:05
// Design Name: 
// Module Name: small_mux
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


module small_mux(
input sel,
input [31:0] C1,
input [31:0] C2,
output reg [31:0] out
    );
    
    always @ (*) begin
        case (sel)
            1'b0: out = C1;
            1'b1: out = C2;
            default: out = 32'b0;
        endcase
    end
endmodule
