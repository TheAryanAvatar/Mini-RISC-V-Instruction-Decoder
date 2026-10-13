// =============================================================================
// File        : rtl/field_extractor.sv
// Description : Extracts the fixed-position fields from a 32-bit RISC-V
//               instruction.  Every field always sits at the same bit positions
//               regardless of instruction format, so this is pure bit-slicing
//               with no case statement needed.
//
// Outputs (always valid; meaning depends on the instruction format):
//   opcode  [6:0]  - bits  6:0   - identifies broad category
//   rd      [4:0]  - bits 11:7   - destination register number
//   funct3  [2:0]  - bits 14:12  - narrows down the exact operation
//   rs1     [4:0]  - bits 19:15  - first source register number
//   rs2     [4:0]  - bits 24:20  - second source register number
//   funct7  [6:0]  - bits 31:25  - only meaningful in R-type instructions
// =============================================================================

module field_extractor (
    input  logic [31:0] instr,    // 32-bit instruction from memory

    output logic [6:0]  opcode,   // instruction bits [6:0]
    output logic [4:0]  rd,       // instruction bits [11:7]
    output logic [2:0]  funct3,   // instruction bits [14:12]
    output logic [4:0]  rs1,      // instruction bits [19:15]
    output logic [4:0]  rs2,      // instruction bits [24:20]
    output logic [6:0]  funct7    // instruction bits [31:25]
);

    // Each assign is a direct wire connection - no logic, just naming
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

endmodule
