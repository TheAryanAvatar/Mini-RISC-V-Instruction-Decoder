// =============================================================================
// File        : rtl/riscv_instr_decoder.sv
// Description : Top-level integration module for the Mini RISC-V Instruction
//               Decoder.  This module instantiates the four sub-modules built
//               separately (field_extractor, imm_generator, instr_type_decoder,
//               control_unit) and wires them together.
//
//               This module itself contains NO logic of its own - it is purely
//               structural: it just connects wires between the sub-modules.
//
// Data flow:
//   instr (32-bit) --> field_extractor  --> opcode, rd, funct3, rs1, rs2, funct7
//   instr (32-bit) --> imm_generator    --> imm  (32-bit sign-extended immediate)
//   instr (32-bit) --> instr_type_decoder --> instr_type  (enum: R/I/S/B/U/J)
//   opcode + funct3 + funct7 --> control_unit --> 8 control signals
// =============================================================================

import riscv_pkg::*;

module riscv_instr_decoder (
    // Single input: the 32-bit machine instruction
    input  logic [31:0]  instr,

    // Outputs from field_extractor
    output logic [6:0]   opcode,
    output logic [4:0]   rd,
    output logic [2:0]   funct3,
    output logic [4:0]   rs1,
    output logic [4:0]   rs2,
    output logic [6:0]   funct7,

    // Output from imm_generator
    output logic [31:0]  imm,

    // Output from instr_type_decoder
    output instr_type_e  instr_type,

    // Outputs from control_unit
    output logic         reg_write,
    output logic         mem_read,
    output logic         mem_write,
    output logic         mem_to_reg,
    output logic         alu_src,
    output logic         branch,
    output logic         jump,
    output logic [3:0]   alu_ctrl
);

    // ------------------------------------------------------------------
    // Instance 1: field_extractor
    // Slices out the six named fields from fixed bit positions.
    // Note: opcode, funct3, funct7 are outputs of this instance AND
    //       inputs of the control_unit instance below - both see the
    //       same wire, which is how structural SystemVerilog works.
    // ------------------------------------------------------------------
    field_extractor u_field_extractor (
        .instr  (instr),
        .opcode (opcode),
        .rd     (rd),
        .funct3 (funct3),
        .rs1    (rs1),
        .rs2    (rs2),
        .funct7 (funct7)
    );

    // ------------------------------------------------------------------
    // Instance 2: imm_generator
    // Reconstructs the 32-bit signed immediate from the scrambled bits.
    // ------------------------------------------------------------------
    imm_generator u_imm_generator (
        .instr (instr),
        .imm   (imm)
    );

    // ------------------------------------------------------------------
    // Instance 3: instr_type_decoder
    // Classifies the instruction into one of the six RISC-V formats.
    // ------------------------------------------------------------------
    instr_type_decoder u_instr_type_decoder (
        .instr      (instr),
        .instr_type (instr_type)
    );

    // ------------------------------------------------------------------
    // Instance 4: control_unit
    // Generates the eight control signals.  It uses opcode, funct3 and
    // funct7 which were just produced by u_field_extractor above.
    // ------------------------------------------------------------------
    control_unit u_control_unit (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .reg_write  (reg_write),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .alu_src    (alu_src),
        .branch     (branch),
        .jump       (jump),
        .alu_ctrl   (alu_ctrl)
    );

endmodule
