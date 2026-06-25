`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 18:57:54
// Design Name: 
// Module Name: imm_gen
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


module imm_gen(
    input [31:0] instruct,
    output reg [31:0] out
    );
    always @ (*) begin
        case(instruct[6:0])
            7'b0010011: out <=  {{20{instruct[31]}},instruct[31:20]};
            7'b0000011: out <=  {{20{instruct[31]}},instruct[31:20]};
            7'b0100011: out <=  {{20{instruct[31]}},instruct[31:25],instruct[11:7]};
            7'b1100011: out <=  {{19{instruct[31]}},instruct[31],instruct[7],instruct[30:25],instruct[11:8],1'b0};
            7'b0110111: out <=  {instruct[31:12],12'b0};
            7'b0010111: out <=  {instruct[31:12],12'b0};
            7'b1101111: out <=  {{11{instruct[31]}},instruct[31],instruct[19:12],instruct[20],instruct[30:21],1'b0};
            7'b0001111: out <=  {{20{instruct[31]}},instruct[31:20]};
            7'b1110011: out <=  {{32{1'b0}}};
            default:    out <=  32'b0;
            
            
            
            endcase
    
    
    end
    
endmodule
