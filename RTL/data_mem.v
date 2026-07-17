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

   wire [31:0] sram_dout;
    // The 1KB macro has 256 words, so we only need an 8-bit address
    wire [7:0] word_addr = address[9:2];

    // 1. Generate the 4-bit Write Mask based on funct3
    reg [3:0] wmask;
    always @(*) begin
        if (mem_write) begin
            case(funct3)
                3'b000: wmask = 4'b0001; // sb (store byte)
                3'b001: wmask = 4'b0011; // sh (store halfword)
                3'b010: wmask = 4'b1111; // sw (store word)
                default: wmask = 4'b1111;
            endcase
        end else begin
            wmask = 4'b0000;
        end
    end

    // 2. Replicate Write Data for partial writes
    reg [31:0] sram_din;
    always @(*) begin
        case(funct3)
            3'b000: sram_din = {4{write_data[7:0]}};  // Replicate byte
            3'b001: sram_din = {2{write_data[15:0]}}; // Replicate halfword
            default: sram_din = write_data;
        endcase
    end

    // 3. Instantiate the Sky130 SRAM Macro
    sky130_sram_1kbyte_1rw1r_32x256_8 data_ram_block (
        // NEGATIVE EDGE TRICK: Fires on the falling edge of the CPU clock
        .clk0(~clk),
        .csb0(~(mem_write | mem_read)), // Active-low chip select
        .web0(~mem_write),              // Active-low write enable
        .wmask0(wmask),                 // 4-bit byte mask
        .addr0(word_addr),              // 8-bit word address
        .din0(sram_din),                // 32-bit data in
        .dout0(sram_dout),              // 32-bit data out

        // Port 1 (Read Only) - Unused for this data memory
        .clk1(1'b0),
        .csb1(1'b1),
        .addr1(8'b0),
        .dout1()
    );

    // 4. Format Read Data Output (Matching your original sign-extension logic)
    always @(*) begin
        if (mem_read) begin
            case(funct3)
                3'b000: read_data = { {24{sram_dout[7]}}, sram_dout[7:0] };
                3'b001: read_data = { {16{sram_dout[15]}}, sram_dout[15:0] };
                3'b010: read_data = sram_dout;
                3'b100: read_data = { 24'b0, sram_dout[7:0] };
                3'b101: read_data = { 16'b0, sram_dout[15:0] };
                default: read_data = sram_dout;
            endcase
        end else begin
            read_data = 32'b0;
        end
    end
endmodule
