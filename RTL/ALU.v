`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 12:22:30
// Design Name: 
// Module Name: ALU
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


module ALU(
input [31:0] data1,
input [31:0] data2,
input [3:0] operation,
output reg [31:0] result,
output zero,
output alu_lt,
output alu_ltu
    );
    always @ (*) begin
        case (operation) 
            4'b0000: result = data1 & data2;
            4'b0001: result = data1 | data2;
            4'b0010: result = data1 + data2;
            4'b0110: result = data1 - data2;
            4'b0100: result = data1 ^ data2;
            4'b0101: result = data1 >> data2[4:0];
            4'b1101: result = $signed(data1) >>> data2[4:0];
            4'b0011: result = data1 << data2[4:0];
            4'b0111: result = $signed(data1) < $signed(data2) ? 1 : 0;
            4'b1000: result = data1 < data2 ? 1 : 0;
            default: result = 32'b0;
        endcase
    end
    assign zero = (result == 32'b0) ? 1 : 0;
assign alu_lt  = ($signed(data1) < $signed(data2))  ? 1'b1 : 1'b0;
assign alu_ltu = (data1 < data2)                     ? 1'b1 : 1'b0;
endmodule
