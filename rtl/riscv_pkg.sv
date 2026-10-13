// =============================================================================
// File        : rtl/riscv_pkg.sv
// Description : Shared constants package for the Mini RISC-V Instruction Decoder.
//               Every other module imports this package so that opcode values,
//               funct3/funct7 codes and ALU codes are defined in one place only.
// =============================================================================

package riscv_pkg;

    // -----------------------------------------------------------------
    // Opcode values  (instruction bits [6:0])
    // These are the bottom 7 bits of every 32-bit RISC-V instruction.
    // They tell us the broad category / format of the instruction.
    // -----------------------------------------------------------------
    parameter logic [6:0] OPCODE_RTYPE = 7'b0110011; // R-type  : ADD, SUB, AND, OR, XOR, SLT
    parameter logic [6:0] OPCODE_ITYPE = 7'b0010011; // I-type  : ADDI, ANDI, ORI
    parameter logic [6:0] OPCODE_LOAD  = 7'b0000011; // I-type  : LW  (same format, different opcode)
    parameter logic [6:0] OPCODE_STYPE = 7'b0100011; // S-type  : SW
    parameter logic [6:0] OPCODE_BTYPE = 7'b1100011; // B-type  : BEQ, BNE
    parameter logic [6:0] OPCODE_UTYPE = 7'b0110111; // U-type  : LUI
    parameter logic [6:0] OPCODE_JTYPE = 7'b1101111; // J-type  : JAL

    // -----------------------------------------------------------------
    // funct3 values  (instruction bits [14:12])
    // These three bits further narrow down which operation is being
    // performed within a format group (e.g. ADD vs AND vs OR).
    // -----------------------------------------------------------------
    parameter logic [2:0] F3_ADD_SUB = 3'b000; // ADD, SUB (funct7 decides which), ADDI
    parameter logic [2:0] F3_SLT     = 3'b010; // SLT  (set less than)
    parameter logic [2:0] F3_XOR     = 3'b100; // XOR
    parameter logic [2:0] F3_OR      = 3'b110; // OR,  ORI
    parameter logic [2:0] F3_AND     = 3'b111; // AND, ANDI
    parameter logic [2:0] F3_LW_SW   = 3'b010; // LW, SW  (word access)
    parameter logic [2:0] F3_BEQ     = 3'b000; // BEQ (branch if equal)
    parameter logic [2:0] F3_BNE     = 3'b001; // BNE (branch if not equal)

    // -----------------------------------------------------------------
    // funct7 values  (instruction bits [31:25], meaningful in R-type only)
    // Together with funct3 they distinguish ADD from SUB.
    // -----------------------------------------------------------------
    parameter logic [6:0] F7_NORMAL = 7'b0000000; // ADD, AND, OR, XOR, SLT
    parameter logic [6:0] F7_SUB    = 7'b0100000; // SUB

    // -----------------------------------------------------------------
    // ALU control codes
    // These 4-bit codes are produced by control_unit and would be sent
    // to a future ALU to tell it exactly what arithmetic to perform.
    // -----------------------------------------------------------------
    parameter logic [3:0] ALU_ADD = 4'b0000; // Add
    parameter logic [3:0] ALU_SUB = 4'b0001; // Subtract
    parameter logic [3:0] ALU_AND = 4'b0010; // Bitwise AND
    parameter logic [3:0] ALU_OR  = 4'b0011; // Bitwise OR
    parameter logic [3:0] ALU_XOR = 4'b0100; // Bitwise XOR
    parameter logic [3:0] ALU_SLT = 4'b0101; // Set Less Than

    // -----------------------------------------------------------------
    // Instruction type enumeration
    // An enum gives human-readable names to the six RISC-V formats
    // instead of forcing us to remember which number means which format.
    // This is used by instr_type_decoder and shown in waveform viewers.
    // -----------------------------------------------------------------
    typedef enum logic [2:0] {
        R_TYPE  = 3'd0,  // Register-Register arithmetic
        I_TYPE  = 3'd1,  // Immediate arithmetic / loads
        S_TYPE  = 3'd2,  // Stores
        B_TYPE  = 3'd3,  // Conditional branches
        U_TYPE  = 3'd4,  // Upper immediate (LUI)
        J_TYPE  = 3'd5,  // Unconditional jump (JAL)
        INVALID = 3'd6   // Unknown / unsupported opcode
    } instr_type_e;

endpackage
