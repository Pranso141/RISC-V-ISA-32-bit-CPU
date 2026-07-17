# 32-bit Single-Cycle RISC-V Core: Full-Stack RTL to GDSII & FPGA Implementation

**Author:** Pranav Sapkale 

## Project Overview
This repository contains the complete architectural development and physical implementation of a 32-bit single-cycle RISC-V processor. Built upon the RV32I base integer instruction set, this project bridges the gap between digital logic design and physical silicon fabrication. 

The core has been successfully synthesized and routed for two distinct hardware targets:
1. **Application-Specific Integrated Circuit (ASIC):** Full RTL-to-GDSII flow using the open-source OpenLane EDA toolchain targeting the SkyWater 130nm (Sky130) Process Design Kit (PDK).
2. **Field-Programmable Gate Array (FPGA):** Highly optimized logic synthesis and implementation using Xilinx Vivado.

##  Key Technical Achievements

### 1. Robust ASIC Physical Design (Sky130)
* **End-to-End Open-Source Flow:** Successfully navigated the OpenLane flow—including Yosys (Synthesis), RePlace (Global Placement), OpenDP (Detailed Placement), TritonCTS (Clock Tree Synthesis), and TritonRoute (Detailed Routing).
* **Custom Hard Macro Integration:** Engineered the floorplan to integrate two distinct SRAM hard macros for the Instruction Memory (`inst_ram_block`) and Data Memory (`data_ram_block`). These macros were strategically placed to minimize routing congestion across the central standard-cell logic cloud.
* **EDA Toolchain Resiliency:** Engineered a bypass for a critical Magic DRC/LEF stream-out dependency failure. The flow was manually overridden to preserve the optimized TritonRoute database (ODB/DEF) and execute the final GDSII stream-out natively via KLayout, ensuring zero data loss.

### 2. Ultra-Efficient FPGA Implementation
The processor architecture was deeply optimized at the RTL level to reduce logic gate depth and area overhead, resulting in an exceptionally lightweight footprint:
* **Logic Utilization:** Achieved a highly dense synthesis requiring only 744 Look-Up Tables (LUTs), utilizing a mere 3.58% of available resources. 
* **Sequential Elements:** Required only 166 Flip-Flops (FFs), representing 0.40% utilization.
* **Memory Efficiency:** Mapped memory structures to 512 LUTRAMs (5.33% utilization).
* **Thermal & Power Optimization:** The implemented core operates with an ultra-low total on-chip power consumption of just 0.137 W, maintaining a stable junction temperature of 25.7 °C with a thermal margin of 59.3 °C.

### 3. Advanced Layout Visualization and Topography
To support rigorous academic documentation, the physical layout was processed to generate publication-ready die shots.
* **Native ODB Extraction:** Bypassed KLayout `.lyp` mapping discrepancies by loading the `.odb` database natively into the OpenROAD GUI.
* **PDN and Grid Stripping:** Generated high-contrast layout visuals by isolating the dense signal routing from the Power Distribution Network (VDD/GND mesh) and the standard-cell manufacturing grid. 
* **3D Extrusion:** Processed GDSII layer definitions to generate 3D STL meshes of the Sky130 metal routing stack for advanced visual topography.

##  Tools & Technologies Used
* **Hardware Description Language:** Verilog
* **ASIC Toolchain:** OpenLane, Yosys, OpenROAD, KLayout
* **Process Node:** SkyWater 130nm (Sky130 PDK)
* **FPGA Toolchain:** Xilinx Vivado

##  Documentation
For a deep dive into the physical design methodology, toolchain configurations, and synthesis reports, please wait for the published paper.
