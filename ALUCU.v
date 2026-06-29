`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 13:02:44
// Design Name: 
// Module Name: ALUCU
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


module ALUCU(
input [2:0]  funct3,
input [1:0] aluop,
input        b30,
output reg [3:0] operation
    );
    wire [5:0] check = {aluop , funct3 , b30};
    
    always @ (*) begin
        casex (check) 
        6'b00xxxx: operation = 4'b0010;
        6'b01xxxx: operation = 4'b0110;
        6'b100000: operation = 4'b0010;
        6'b100001: operation = 4'b0110;
        6'b1x0010: operation = 4'b0011;
        6'b1x010x: operation = 4'b0111;
        6'b1x011x: operation = 4'b1000;
        6'b1x100x: operation = 4'b0100;
        6'b1x1010: operation = 4'b0101;
        6'b1x1011: operation = 4'b1101;
        6'b1x110x: operation = 4'b0001;
        6'b1x111x: operation = 4'b0000;
        6'b11000x: operation = 4'b0010;
        default:   operation = 4'b0000;
        endcase
    end
endmodule
