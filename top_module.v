`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 20:39:00
// Design Name: 
// Module Name: top_module
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


module top_module(
input wire clk,rst,
output wire [31:0] current_pc
    );
    // add this new wire on line 27 or just after:
    wire [31:0] jalr_target;

    wire [31:0] nextpc, pc, pc4, instruction, imm_ext, write_data, read_data1, read_data2;
    wire [31:0] m1_output, alu_out,out_addimm,output_branchadder,mem_read_data;
    wire  reg_write, mem_read, mem_write, alu_src, jalr_src, branch, jump, alu_zero, alu_lt, alu_ltu;
    wire        pc_src;
    wire [1:0]  mem_to_reg, alu_op;
    wire [3:0]  operation;
    wire        auipc_sel;
    wire [31:0] alu_operand1;
        assign jalr_target = {output_branchadder[31:1], 1'b0};
    pc progcount (.clk(clk),.reset(rst),.nextpc(nextpc),.pc(pc));
    adder pc_inc (.in1(pc),.in2(32'd4),.out(pc4));
    instrct_mem insmem (.clk(clk),.reset(rst),.read_add(pc),.instruction(instruction));
    CU control (.opcode(instruction[6:0]),.reg_write(reg_write),.mem_read(mem_read),.mem_write(mem_write),.alu_src(alu_src),
                .mem_to_reg(mem_to_reg),.jalr_src(jalr_src),.branch(branch),.jump(jump),.alu_op(alu_op),.auipc_sel(auipc_sel));
    imm_gen immgen (.instruct(instruction),.out(imm_ext));
    reg_file regfile (.clk(clk),.reset(rst),.reg_write(reg_write),.read_reg1(instruction[19:15]),
                      .read_reg2(instruction[24:20]),.write_reg(instruction[11:7]),.write_data(write_data),
                      .read_data1(read_data1),.read_data2(read_data2));
    small_mux m1(.sel(alu_src),.C1(read_data2),.C2(imm_ext),.out(m1_output));
    small_mux alu_a_mux(.sel(auipc_sel),.C1(read_data1),.C2(pc),.out(alu_operand1));
    ALU alu (.data1(alu_operand1),.data2(m1_output),.operation(operation),.result(alu_out),.zero(alu_zero),.alu_lt(alu_lt),.alu_ltu(alu_ltu));
    ALUCU alucu (.funct3(instruction[14:12]),.aluop(alu_op),.b30(instruction[30]),.operation(operation));
    small_mux jrmux (.sel(jalr_src),.C1(pc),.C2(read_data1),.out(out_addimm));
    adder addimm (.in1(out_addimm),.in2(imm_ext),.out(output_branchadder));
    data_mem datamem (.clk(clk),.mem_read(mem_read),.mem_write(mem_write),.funct3(instruction[14:12]),
                      .address(alu_out),.write_data(read_data2),.read_data(mem_read_data));
    branch_unit brancher (.branch(branch),.jump(jump),.funct3(instruction[14:12]),.alu_zero(alu_zero),.alu_lt(alu_lt)
                         ,.alu_ltu(alu_ltu),.pc_src(pc_src));
    small_mux mmux (.sel(pc_src),.C1(pc4),.C2(jalr_target),.out(nextpc));
    wb_mux writeback_mux (.sel(mem_to_reg),.C1(alu_out),.C2(mem_read_data),.C3(pc4),.C4(imm_ext),.out(write_data));
    
    assign current_pc  = pc; 
endmodule
