`timescale 1ns / 1ps
//==============================================================================
// Testbench: tb_top_module
// Tests all 40 RV32I instructions by loading real machine code into
// instruction memory via hierarchical path access.
//
// Register usage convention in this testbench:
//   x1  = primary result / scratch
//   x2  = second operand / scratch
//   x3  = expected value for comparison
//   x4-x31 = used freely per group
//
// Memory layout:
//   Instruction memory: word-addressed [0:1023]
//   Data memory:        word-addressed [0:1023], base byte addr = 0x0000
//==============================================================================

module tb_top_module;

    // ?? DUT ports ??????????????????????????????????????????????????????????
    reg         clk;
    reg         rst;
    wire [31:0] current_pc;

    // ?? Instantiate DUT ????????????????????????????????????????????????????
    top_module dut (
        .clk        (clk),
        .rst        (rst),
        .current_pc (current_pc)
    );

    // ?? Clock: 10 ns period ????????????????????????????????????????????????
    initial clk = 0;
    always #5 clk = ~clk;

    // ?? Helpers ????????????????????????????????????????????????????????????
    integer pass_count;
    integer fail_count;

    // Read register from reg file via hierarchical path
    function [31:0] reg_read;
        input [4:0] r;
        reg_read = dut.regfile.register[r];
    endfunction

    // Read data memory word via hierarchical path
    function [31:0] mem_read_word;
        input [9:0] word_idx;
        mem_read_word = dut.datamem.memory[word_idx];
    endfunction

    // Write instruction word into instruction memory
    task load_instr;
        input [9:0]  addr;   // word index
        input [31:0] instr;
        begin
            dut.insmem.memory[addr] = instr;
        end
    endtask

    // Check: compare reg[rd] with expected, print PASS/FAIL
    task check_reg;
        input [4:0]  rd;
        input [31:0] expected;
        input [63:0] test_name; // up to 8 chars packed
        reg   [31:0] got;
        begin
            got = reg_read(rd);
            if (got === expected) begin
                $display("  PASS  %-10s  x%0d = 0x%08h", test_name, rd, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %-10s  x%0d = 0x%08h  (expected 0x%08h)",
                         test_name, rd, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Check data memory word
    task check_mem;
        input [9:0]  word_idx;
        input [31:0] expected;
        input [63:0] test_name;
        reg   [31:0] got;
        begin
            got = mem_read_word(word_idx);
            if (got === expected) begin
                $display("  PASS  %-10s  mem[%0d] = 0x%08h", test_name, word_idx, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %-10s  mem[%0d] = 0x%08h  (expected 0x%08h)",
                         test_name, word_idx, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Run N clock cycles, then one extra so the last instruction's
    // synchronous reg-file write (posedge clk) has committed before
    // the testbench reads back register values.
    task run_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
            @(posedge clk); // extra cycle: let write-back settle
            #1;
        end
    endtask

    // Clear all instruction memory (fill with NOP = ADDI x0,x0,0)
    task clear_imem;
        integer i;
        begin
            for (i = 0; i < 1024; i = i + 1)
                dut.insmem.memory[i] = 32'h00000013; // NOP
        end
    endtask

    // Clear data memory
    task clear_dmem;
        integer i;
        begin
            for (i = 0; i < 1024; i = i + 1)
                dut.datamem.memory[i] = 32'h00000000;
        end
    endtask

    // Reset DUT
    task do_reset;
        begin
            rst = 1;
            @(posedge clk); #1;
            @(posedge clk); #1;
            rst = 0;
            @(posedge clk); #1;
        end
    endtask

    //==========================================================================
    // INSTRUCTION ENCODING FUNCTIONS
    // Each returns a 32-bit machine word.
    //==========================================================================

    // R-type: funct7 | rs2 | rs1 | funct3 | rd | opcode
    function [31:0] R;
        input [6:0] funct7;
        input [4:0] rs2, rs1, rd;
        input [2:0] funct3;
        input [6:0] opcode;
        R = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    // I-type: imm[11:0] | rs1 | funct3 | rd | opcode
    function [31:0] I;
        input [11:0] imm;
        input [4:0]  rs1, rd;
        input [2:0]  funct3;
        input [6:0]  opcode;
        I = {imm, rs1, funct3, rd, opcode};
    endfunction

    // S-type: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
    function [31:0] S;
        input [11:0] imm;
        input [4:0]  rs2, rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        S = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction

    // B-type: imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode
    function [31:0] B;
        input [12:0] imm; // signed, bit 0 always 0
        input [4:0]  rs2, rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        B = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction

    // U-type: imm[31:12] | rd | opcode
    function [31:0] U;
        input [19:0] imm; // upper 20 bits
        input [4:0]  rd;
        input [6:0]  opcode;
        U = {imm, rd, opcode};
    endfunction

    // J-type: imm[20|10:1|11|19:12] | rd | opcode
    function [31:0] J;
        input [20:0] imm; // signed, bit 0 always 0
        input [4:0]  rd;
        input [6:0]  opcode;
        J = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    // Convenience wrappers for common instructions
    // ADDI rd, rs1, imm
    function [31:0] ADDI;  input [4:0] rd,rs1; input [11:0] imm;
        ADDI = I(imm, rs1, rd, 3'b000, 7'b0010011); endfunction
    // ADD rd, rs1, rs2
    function [31:0] ADD;   input [4:0] rd,rs1,rs2;
        ADD  = R(7'b0000000, rs2, rs1, rd, 3'b000, 7'b0110011); endfunction
    // SUB rd, rs1, rs2
    function [31:0] SUB;   input [4:0] rd,rs1,rs2;
        SUB  = R(7'b0100000, rs2, rs1, rd, 3'b000, 7'b0110011); endfunction
    // AND rd, rs1, rs2
    function [31:0] AND_;  input [4:0] rd,rs1,rs2;
        AND_ = R(7'b0000000, rs2, rs1, rd, 3'b111, 7'b0110011); endfunction
    // OR  rd, rs1, rs2
    function [31:0] OR_;   input [4:0] rd,rs1,rs2;
        OR_  = R(7'b0000000, rs2, rs1, rd, 3'b110, 7'b0110011); endfunction
    // XOR rd, rs1, rs2
    function [31:0] XOR_;  input [4:0] rd,rs1,rs2;
        XOR_ = R(7'b0000000, rs2, rs1, rd, 3'b100, 7'b0110011); endfunction
    // SLL rd, rs1, rs2
    function [31:0] SLL_;  input [4:0] rd,rs1,rs2;
        SLL_ = R(7'b0000000, rs2, rs1, rd, 3'b001, 7'b0110011); endfunction
    // SRL rd, rs1, rs2
    function [31:0] SRL_;  input [4:0] rd,rs1,rs2;
        SRL_ = R(7'b0000000, rs2, rs1, rd, 3'b101, 7'b0110011); endfunction
    // SRA rd, rs1, rs2
    function [31:0] SRA_;  input [4:0] rd,rs1,rs2;
        SRA_ = R(7'b0100000, rs2, rs1, rd, 3'b101, 7'b0110011); endfunction
    // SLT rd, rs1, rs2
    function [31:0] SLT_;  input [4:0] rd,rs1,rs2;
        SLT_ = R(7'b0000000, rs2, rs1, rd, 3'b010, 7'b0110011); endfunction
    // SLTU rd, rs1, rs2
    function [31:0] SLTU_; input [4:0] rd,rs1,rs2;
        SLTU_= R(7'b0000000, rs2, rs1, rd, 3'b011, 7'b0110011); endfunction
    // ANDI rd, rs1, imm
    function [31:0] ANDI;  input [4:0] rd,rs1; input [11:0] imm;
        ANDI = I(imm, rs1, rd, 3'b111, 7'b0010011); endfunction
    // ORI rd, rs1, imm
    function [31:0] ORI;   input [4:0] rd,rs1; input [11:0] imm;
        ORI  = I(imm, rs1, rd, 3'b110, 7'b0010011); endfunction
    // XORI rd, rs1, imm
    function [31:0] XORI;  input [4:0] rd,rs1; input [11:0] imm;
        XORI = I(imm, rs1, rd, 3'b100, 7'b0010011); endfunction
    // SLTI rd, rs1, imm
    function [31:0] SLTI;  input [4:0] rd,rs1; input [11:0] imm;
        SLTI = I(imm, rs1, rd, 3'b010, 7'b0010011); endfunction
    // SLTIU rd, rs1, imm
    function [31:0] SLTIU; input [4:0] rd,rs1; input [11:0] imm;
        SLTIU= I(imm, rs1, rd, 3'b011, 7'b0010011); endfunction
    // SLLI rd, rs1, shamt
    function [31:0] SLLI;  input [4:0] rd,rs1,shamt;
        SLLI = {7'b0000000, shamt, rs1, 3'b001, rd, 7'b0010011}; endfunction
    // SRLI rd, rs1, shamt
    function [31:0] SRLI;  input [4:0] rd,rs1,shamt;
        SRLI = {7'b0000000, shamt, rs1, 3'b101, rd, 7'b0010011}; endfunction
    // SRAI rd, rs1, shamt
    function [31:0] SRAI;  input [4:0] rd,rs1,shamt;
        SRAI = {7'b0100000, shamt, rs1, 3'b101, rd, 7'b0010011}; endfunction
    // LW rd, imm(rs1)
    function [31:0] LW;    input [4:0] rd,rs1; input [11:0] imm;
        LW   = I(imm, rs1, rd, 3'b010, 7'b0000011); endfunction
    // LH rd, imm(rs1)
    function [31:0] LH;    input [4:0] rd,rs1; input [11:0] imm;
        LH   = I(imm, rs1, rd, 3'b001, 7'b0000011); endfunction
    // LB rd, imm(rs1)
    function [31:0] LB;    input [4:0] rd,rs1; input [11:0] imm;
        LB   = I(imm, rs1, rd, 3'b000, 7'b0000011); endfunction
    // LHU rd, imm(rs1)
    function [31:0] LHU;   input [4:0] rd,rs1; input [11:0] imm;
        LHU  = I(imm, rs1, rd, 3'b101, 7'b0000011); endfunction
    // LBU rd, imm(rs1)
    function [31:0] LBU;   input [4:0] rd,rs1; input [11:0] imm;
        LBU  = I(imm, rs1, rd, 3'b100, 7'b0000011); endfunction
    // SW rs2, imm(rs1)
    function [31:0] SW;    input [4:0] rs2,rs1; input [11:0] imm;
        SW   = S(imm, rs2, rs1, 3'b010, 7'b0100011); endfunction
    // SH rs2, imm(rs1)
    function [31:0] SH;    input [4:0] rs2,rs1; input [11:0] imm;
        SH   = S(imm, rs2, rs1, 3'b001, 7'b0100011); endfunction
    // SB rs2, imm(rs1)
    function [31:0] SB_;   input [4:0] rs2,rs1; input [11:0] imm;
        SB_  = S(imm, rs2, rs1, 3'b000, 7'b0100011); endfunction
    // BEQ rs1, rs2, imm
    function [31:0] BEQ;   input [4:0] rs1,rs2; input [12:0] imm;
        BEQ  = B(imm, rs2, rs1, 3'b000, 7'b1100011); endfunction
    // BNE rs1, rs2, imm
    function [31:0] BNE;   input [4:0] rs1,rs2; input [12:0] imm;
        BNE  = B(imm, rs2, rs1, 3'b001, 7'b1100011); endfunction
    // BLT rs1, rs2, imm
    function [31:0] BLT;   input [4:0] rs1,rs2; input [12:0] imm;
        BLT  = B(imm, rs2, rs1, 3'b100, 7'b1100011); endfunction
    // BGE rs1, rs2, imm
    function [31:0] BGE;   input [4:0] rs1,rs2; input [12:0] imm;
        BGE  = B(imm, rs2, rs1, 3'b101, 7'b1100011); endfunction
    // BLTU rs1, rs2, imm
    function [31:0] BLTU;  input [4:0] rs1,rs2; input [12:0] imm;
        BLTU = B(imm, rs2, rs1, 3'b110, 7'b1100011); endfunction
    // BGEU rs1, rs2, imm
    function [31:0] BGEU;  input [4:0] rs1,rs2; input [12:0] imm;
        BGEU = B(imm, rs2, rs1, 3'b111, 7'b1100011); endfunction
    // LUI rd, imm[31:12]
    function [31:0] LUI;   input [4:0] rd; input [19:0] imm;
        LUI  = U(imm, rd, 7'b0110111); endfunction
    // AUIPC rd, imm[31:12]
    function [31:0] AUIPC; input [4:0] rd; input [19:0] imm;
        AUIPC= U(imm, rd, 7'b0010111); endfunction
    // JAL rd, imm
    function [31:0] JAL;   input [4:0] rd; input [20:0] imm;
        JAL  = J(imm, rd, 7'b1101111); endfunction
    // JALR rd, rs1, imm
    function [31:0] JALR;  input [4:0] rd,rs1; input [11:0] imm;
        JALR = I(imm, rs1, rd, 3'b000, 7'b1100111); endfunction
    // NOP = ADDI x0,x0,0  (dummy input required by Verilog-2001)
    function [31:0] NOP_;  input dummy;
        NOP_ = 32'h00000013; endfunction
    // FENCE
    function [31:0] FENCE_; input dummy;
        FENCE_= 32'h0000000F; endfunction
    // ECALL
    function [31:0] ECALL_; input dummy;
        ECALL_= 32'h00000073; endfunction
    // EBREAK
    function [31:0] EBREAK_; input dummy;
        EBREAK_= 32'h00100073; endfunction

    //==========================================================================
    // MAIN TEST SEQUENCE
    //==========================================================================
    integer i;
    reg [31:0] mval;   // shared temp for inline memory checks

    initial begin
        $display("=============================================================");
        $display(" RISC-V Single-Cycle Core - Full 40-Instruction Testbench");
        $display("=============================================================");
        pass_count = 0;
        fail_count = 0;
        rst = 1;
        clear_imem;
        clear_dmem;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;

        // ??????????????????????????????????????????????????????????????????
        // GROUP 1: R-TYPE (10 instructions)
        // ADD SUB AND OR XOR SLL SRL SRA SLT SLTU
        // Strategy: pre-load operands with ADDI, then execute R-type ops
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 1: R-type ??????????????????????????????????????????");
        clear_imem;
        // x1 = 20, x2 = 7, x3 = -5 (0xFFFFFFFB), x4 = 0x80000000
        // Slot 0:  ADDI x1, x0, 20
        load_instr(0,  ADDI(1,  0, 12'd20));
        // Slot 1:  ADDI x2, x0, 7
        load_instr(1,  ADDI(2,  0, 12'd7));
        // Slot 2:  ADDI x3, x0, -5   (0xFFB in 12-bit signed = -5)
        load_instr(2,  ADDI(3,  0, 12'hFFB));
        // Slot 3:  LUI  x4, 0x80000  ? x4 = 0x80000000
        load_instr(3,  LUI(4, 20'h80000));
        // Slot 4:  ADD  x5, x1, x2   ? 20+7 = 27
        load_instr(4,  ADD(5, 1, 2));
        // Slot 5:  SUB  x6, x1, x2   ? 20-7 = 13
        load_instr(5,  SUB(6, 1, 2));
        // Slot 6:  AND  x7, x1, x2   ? 20&7 = 4
        load_instr(6,  AND_(7, 1, 2));
        // Slot 7:  OR   x8, x1, x2   ? 20|7 = 23
        load_instr(7,  OR_(8, 1, 2));
        // Slot 8:  XOR  x9, x1, x2   ? 20^7 = 19
        load_instr(8,  XOR_(9, 1, 2));
        // Slot 9:  SLL  x10, x1, x2  ? 20<<7 = 2560
        load_instr(9,  SLL_(10, 1, 2));
        // Slot 10: SRL  x11, x1, x2  ? 20>>7 = 0
        load_instr(10, SRL_(11, 1, 2));
        // Slot 11: ADDI x12, x0, -128 (0xF80)
        load_instr(11, ADDI(12, 0, 12'hF80));
        // Slot 12: SRA  x13, x12, x2 ? -128>>>7 = -1
        load_instr(12, SRA_(13, 12, 2));
        // Slot 13: SLT  x14, x3, x1  ? -5 < 20 = 1
        load_instr(13, SLT_(14, 3, 1));
        // Slot 14: SLTU x15, x3, x1  ? 0xFFFFFFFB < 20 = 0 (unsigned)
        load_instr(14, SLTU_(15, 3, 1));
        // Slots 15-19: NOPs then halt loop
        for (i=15; i<20; i=i+1) load_instr(i, NOP_(1));
        // Slot 20: JAL x0, 0 (infinite loop to halt)
        load_instr(20, JAL(0, 21'h0));

        do_reset;

        run_cycles(20);
        check_reg(5,  32'd27,         "ADD");
        check_reg(6,  32'd13,         "SUB");
        check_reg(7,  32'd4,          "AND");
        check_reg(8,  32'd23,         "OR");
        check_reg(9,  32'd19,         "XOR");
        check_reg(10, 32'd2560,       "SLL");
        check_reg(11, 32'd0,          "SRL");
        check_reg(13, 32'hFFFFFFFF,   "SRA");
        check_reg(14, 32'd1,          "SLT");
        check_reg(15, 32'd0,          "SLTU");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 2: I-TYPE ALU (9 instructions)
        // ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 2: I-type ALU ??????????????????????????????????????");
        clear_imem;
        // x1 = 20
        load_instr(0, ADDI(1, 0, 12'd20));
        // x2 = -1 (0xFFF)
        load_instr(1, ADDI(2, 0, 12'hFFF));
        // ADDI x3, x1, 5  ? 25
        load_instr(2, ADDI(3, 1, 12'd5));
        // SLTI x4, x2, 1  ? -1 < 1 = 1
        load_instr(3, SLTI(4, 2, 12'd1));
        // SLTIU x5, x2, 1 ? 0xFFFFFFFF < 1 = 0 (unsigned)
        load_instr(4, SLTIU(5, 2, 12'd1));
        // XORI x6, x1, 15 ? 20^15 = 27
        load_instr(5, XORI(6, 1, 12'd15));
        // ORI  x7, x1, 3  ? 20|3 = 23
        load_instr(6, ORI(7, 1, 12'd3));
        // ANDI x8, x1, 14 ? 20&14 = 4
        load_instr(7, ANDI(8, 1, 12'd14));
        // SLLI x9, x1, 2  ? 20<<2 = 80
        load_instr(8, SLLI(9, 1, 5'd2));
        // SRLI x10, x1, 1 ? 20>>1 = 10
        load_instr(9, SRLI(10, 1, 5'd1));
        // x11 = -128
        load_instr(10, ADDI(11, 0, 12'hF80));
        // SRAI x12, x11, 3 ? -128>>>3 = -16
        load_instr(11, SRAI(12, 11, 5'd3));
        for (i=12; i<14; i=i+1) load_instr(i, NOP_(1));
        load_instr(14, JAL(0, 21'h0));

        do_reset;

        run_cycles(16);
        check_reg(3,  32'd25,         "ADDI");
        check_reg(4,  32'd1,          "SLTI");
        check_reg(5,  32'd0,          "SLTIU");
        check_reg(6,  32'd27,         "XORI");
        check_reg(7,  32'd23,         "ORI");
        check_reg(8,  32'd4,          "ANDI");
        check_reg(9,  32'd80,         "SLLI");
        check_reg(10, 32'd10,         "SRLI");
        check_reg(12, 32'hFFFFFFF0,   "SRAI");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 3: LOADS (LW LH LB LHU LBU)
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 3: Load instructions ???????????????????????????????");
        clear_imem; clear_dmem;
        // Pre-load data memory[0] = 0xDEADBEEF, mem[1] = 0x00008080
        dut.datamem.memory[0] = 32'hDEADBEEF;
        dut.datamem.memory[1] = 32'h00008080;
        // x1 = base addr 0 (already 0 from reset)
        // LW  x2, 0(x1) ? 0xDEADBEEF
        load_instr(0, LW(2,  1, 12'd0));
        // LH  x3, 0(x1) ? sign-extend 0xBEEF = 0xFFFFBEEF
        load_instr(1, LH(3,  1, 12'd0));
        // LB  x4, 0(x1) ? sign-extend 0xEF = 0xFFFFFFEF
        load_instr(2, LB(4,  1, 12'd0));
        // x5 = addr 4 (byte addr of word[1])
        load_instr(3, ADDI(5, 0, 12'd4));
        // LHU x6, 0(x5) ? zero-extend lower half of mem[1] = 0x00008080
        load_instr(4, LHU(6, 5, 12'd0));
        // LBU x7, 0(x5) ? zero-extend byte = 0x80
        load_instr(5, LBU(7, 5, 12'd0));
        for (i=6; i<8; i=i+1) load_instr(i, NOP_(1));
        load_instr(8, JAL(0, 21'h0));

        do_reset;

        run_cycles(10);
        check_reg(2, 32'hDEADBEEF,  "LW");
        check_reg(3, 32'hFFFFBEEF,  "LH");
        check_reg(4, 32'hFFFFFFEF,  "LB");
        check_reg(6, 32'h00008080,  "LHU");
        check_reg(7, 32'h00000080,  "LBU");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 4: STORES (SW SH SB)
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 4: Store instructions ??????????????????????????????");
        clear_imem; clear_dmem;
        // x1 = 0xABCD1234
        load_instr(0, LUI(1,  20'hABCD1));     // x1 = 0xABCD1000
        load_instr(1, ADDI(1, 1, 12'h234));    // x1 = 0xABCD1234
        // x2 = base addr 0
        // SW x1, 0(x2)  ? mem[0] = 0xABCD1234
        load_instr(2, SW(1, 0, 12'd0));
        // x3 = 0x5A5A
        load_instr(3, ADDI(3, 0, 12'h5A5));    // partial (only 12 bits)
        // SH x3, 4(x2)  ? mem[1] lower half = 0x5A5
        load_instr(4, SH(3, 0, 12'd4));
        // x4 = 0xFF
        load_instr(5, ADDI(4, 0, 12'hFF));
        // SB x4, 8(x2)  ? mem[2] byte 0 = 0xFF
        load_instr(6, SB_(4, 0, 12'd8));
        for (i=7; i<9; i=i+1) load_instr(i, NOP_(1));
        load_instr(9, JAL(0, 21'h0));

        do_reset;

        run_cycles(12);
        check_mem(0, 32'hABCD1234,  "SW");
        // SH stored 0x5A5 into lower 16 bits of mem[1]
        begin : chk_sh
            mval = mem_read_word(1);
            if (mval[15:0] === 16'h05A5) begin
                $display("  PASS  SH         mem[1][15:0] = 0x%04h", mval[15:0]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  SH         mem[1][15:0] = 0x%04h (expected 0x05A5)", mval[15:0]);
                fail_count = fail_count + 1;
            end
        end
        begin : chk_sb
            mval = mem_read_word(2);
            if (mval[7:0] === 8'hFF) begin
                $display("  PASS  SB         mem[2][7:0]  = 0x%02h", mval[7:0]);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  SB         mem[2][7:0]  = 0x%02h (expected 0xFF)", mval[7:0]);
                fail_count = fail_count + 1;
            end
        end

        // ??????????????????????????????????????????????????????????????????
        // GROUP 5: BRANCHES (BEQ BNE BLT BGE BLTU BGEU)
        // Strategy: each branch skips a "poison" ADDI that sets a sentinel
        // value; if the branch fails to take, the sentinel appears in rd.
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 5: Branch instructions ?????????????????????????????");
        clear_imem;
        // x1=5, x2=5, x3=3, x4=-1(0xFFFFFFFF), x5=6
        load_instr(0,  ADDI(1, 0, 12'd5));
        load_instr(1,  ADDI(2, 0, 12'd5));
        load_instr(2,  ADDI(3, 0, 12'd3));
        load_instr(3,  ADDI(4, 0, 12'hFFF));  // x4 = -1
        load_instr(4,  ADDI(5, 0, 12'd6));

        // BEQ: x1==x2 ? skip poison, x10 stays 0
        // Slot 5: BEQ x1,x2, +8 (skip slot 6)
        load_instr(5,  BEQ(1, 2, 13'd8));
        // Slot 6: poison - if reached x10=0xDEAD
        load_instr(6,  ADDI(10, 0, 12'hDEA));
        // Slot 7: NOP (branch target lands here for offset +8 from slot 5)

        // BNE: x1!=x3 ? skip poison, x11 stays 0
        // Slot 7: BNE x1,x3, +8
        load_instr(7,  BNE(1, 3, 13'd8));
        // Slot 8: poison
        load_instr(8,  ADDI(11, 0, 12'hDEA));

        // BLT: x3<x1 (signed 3<5) ? skip poison, x12 stays 0
        // Slot 9: BLT x3,x1, +8
        load_instr(9,  BLT(3, 1, 13'd8));
        // Slot 10: poison
        load_instr(10, ADDI(12, 0, 12'hDEA));

        // BGE: x1>=x3 (5>=3) ? skip poison, x13 stays 0
        // Slot 11: BGE x1,x3, +8
        load_instr(11, BGE(1, 3, 13'd8));
        // Slot 12: poison
        load_instr(12, ADDI(13, 0, 12'hDEA));

        // BLTU: x3<x1 unsigned (3<5) ? skip poison, x14 stays 0
        // Slot 13: BLTU x3,x1, +8
        load_instr(13, BLTU(3, 1, 13'd8));
        // Slot 14: poison
        load_instr(14, ADDI(14, 0, 12'hDEA));

        // BGEU: x1>=x3 unsigned (5>=3) ? skip poison, x15 stays 0
        // Slot 15: BGEU x1,x3, +8
        load_instr(15, BGEU(1, 3, 13'd8));
        // Slot 16: poison
        load_instr(16, ADDI(15, 0, 12'hDEA));

        // Slot 17: NOP, Slot 18: halt
        load_instr(17, NOP_(1));
        load_instr(18, JAL(0, 21'h0));

        do_reset;

        run_cycles(22);
        check_reg(10, 32'd0,  "BEQ");
        check_reg(11, 32'd0,  "BNE");
        check_reg(12, 32'd0,  "BLT");
        check_reg(13, 32'd0,  "BGE");
        check_reg(14, 32'd0,  "BLTU");
        check_reg(15, 32'd0,  "BGEU");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 6: NOT-TAKEN BRANCHES
        // Verify branches do NOT fire when condition is false
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 6: Branch not-taken ????????????????????????????????");
        clear_imem;
        load_instr(0, ADDI(1, 0, 12'd5));
        load_instr(1, ADDI(2, 0, 12'd3));
        // BEQ x1,x2 - 5!=3 ? NOT taken, x10 gets set
        load_instr(2, BEQ(1, 2, 13'd8));
        load_instr(3, ADDI(10, 0, 12'd1));  // should execute
        load_instr(4, NOP_(1));
        // BNE x1,x1 - equal ? NOT taken, x11 gets set
        load_instr(5, BNE(1, 1, 13'd8));
        load_instr(6, ADDI(11, 0, 12'd1));  // should execute
        load_instr(7, NOP_(1));
        load_instr(8, JAL(0, 21'h0));

        do_reset;

        run_cycles(12);
        check_reg(10, 32'd1,  "BEQ-NT");
        check_reg(11, 32'd1,  "BNE-NT");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 7: LUI and AUIPC
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 7: LUI / AUIPC ?????????????????????????????????????");
        clear_imem;
        // LUI x1, 0xABCDE ? x1 = 0xABCDE000
        load_instr(0, LUI(1, 20'hABCDE));
        // AUIPC x2, 1 ? x2 = PC(=4) + 0x00001000 = 0x00001004
        load_instr(1, AUIPC(2, 20'h00001));
        load_instr(2, JAL(0, 21'h0));

        do_reset;

        run_cycles(5);
        check_reg(1, 32'hABCDE000, "LUI");
        check_reg(2, 32'h00001004, "AUIPC");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 8: JAL
        // JAL writes PC+4 to rd and jumps to target
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 8: JAL ?????????????????????????????????????????????");
        clear_imem;
        // Slot 0: JAL x1, +8 ? jump to slot 2; x1 = 0+4 = 4
        load_instr(0, JAL(1, 21'd8));
        // Slot 1: poison (should be skipped)
        load_instr(1, ADDI(10, 0, 12'hDEA));
        // Slot 2: ADDI x2, x0, 99
        load_instr(2, ADDI(2, 0, 12'd99));
        load_instr(3, JAL(0, 21'h0));

        do_reset;

        run_cycles(6);
        check_reg(1,  32'd4,      "JAL-link");
        check_reg(2,  32'd99,     "JAL-tgt");
        check_reg(10, 32'd0,      "JAL-skip");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 9: JALR
        // JALR jumps to (rs1+imm)&~1, writes PC+4 to rd
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 9: JALR ????????????????????????????????????????????");
        clear_imem;
        // x1 = byte addr of slot 3 = 12
        load_instr(0, ADDI(1, 0, 12'd12));
        // Slot 1: JALR x2, x1, 0 ? jump to addr 12 (slot 3); x2 = 8
        load_instr(1, JALR(2, 1, 12'd0));
        // Slot 2: poison
        load_instr(2, ADDI(10, 0, 12'hDEA));
        // Slot 3: target
        load_instr(3, ADDI(3, 0, 12'd55));
        load_instr(4, JAL(0, 21'h0));

        do_reset;

        run_cycles(8);
        check_reg(2,  32'd8,   "JALR-lnk");
        check_reg(3,  32'd55,  "JALR-tgt");
        check_reg(10, 32'd0,   "JALR-skp");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 10: FENCE / ECALL / EBREAK (NOP behaviour)
        // These should behave as NOPs - PC advances, no state change
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 10: FENCE / ECALL / EBREAK ????????????????????????");
        clear_imem;
        load_instr(0, ADDI(1, 0, 12'd1));
        load_instr(1, FENCE_(1));
        load_instr(2, ADDI(2, 0, 12'd2));
        load_instr(3, ECALL_(1));
        load_instr(4, ADDI(3, 0, 12'd3));
        load_instr(5, EBREAK_(1));
        load_instr(6, ADDI(4, 0, 12'd4));
        load_instr(7, JAL(0, 21'h0));

        do_reset;

        run_cycles(10);
        check_reg(1, 32'd1, "FENCE-x1");
        check_reg(2, 32'd2, "ECALL-x2");
        check_reg(3, 32'd3, "EBRK-x3");
        check_reg(4, 32'd4, "SYS-x4");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 11: STORE ? LOAD ROUND-TRIP (integration)
        // Write a value with SW then read back with LW
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 11: Store?Load round-trip ?????????????????????????");
        clear_imem; clear_dmem;
        // x1 = 0xCAFEBABE
        // 0xABE has bit11=1 so ADDI sign-extends it as -1346.
        // Compensate: LUI=0xCAFEC (loads 0xCAFEC000), ADDI adds -1346
        // 0xCAFEC000 + (-1346) = 0xCAFEBABE
        load_instr(0, LUI(1,  20'hCAFEC));   // x1 = 0xCAFEC000
        load_instr(1, ADDI(1, 1, 12'hABE));  // x1 += sign_ext(0xABE)=-1346 -> 0xCAFEBABE
        // x2 = base = 0
        load_instr(2, SW(1, 0, 12'd0));
        load_instr(3, NOP_(1));
        load_instr(4, LW(3, 0, 12'd0));
        load_instr(5, JAL(0, 21'h0));

        do_reset;

        run_cycles(8);
        check_reg(3, 32'hCAFEBABE, "SW+LW");

        // ??????????????????????????????????????????????????????????????????
        // GROUP 12: x0 HARDWIRING
        // Writing to x0 must always leave it 0
        // ??????????????????????????????????????????????????????????????????
        $display("\n?? Group 12: x0 always zero ?????????????????????????????????");
        clear_imem;
        load_instr(0, ADDI(0, 0, 12'd999));
        load_instr(1, NOP_(1));
        load_instr(2, JAL(0, 21'h0));

        do_reset;

        run_cycles(5);
        check_reg(0, 32'd0, "x0-zero");

        // ??????????????????????????????????????????????????????????????????
        // FINAL SUMMARY
        // ??????????????????????????????????????????????????????????????????
        $display("\n=============================================================");
        $display("  Results: %0d PASSED,  %0d FAILED", pass_count, fail_count);
        $display("=============================================================");
        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED - check output above");
        $display("=============================================================\n");

        $finish;
    end

    // Timeout watchdog - kills simulation if PC gets stuck
    initial begin
        #100000;
        $display("TIMEOUT - simulation exceeded 100us");
        $finish;
    end

endmodule
