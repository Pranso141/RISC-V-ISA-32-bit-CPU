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
        casez (check) 
        6'b00zzzz: operation = 4'b0010;
        6'b01zzzz: operation = 4'b0110;
        6'b100000: operation = 4'b0010;
        6'b100001: operation = 4'b0110;
        6'b1z0010: operation = 4'b0011;
        6'b1z010z: operation = 4'b0111;
        6'b1z011z: operation = 4'b1000;
        6'b1z100z: operation = 4'b0100;
        6'b1z1010: operation = 4'b0101;
        6'b1z1011: operation = 4'b1101;
        6'b1z110z: operation = 4'b0001;
        6'b1z111z: operation = 4'b0000;
        6'b11000z: operation = 4'b0010; // ADDI (bit30 here is imm[10], not funct7 - ignore it)
        6'b110010: operation = 4'b0011; // SLLI
        6'b110100: operation = 4'b0111; // SLTI
        6'b110110: operation = 4'b1000; // SLTIU
        6'b111000: operation = 4'b0100; // XORI
        6'b111010: operation = 4'b0101; // SRLI
        6'b111011: operation = 4'b1101; // SRAI
        6'b111100: operation = 4'b0001; // ORI
        6'b111110: operation = 4'b0000; // ANDI
        default:   operation = 4'b0000;
        endcase
    end
endmodule
