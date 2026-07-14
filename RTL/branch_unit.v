`timescale 1ns / 1ps

module branch_unit(
    input  wire       branch,          // From CU: Is this a branch instruction?
    input  wire       jump,            // From CU: Is this a jump instruction (jal/jalr)?
    input  wire [2:0] funct3,          // From instruction: Tells us which comparison to make
    input  wire       alu_zero,        // From ALU: High if inputs are equal
    input  wire       alu_lt,          // From ALU: High if input A < input B (signed/unsigned)
    input  wire       alu_ltu,
    output wire       pc_src           // To Top Mux: 1 = branch/jump taken, 0 = PC+4
);

    reg branch_taken;

    always @(*) begin
        case (funct3)
            3'b000:  branch_taken = alu_zero;   // beq
            3'b001:  branch_taken = ~alu_zero;  // bne
            3'b100:  branch_taken = alu_lt;     // blt
            3'b101:  branch_taken = ~alu_lt;    // bge
            3'b110:  branch_taken = alu_ltu;     // bltu (if your ALU handles unsigned lt)
            3'b111:  branch_taken = ~alu_ltu;    // bgeu (if your ALU handles unsigned lt)
            default: branch_taken = 1'b0;
        endcase
    end

    // The final decision: Change the PC path if it's an unconditional jump, 
    // OR if it's a branch instruction and the specific math condition is met.
    assign pc_src = jump | (branch & branch_taken);

endmodule
