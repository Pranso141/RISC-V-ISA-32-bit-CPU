# RISC-V RV32I Single-Cycle Processor — SRAM-Based Physical Implementation

**Author:** Pranav Sapkale

## Index
1. [Overview](#overview)
2. [Supported Instruction Set Architecture (RV32I)](#supported-instruction-set-architecture-rv32i)
3. [Hardware Architecture & Datapath](#hardware-architecture--datapath)
   - [RTL Schematic](#rtl-schematic)
   - [Module Breakdown](#module-breakdown)
4. [Memory Subsystem — SRAM Macro Integration](#memory-subsystem--sram-macro-integration)
5. [Physical Design Flow (RTL → GDSII)](#physical-design-flow-rtl--gdsii)
   - [Toolchain & Environment](#toolchain--environment)
   - [Flow Stages](#flow-stages)
   - [Key Configuration Choices (config.json)](#key-configuration-choices-configjson)
6. [Results](#results-extracted-directly-from-the-physical-design-run)
7. [GDSII — Final Silicon Layout](#gdsii--final-silicon-layout)
   - [Die-Level View](#die-level-view)
   - [SRAM Macro Placement (Silicon Level)](#sram-macro-placement-silicon-level)
   - [GDS Export Notes](#gds-export-notes)
8. [Visualization](#visualization)
9. [Verification & Simulation](#verification--simulation)
10. [Synthesis Utilization](#synthesis-utilization)
11. [Future Roadmap](#future-roadmap)

## Overview
This repository contains the complete RTL-to-GDSII implementation of a 32-bit single-cycle RISC-V processor core, built on the base integer instruction set (RV32I) and carried all the way from Verilog RTL through an open-source physical design flow to a routed, DRC-clean silicon layout on the SkyWater Sky130 130nm process.

This is a significant evolution beyond a purely academic RTL exercise: the processor's instruction and data memories are no longer behaviorally inferred flip-flop arrays. They are implemented as dedicated hard-macro SRAM blocks generated with OpenRAM, integrated directly into the floorplan and power delivery network like they would be in a real ASIC tapeout. The result is a design that reflects, in area, power, and routing behavior, what this core would actually look like in silicon — not just what it looks like in simulation.

The project's goal is twofold: first, to serve as a "Golden Reference Model" — a functionally correct, physically implementable single-cycle baseline — ahead of a planned transition to a 5-stage pipelined architecture; and second, to serve as a fully documented, reproducible case study in taking a processor core through an entirely open-source EDA toolchain, with no commercial license required at any stage.

## Supported Instruction Set Architecture (RV32I)
The processor supports a robust subset of the RISC-V RV32I unprivileged ISA:

*   **R-Type (Register-Register):** `add`, `sub`, `sll`, `slt`, `sltu`, `xor`, `srl`, `sra`, `or`, `and`
*   **I-Type (Immediate):** `addi`, `slli`, `slti`, `sltiu`, `xori`, `srli`, `srai`, `ori`, `andi`
*   **Memory Operations (Loads/Stores):** `lw`, `lh`, `lhu`, `lb`, `lbu`, `sw`, `sh`, `sb`
*   **B-Type (Branches):** `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`
*   **J-Type (Jumps):** `jal`, `jalr`
*   **U-Type (Upper Immediate):** `lui`, `auipc`

## Hardware Architecture & Datapath
The top-level module (`top_module.v`) connects the individual functional blocks into a unified single-cycle datapath. Data and control signals propagate combinationally through the modules within a single clock period, updating architectural state (Registers, PC, and now SRAM-backed memory) on the rising clock edge.

### RTL Schematic
Below is the generated schematic of the single-cycle datapath:

![RTL Schematic](Images/Schematic.PNG)

### Module Breakdown
*   **`top_module.v`**: The structural wrapper that instantiates and wires all datapath components, control lines, and the two SRAM macros together.
*   **`CU.v` (Control Unit)**: The main decoder that takes the 7-bit instruction opcode and generates all primary multiplexer selects, memory enable flags, and execution unit signals.
*   **`pc.v` (Program Counter)**: A synchronous 32-bit register holding the current execution address.
*   **`instrct_mem.v`**: Interface logic to the instruction SRAM macro (see "Memory Subsystem" below) — replaces the earlier 1024x32 behaviorally inferred instruction memory.
*   **`reg_file.v`**: A 32x32-bit integer register file. It supports two concurrent asynchronous reads and one synchronous write on the positive clock edge. Register `x0` is hardwired to zero.
*   **`imm_gen.v`**: Extracts and sign-extends immediate values from the 32-bit instruction based on the opcode format (I, S, B, U, J).
*   **`ALU.v`**: The Arithmetic Logic Unit executing additions, subtractions, bitwise logic, and shifts (logical and arithmetic). It outputs zero and less-than flags for branch evaluation.
*   **`ALUCU.v` (ALU Control)**: A secondary control decoder that takes the main `alu_op` signal alongside the instruction's `funct3` and `funct7` (bit 30) fields to dictate the precise ALU operation (e.g., distinguishing between arithmetic and logical right shifts).
*   **`branch_unit.v`**: Evaluates branch conditions (`funct3`) against ALU flags (`alu_zero`, `alu_lt`, `alu_ltu`) and jump signals to assert the `pc_src` flag, redirecting the Program Counter if a branch is taken.
*   **`data_mem.v`**: Interface logic to the data SRAM macro, handling precise byte (`sb`/`lb`), half-word (`sh`/`lh`), and word (`sw`/`lw`) alignments and sign-extensions for memory instructions.
*   **`adder.v`**: Reusable 32-bit arithmetic adders used for incrementing `PC+4` and calculating branch target addresses.
*   **`wb_mux.v` & `small_mux.v`**: Datapath routing multiplexers for ALU operands, write-back data, and PC next-state selection.
*   **`sky130_sram_1kbyte_1rw1r_32x256_8.v`**: The OpenRAM-generated hard-macro SRAM model used for both instruction and data memory (see below).

## Memory Subsystem — SRAM Macro Integration
The single largest architectural change from the original all-flip-flop implementation is the memory subsystem:

*   Instruction and data memory are each implemented as a **1 KB (1024 x 32-bit) SRAM macro**, generated with **OpenRAM**, rather than as synthesized register arrays.
*   Using two 1 KB macros instead of 1024 discrete registers keeps the instruction/data address space bounded to a 1024-word limit while producing a far more area- and power-efficient result than an equivalent flip-flop-based memory would.
*   Each macro is instantiated as a hard macro (`sky130_sram_1kbyte_1rw1r_32x256_8`) with its own `.gds`, `.lef`, and `.lib` views, so the physical design flow treats it as a fixed, pre-characterized block rather than something to synthesize.
*   Macros are placed at the edges of the floorplan (via an explicit `MACRO_PLACEMENT_CFG` coordinate file) to keep them out of the way of the dense central standard-cell routing for the 32-bit register file/ALU interconnect.
*   Each macro's power pins are explicitly stitched into the chip-level power delivery network (`PDN_MACRO_CONNECTIONS`) so both memories receive the same VDD/GND mesh as the surrounding standard cells.

## Physical Design Flow (RTL → GDSII)
This project doesn't stop at RTL — it carries the design through a complete, open-source physical implementation flow using **LibreLane/OpenLane**, **Yosys**, **OpenROAD**, and the **SkyWater Sky130** open PDK.

### Toolchain & Environment
*   Package/environment management handled entirely with **Nix**.
*   Deliberately run on **Ultramarine Linux** (Red Hat/Fedora-derived) instead of the officially recommended Ubuntu-based distribution, to test flow portability.
*   `RUN_MAGIC` was disabled to bypass a Magic GDS stream-out dependency failure specific to this environment; **KLayout** was used for GDSII stream-out instead, with no loss of routing/layout completeness.

### Flow Stages
1.  **Logic Synthesis** — Yosys/ABC technology-maps the RTL to Sky130 standard cells under an `AREA 0` optimization strategy.
2.  **Floorplanning & PDN Generation** — fixed 1500x1500 µm die / 1480x1480 µm core, with the two SRAM macros placed at the floorplan edges and a VDD/GND metal mesh built across the upper metal layers.
3.  **Global & Detailed Placement** — RePlace performs wirelength-driven global placement at a 40% target density; OpenDP legalizes cell positions to the manufacturing grid.
4.  **Clock Tree Synthesis** — TritonCTS builds a balanced H-tree from `clk` to all sequential sinks using `sky130_fd_sc_hd` clock buffers.
5.  **Global & Detailed Routing** — FastRoute plans congestion-aware routing guides across `met1`–`met5`; TritonRoute performs DRC-clean detailed wiring and via insertion.
6.  **Signoff** — Static timing analysis across 9 PVT corners, plus IR-drop analysis on the VPWR/VGND power nets.
7.  **GDSII Stream-Out** — via KLayout, using the Sky130A `.lyp` layer property file for visualization.

### Key Configuration Choices (`config.json`)
| Parameter | Value | Why |
|---|---|---|
| `CLOCK_PERIOD` | 50.0 ns | Conservative period to accommodate the long single-cycle critical path without forcing synthesis to over-optimize for area. |
| `FP_CORE_UTIL` / `PL_TARGET_DENSITY_PCT` | 40% / 40% | Heavy 32-bit bus routing needs headroom; low density avoids detailed-routing DRC congestion. |
| `SYNTH_STRATEGY` | `AREA 0` | Prioritizes area; can be swapped to a delay-oriented strategy if setup timing fails. |
| `DIE_AREA` / `CORE_AREA` | 1500x1500 / 1480x1480 µm (absolute) | Fixed sizing chosen to fit both SRAM macros plus logic with margin. |
| `MACRO_PLACEMENT_CFG` | `macro.cfg` | Explicit edge placement for the two SRAM macros to protect central routing. |
| `RUN_MAGIC` | `false` | Bypasses a Nix/Ultramarine-specific Magic stream-out failure; KLayout used instead. |

## Results (extracted directly from the physical design run)
*   **Cell inventory (post-CTS):** 33,257 total cells / 503,770 µm², including 2 SRAM macros (381,425 µm²), 1,055 sequential cells, 3,979 multi-input combinational cells, and 210 clock buffers.
*   **Clock tree:** 143 clock buffers across 143 subnets reaching 1,057 sequential sinks; max clock-tree depth of 4 levels.
*   **Timing:** hold timing met with positive slack across all 9 PVT corners tested; setup timing met at nominal and fast-process corners, with violations only at the worst-case slow-process corner (`-1.2449 ns` WNS / `-4.8272 ns` TNS across 9 paths) — an expected consequence of the single-cycle critical path.
*   **Routing:** average congestion of 6.49% across all metal layers with **zero overflow** anywhere; ~739,000 µm total wirelength across 8,145 nets and 69,099 vias.
*   **Power / IR drop:** 1.96 mW total core power at nominal conditions; worst-case IR drop of just 0.02% of supply voltage on both VPWR and VGND — well inside typical signoff margins.

## GDSII — Final Silicon Layout
The flow terminates in a full GDSII stream-out of the routed design — the actual polygon-level geometry that would be handed to a foundry for fabrication. This is the artifact that separates this project from a purely RTL/FPGA exercise: every cell, macro, and wire below has real, DRC-checked physical geometry on the Sky130 process.

### Die-Level View
![Full-Chip GDSII Layout](Images/GDSII_Full_Die.PNG)

*   **File:** `top_module.gds`, viewed in **KLayout 0.30.7**.
*   **Die area:** 1500 x 1500 µm (absolute), **core area:** 1480 x 1480 µm, per the `DIE_AREA`/`CORE_AREA` settings in `config.json`.
*   The dense, uniformly hatched region filling the core is the standard-cell placement — tap cells, fill cells, combinational logic, sequential cells, and clock buffers — rendered here on the boundary/outline layer (`235/4` in the Sky130 GDS layer map, shown selected in the Layers panel).
*   Faint vertical/horizontal striping visible through the core is the upper-metal (met4/met5) power distribution mesh, running across the die to feed both standard cells and the two SRAM macros.
*   The **Cells** panel (left) lists every standard-cell master used in the design pulled in from the Sky130 `sky130_fd_sc_hd` library — logic gates (`a211oi`, `a21oi`, `a2bb2o`, `and2`, `and3`, `and4`...), buffers/inverters (`buf_1`, `buf_4`, `inv_2`...), clock cells (`clkbuf_2/4/16`, `clkdlybuf4s25_1`), fill/decap/tap cells, and DFF/latch cells (`dfxtp_2`, `dlygate4sd3_1`) — confirming the design is composed entirely of pre-characterized, foundry-qualified cells rather than abstract logic.
*   No DRC violation markers are present in this view; the geometry shown is what streamed out cleanly after detailed routing.

### SRAM Macro Placement (Silicon Level)
![SRAM Macro Placement in Final Layout](Images/GDSII_SRAM_Macros.PNG)

*   Close-up of the die's lower edge showing the two integrated SRAM hard macros: **`insmem.inst_ram_block`** (instruction memory, right) and **`datamem.data_ram_block`** (data memory, left), each a `sky130_sram_1kbyte_1rw1r_32x256_8` macro dropped in directly from its OpenRAM-generated `.gds`.
*   The pink/pill-colored regions are the macro boundary outlines pulled from each macro's `.lef` abstract; the dense red/magenta vertical routing between the two macros is the shared address/control/power interconnect stitched across both blocks.
*   Green and yellow traces below and around the macros are the standard-cell-layer routing (met1–met3) connecting the memories to the rest of the datapath — visibly denser directly beneath the macros, where the 32-bit address and data buses fan out.
*   This placement — both macros pinned along one edge of the die rather than scattered through the core — is a direct result of the `MACRO_PLACEMENT_CFG` coordinates and is what kept central-core routing congestion low (see Results: 6.49% average congestion, zero overflow).
*   Both macros' `vccd1`/`vssd1` power pins are visible tying directly into the surrounding power mesh, per the `PDN_MACRO_CONNECTIONS` configuration.

### GDS Export Notes
*   GDSII stream-out was performed via **KLayout**, not Magic — `RUN_MAGIC` was set to `false` to route around an environment-specific Magic dependency failure (see *Physical Design Flow* above). KLayout merged the routed OpenROAD database with each macro's pre-supplied `.gds` (`sky130_sram_1kbyte_1rw1r_32x256_8.gds`) to produce the final full-chip stream-out.
*   `MAGIC_DRC_USE_GDS` and `MAGIC_EXT_USE_GDS` were left enabled in `config.json` so that, if Magic-based DRC/LVS is run later, it will check against this same GDS geometry rather than re-deriving it from LEF.
*   `MAGIC_WRITE_FULL_LEF` was disabled since no further hierarchical abstraction of `top_module` was needed for this run.
*   Final GDS output includes all fill, tap, and decap cells inserted during placement/CTS, so the streamed-out die is fill-complete and ready for the DRC/LVS signoff step noted in the Future Roadmap.

## Visualization
*   **KLayout** — used with the Sky130A `.lyp` property file, with base substrate layers (N-well, P-well, diffusion) disabled to isolate standard-cell and SRAM macro placement for clean figures.
*   **OpenROAD GUI** — used to load the routed `.odb` database and strip away power-grid and manufacturing-grid layers for high-contrast routing-density visualizations.
*   **Blender + GDS3D** — used for 3D silicon-level renders of the final layout.

## Verification & Simulation
The processor's functionality has been verified using a self-checking testbench to ensure proper instruction decoding, arithmetic execution, and memory read/writes against the SRAM-backed instruction and data memories.

Below are the simulation waveforms demonstrating correct execution:

![Simulation Results](Images/Simulation_Results.PNG)

## Synthesis Utilization
The design has been synthesized to analyze logic block, register, and SRAM macro resource consumption.

Below is the utilization report for the SRAM-based implementation:

![Resource Utilization](Images/Utilization.PNG)

## Future Roadmap
This single-cycle, SRAM-backed implementation is phase two of a larger VLSI development cycle (phase one being the original flip-flop-only version). Upcoming milestones include:
1.  **Pipelining:** Transformation into a 5-stage (IF, ID, EX, MEM, WB) pipelined architecture to close the setup-timing gap observed at worst-case slow-process corners and substantially raise maximum operating frequency.
2.  **Hazard Mitigation:** Implementation of forwarding logic and load-use hazard detection units for the pipelined core.
3.  **Low-Power Exploration:** Investigating reduced-voltage and clock-gated variants of the same OpenLane/Sky130 flow.
4.  **Full Signoff:** Extending the current placement/CTS/routing results with parasitic-extracted (RCX) final timing signoff and a complete DRC/LVS clean report.
