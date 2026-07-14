# RISC-V RV32I Single-Cycle Processor

**Author:** Pranav Sapkale  
**Institution:** Sardar Patel Institute of Technology (SPIT)  
**Project Type:** Architectural Depth Project  

## Overview
This repository contains the RTL (Register Transfer Level) implementation of a 32-bit single-cycle RISC-V processor core written in Verilog. It implements the base integer instruction set (RV32I) and is designed as a foundational architectural project, bridging the gap between digital logic theory and VLSI engineering. 

The current design executes one instruction per clock cycle, featuring a comprehensive datapath with dedicated control logic, arithmetic processing, and memory interfacing. This single-cycle core serves as the "Golden Reference Model" for a future transition into a fully functional 5-stage pipelined architecture targeted for ASIC synthesis via OpenLane/OpenROAD.

## Supported Instruction Set Architecture (RV32I)
The processor supports a robust subset of the RISC-V RV32I unprivileged ISA:

*   **R-Type (Register-Register):** `add`, `sub`, `sll`, `slt`, `sltu`, `xor`, `srl`, `sra`, `or`, `and`[cite: 8, 9]
*   **I-Type (Immediate):** `addi`, `slli`, `slti`, `sltiu`, `xori`, `srli`, `srai`, `ori`, `andi`[cite: 9]
*   **Memory Operations (Loads/Stores):** `lw`, `lh`, `lhu`, `lb`, `lbu`, `sw`, `sh`, `sb`[cite: 2]
*   **B-Type (Branches):** `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`[cite: 10]
*   **J-Type (Jumps):** `jal`, `jalr`[cite: 1, 10]
*   **U-Type (Upper Immediate):** `lui`, `auipc`[cite: 1, 3]

## Hardware Architecture & Datapath
The top-level module (`top_module.v`) connects the individual functional blocks into a unified single-cycle datapath[cite: 11]. Data and control signals propagate combinationally through the modules within a single clock period, updating architectural state (Registers and Data Memory) on the rising clock edge[cite: 2, 6, 11]. 

### RTL Schematic
Below is the generated schematic of the single-cycle datapath:

![RTL Schematic](images/Schematic.PNG)

### Module Breakdown
*   **`top_module.v`**: The structural wrapper that instantiates and wires all datapath components and control lines together[cite: 11].
*   **`CU.v` (Control Unit)**: The main decoder that takes the 7-bit instruction opcode and generates all primary multiplexer selects, memory enable flags, and execution unit signals[cite: 1].
*   **`pc.v` (Program Counter)**: A synchronous 32-bit register holding the current execution address[cite: 5].
*   **`instrct_mem.v`**: A 1024x32 instruction memory array accessed combinationally via the Program Counter[cite: 4].
*   **`reg_file.v`**: A 32x32-bit integer register file. It supports two concurrent asynchronous reads and one synchronous write on the positive clock edge. Register `x0` is hardwired to zero[cite: 6].
*   **`imm_gen.v`**: Extracts and sign-extends immediate values from the 32-bit instruction based on the opcode format (I, S, B, U, J)[cite: 3].
*   **`ALU.v`**: The Arithmetic Logic Unit executing additions, subtractions, bitwise logic, and shifts (logical and arithmetic). It outputs zero and less-than flags for branch evaluation[cite: 8].
*   **`ALUCU.v` (ALU Control)**: A secondary control decoder that takes the main `alu_op` signal alongside the instruction's `funct3` and `funct7` (bit 30) fields to dictate the precise ALU operation (e.g., distinguishing between arithmetic and logical right shifts)[cite: 9].
*   **`branch_unit.v`**: Evaluates branch conditions (`funct3`) against ALU flags (`alu_zero`, `alu_lt`, `alu_ltu`) and jump signals to assert the `pc_src` flag, redirecting the Program Counter if a branch is taken[cite: 10].
*   **`data_mem.v`**: A 1024x32 data memory array handling precise byte (`sb`/`lb`), half-word (`sh`/`lh`), and word (`sw`/`lw`) alignments and sign-extensions for memory instructions[cite: 2].
*   **`adder.v`**: Reusable 32-bit arithmetic adders used for incrementing `PC+4` and calculating branch target addresses[cite: 7].
*   **`wb_mux.v` & `small_mux.v`**: Datapath routing multiplexers for ALU operands, write-back data, and PC next-state selection[cite: 12, 13].

## Verification & Simulation
The processor's functionality has been verified using a self-checking testbench to ensure proper instruction decoding, arithmetic execution, and memory read/writes.

Below are the simulation waveforms demonstrating correct execution:

![Simulation Results](images/Simulation_Results.PNG)

## Synthesis Utilization
The design has been synthesized to analyze logic block and register resource consumption. 

Below is the utilization report for the single-cycle implementation:

![Resource Utilization](images/Utilization.PNG)

## Future Roadmap
This single-cycle implementation is phase one of a larger VLSI development cycle. Upcoming milestones include:
1.  **Pipelining:** Transformation into a 5-stage (IF, ID, EX, MEM, WB) pipelined architecture.
2.  **Hazard Mitigation:** Implementation of forwarding logic and load-use hazard detection units.
3.  **Synthesis Preparation:** Replacing inferred memory arrays with ASIC-compatible SRAM macros for physical design utilizing OpenLane/OpenROAD.
