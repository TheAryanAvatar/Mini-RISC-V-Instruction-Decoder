// =============================================================================
// File        : rtl/instr_type_decoder.sv
// Description : Classifies a 32-bit RISC-V instruction into one of the six
//               standard formats (R / I / S / B / U / J) by looking only at
//               the opcode field (bits [6:0]).
//               The result is an enum value from riscv_pkg that can be read
//               by name in simulation waveforms (e.g. "R_TYPE" instead of "0").
// =============================================================================

import riscv_pkg::*;

module instr_type_decoder (
    input  logic [31:0]  instr,       // full 32-bit instruction
    output instr_type_e  instr_type   // one of R_TYPE / I_TYPE / S_TYPE /
                                      //        B_TYPE / U_TYPE / J_TYPE / INVALID
);

    // Extract the opcode (bottom 7 bits)
    logic [6:0] opcode;
    assign opcode = instr[6:0];

    always_comb begin
        case (opcode)
            OPCODE_RTYPE:              instr_type = R_TYPE;
            OPCODE_ITYPE, OPCODE_LOAD: instr_type = I_TYPE; // both share I-type layout
            OPCODE_STYPE:              instr_type = S_TYPE;
            OPCODE_BTYPE:              instr_type = B_TYPE;
            OPCODE_UTYPE:              instr_type = U_TYPE;
            OPCODE_JTYPE:              instr_type = J_TYPE;
            default:                   instr_type = INVALID; // unknown / unsupported opcode
        endcase
    end

endmodule
