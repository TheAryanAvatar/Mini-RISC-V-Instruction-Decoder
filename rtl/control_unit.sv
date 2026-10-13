// =============================================================================
// File        : rtl/control_unit.sv
// Description : Generates the control signals that tell the rest of a processor
//               what to do for the current instruction.  Inputs are the opcode,
//               funct3, and funct7 fields; outputs are eight signals that would
//               drive an ALU, a register file, a data memory, and branch/jump
//               logic in a complete single-cycle RISC-V datapath.
//
// Output signals:
//   reg_write  - 1 = write result back to register rd
//   mem_read   - 1 = read a word from data memory (LW)
//   mem_write  - 1 = write a word to data memory  (SW)
//   mem_to_reg - 1 = the value written to rd comes from memory, not the ALU
//   alu_src    - 1 = ALU second operand is the immediate (not rs2)
//   branch     - 1 = this is a conditional branch (BEQ / BNE)
//   jump       - 1 = this is an unconditional jump  (JAL)
//   alu_ctrl   - 4-bit code for the ALU operation (see riscv_pkg ALU_* constants)
// =============================================================================

import riscv_pkg::*;

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       alu_src,
    output logic       branch,
    output logic       jump,
    output logic [3:0] alu_ctrl
);

    always_comb begin
        // ------------------------------------------------------------------
        // Safe defaults: set every output to 0 / no-operation first.
        // The case statement below only changes the signals that actually
        // differ from zero for each opcode.  This pattern guarantees that
        // every output is always driven, which prevents SystemVerilog from
        // accidentally inferring a latch.
        // ------------------------------------------------------------------
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_ctrl   = ALU_ADD;   // a safe default

        case (opcode)

            // ------------------------------------------------------------------
            // R-type: ADD, SUB, AND, OR, XOR, SLT
            // Both operands come from registers; result goes to rd.
            // funct7 + funct3 together select the exact operation.
            // ------------------------------------------------------------------
            OPCODE_RTYPE: begin
                reg_write = 1'b1;    // result goes to register rd
                alu_src   = 1'b0;    // second operand is rs2 (a register)

                // Inner case on the concatenation of funct7 and funct3
                case ({funct7, funct3})
                    {F7_NORMAL, F3_ADD_SUB}: alu_ctrl = ALU_ADD;
                    {F7_SUB,    F3_ADD_SUB}: alu_ctrl = ALU_SUB;
                    {F7_NORMAL, F3_AND}:     alu_ctrl = ALU_AND;
                    {F7_NORMAL, F3_OR}:      alu_ctrl = ALU_OR;
                    {F7_NORMAL, F3_XOR}:     alu_ctrl = ALU_XOR;
                    {F7_NORMAL, F3_SLT}:     alu_ctrl = ALU_SLT;
                    default:                 alu_ctrl = ALU_ADD; // safe fallback
                endcase
            end

            // ------------------------------------------------------------------
            // I-type: ADDI, ANDI, ORI
            // One operand is a register; the other is the immediate.
            // funct3 selects the operation (no funct7 for immediate ops).
            // ------------------------------------------------------------------
            OPCODE_ITYPE: begin
                reg_write = 1'b1;    // result goes to register rd
                alu_src   = 1'b1;    // second operand is the immediate

                case (funct3)
                    F3_ADD_SUB: alu_ctrl = ALU_ADD; // ADDI
                    F3_AND:     alu_ctrl = ALU_AND; // ANDI
                    F3_OR:      alu_ctrl = ALU_OR;  // ORI
                    default:    alu_ctrl = ALU_ADD;
                endcase
            end

            // ------------------------------------------------------------------
            // LOAD: LW
            // Address = rs1 + immediate (ALU does the addition).
            // Result written to rd comes from memory, not the ALU.
            // ------------------------------------------------------------------
            OPCODE_LOAD: begin
                reg_write  = 1'b1;   // loaded value goes to register rd
                mem_read   = 1'b1;   // read from data memory
                mem_to_reg = 1'b1;   // value for rd comes from memory
                alu_src    = 1'b1;   // ALU computes rs1 + immediate (address)
                alu_ctrl   = ALU_ADD;
            end

            // ------------------------------------------------------------------
            // S-type: SW
            // Address = rs1 + immediate; value written is rs2.
            // No register is written back (reg_write stays 0).
            // ------------------------------------------------------------------
            OPCODE_STYPE: begin
                mem_write = 1'b1;    // write to data memory
                alu_src   = 1'b1;    // ALU computes rs1 + immediate (address)
                alu_ctrl  = ALU_ADD;
            end

            // ------------------------------------------------------------------
            // B-type: BEQ, BNE
            // The ALU subtracts rs2 from rs1 to check equality.
            // branch=1 tells downstream logic to check the zero flag.
            // NOTE: BEQ and BNE produce identical signals here; the distinction
            //       is made by funct3 in a branch-decision circuit (future work).
            // ------------------------------------------------------------------
            OPCODE_BTYPE: begin
                branch   = 1'b1;    // signal: this is a conditional branch
                alu_src  = 1'b0;    // compare rs1 - rs2 (both registers)
                alu_ctrl = ALU_SUB;
            end

            // ------------------------------------------------------------------
            // U-type: LUI
            // The immediate IS the result (upper 20 bits with lower 12 zero).
            // ALU passes it through by computing 0 + imm, or hardware just routes
            // the immediate to rd.  We model it as ALU_ADD with alu_src=1.
            // ------------------------------------------------------------------
            OPCODE_UTYPE: begin
                reg_write = 1'b1;   // result goes to register rd
                alu_src   = 1'b1;   // second operand is the immediate
                alu_ctrl  = ALU_ADD;
            end

            // ------------------------------------------------------------------
            // J-type: JAL
            // Unconditional jump; rd = return address (PC + 4).
            // The ALU is not meaningfully used for JAL (destination = PC + imm),
            // so alu_ctrl is left at the default ALU_ADD.
            // ------------------------------------------------------------------
            OPCODE_JTYPE: begin
                reg_write = 1'b1;   // return address goes to register rd
                jump      = 1'b1;   // signal: unconditional jump
            end

            // ------------------------------------------------------------------
            // Default: unrecognised opcode
            // All signals remain at their safe zero defaults set above.
            // This prevents any accidental action for an unknown instruction.
            // ------------------------------------------------------------------
            default: begin
                // nothing to override; defaults are already zero / safe
            end

        endcase
    end

endmodule
