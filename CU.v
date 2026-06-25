`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 10:14:03
// Design Name: 
// Module Name: CU
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


module CU(
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        alu_src,       
    output reg [1:0]  mem_to_reg,    
    output reg        jalr_src,      
    output reg        branch,
    output reg        jump,
    output reg [1:0]  alu_op         
);

    always @(*) begin
        reg_write = 0; mem_read = 0; mem_write = 0; alu_src = 0;
        mem_to_reg = 2'b00; jalr_src = 0; branch = 0; jump = 0; alu_op = 2'b00;

        case(opcode)
            7'b0110011: begin 
                reg_write  = 1;
                alu_op     = 2'b10; 
            end
            7'b0010011: begin 
                reg_write  = 1;
                alu_src    = 1;
                alu_op     = 2'b11; 
            end
            7'b0000011: begin 
                reg_write  = 1;
                alu_src    = 1;
                mem_read   = 1;
                mem_to_reg = 2'b01; 
            end
            7'b0100011: begin 
                alu_src    = 1;
                mem_write  = 1;
            end
            7'b1100011: begin 
                branch     = 1;
                alu_op     = 2'b01;
            end
            7'b1101111: begin 
                reg_write  = 1;
                jump       = 1;
                mem_to_reg = 2'b10; 
            end
            7'b1100111: begin
                reg_write  = 1;
                jump       = 1;
                jalr_src   = 1;     
                mem_to_reg = 2'b10; 
            end
            7'b0110111: begin 
                reg_write  = 1;
                mem_to_reg = 2'b11; 
            end
            7'b0010111: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b00;
                alu_op     = 2'b00;  
            end

            7'b0001111, 7'b1110011: begin
                reg_write  = 1'b0;
                mem_write  = 1'b0;
            end
            default: ; 
        endcase
    end
endmodule