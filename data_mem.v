`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 15:22:56
// Design Name: 
// Module Name: data_mem
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


`timescale 1ns / 1ps

module data_mem(
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [2:0]  funct3,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);

    reg [31:0] memory [0:1023];
    
    wire [9:0] word_addr = address[11:2];

    always @(posedge clk) begin
        if (mem_write) begin
            case(funct3)
                3'b000: begin
                    memory[word_addr][7:0] <= write_data[7:0];
                end
                3'b001: begin
                    memory[word_addr][15:0] <= write_data[15:0];
                end
                3'b010: begin
                    memory[word_addr] <= write_data;
                end
                default: begin
                    memory[word_addr] <= write_data;
                end
            endcase
        end
    end

    always @(*) begin
        if (mem_read) begin
            case(funct3)
                3'b000: read_data = { {24{memory[word_addr][7]}}, memory[word_addr][7:0] };
                3'b001: read_data = { {16{memory[word_addr][15]}}, memory[word_addr][15:0] };
                3'b010: read_data = memory[word_addr];
                3'b100: read_data = { 24'b0, memory[word_addr][7:0] };
                3'b101: read_data = { 16'b0, memory[word_addr][15:0] };
                default: begin
                    read_data = memory[word_addr];
                end
            endcase
        end else begin
            read_data = 32'b0; 
        end
    end

endmodule
