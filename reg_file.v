`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 22:18:26
// Design Name: 
// Module Name: reg_file
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


module reg_file(
input clk, reset,reg_write,
input [4:0] read_reg1,
input [4:0] read_reg2,
input [4:0] write_reg,
input [31:0] write_data,
output [31:0] read_data1,
output [31:0] read_data2
    );
    
    reg [31:0] register[31:0];
    integer k;
    
    always @ (posedge clk) begin
        if (reset) begin
        for(k = 0;k < 32; k = k+1) begin
            register[k] <= 32'b0;
        end
        end
        else if (reg_write && (write_reg != 5'b0))begin
            register[write_reg] <= write_data;
        end
    
    
    end
    assign read_data1 = (read_reg1 == 5'b0) ? 32'b0 : register[read_reg1];
    assign read_data2 = (read_reg2 == 5'b0) ? 32'b0 : register[read_reg2];
endmodule
