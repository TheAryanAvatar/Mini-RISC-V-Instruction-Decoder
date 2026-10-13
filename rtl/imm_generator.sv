// =============================================================================
// File        : rtl/imm_generator.sv
// Description : Reconstructs the correct signed 32-bit immediate value from a
//               32-bit RISC-V instruction.  Different instruction formats store
//               the immediate bits in different positions (and sometimes in a
//               scrambled order), so this module looks at the opcode and applies
//               the appropriate re-assembly and sign-extension formula.
//
// Supported formats and their immediate encodings:
//   I-type  : instr[31:20]           -> sign-extended to 32 bits
//   S-type  : {instr[31:25],instr[11:7]} -> sign-extended to 32 bits
//   B-type  : {instr[31],instr[7],instr[30:25],instr[11:8],1'b0} -> sign-ext
//   U-type  : {instr[31:12], 12'b0}  -> no sign extension needed
//   J-type  : {instr[31],instr[19:12],instr[20],instr[30:21],1'b0} -> sign-ext
//   R-type  : no immediate; outputs 0
// =============================================================================

import riscv_pkg::*;

module imm_generator (
    input  logic [31:0] instr,   // full 32-bit instruction
    output logic [31:0] imm      // reconstructed 32-bit signed immediate
);

    // Pull out the opcode locally to drive the case statement
    logic [6:0] opcode;
    assign opcode = instr[6:0];

    always_comb begin
        case (opcode)

            // ------------------------------------------------------------------
            // I-type  (ADDI, ANDI, ORI) and LOAD (LW) share the same layout.
            // The immediate is the top 12 bits of the instruction, contiguous.
            // Sign-extend: copy bit 31 twenty times, then attach bits [31:20].
            // ------------------------------------------------------------------
            OPCODE_ITYPE, OPCODE_LOAD: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            // ------------------------------------------------------------------
            // S-type  (SW)
            // The immediate is split: upper 7 bits at [31:25], lower 5 at [11:7].
            // Reassemble them into a 12-bit value then sign-extend.
            // ------------------------------------------------------------------
            OPCODE_STYPE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // ------------------------------------------------------------------
            // B-type  (BEQ, BNE)
            // Bits are stored in a scrambled order to keep rs1/rs2/funct3/opcode
            // at their usual positions.  Reconstruct imm[12:1] from the bits
            // scattered across the instruction, then append an implicit 0 at bit 0
            // (branch targets are always 2-byte aligned, so bit 0 is never stored).
            //
            // Bit mapping:  imm[12]=instr[31], imm[11]=instr[7],
            //               imm[10:5]=instr[30:25], imm[4:1]=instr[11:8]
            // Total: 19 (sign) + 1 + 1 + 6 + 4 + 1 = 32 bits
            // ------------------------------------------------------------------
            OPCODE_BTYPE: begin
                imm = {{19{instr[31]}}, instr[31], instr[7],
                        instr[30:25], instr[11:8], 1'b0};
            end

            // ------------------------------------------------------------------
            // U-type  (LUI)
            // The top 20 bits of the instruction ARE the upper 20 bits of the
            // immediate.  The lower 12 bits are simply set to zero.
            // No sign extension is needed here.
            // ------------------------------------------------------------------
            OPCODE_UTYPE: begin
                imm = {instr[31:12], 12'b0};
            end

            // ------------------------------------------------------------------
            // J-type  (JAL)
            // Similar scrambling as B-type, but over a wider range for longer jumps.
            // Bit mapping:  imm[20]=instr[31], imm[19:12]=instr[19:12],
            //               imm[11]=instr[20], imm[10:1]=instr[30:21]
            // Total: 11 (sign) + 1 + 8 + 1 + 10 + 1 = 32 bits
            // ------------------------------------------------------------------
            OPCODE_JTYPE: begin
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                        instr[20], instr[30:21], 1'b0};
            end

            // ------------------------------------------------------------------
            // R-type  (ADD, SUB, AND, OR, XOR, SLT) and anything else
            // R-type instructions have no immediate field; output zero.
            // ------------------------------------------------------------------
            default: begin
                imm = 32'd0;
            end

        endcase
    end

endmodule
