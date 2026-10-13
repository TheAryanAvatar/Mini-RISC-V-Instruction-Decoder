// =============================================================================
// File        : tb/tb_control_unit.sv
// Description : Testbench for the control_unit module.
//               Applies all fifteen in-scope instructions and prints the eight
//               control signals for each.  Compare against Table 12.1 in the
//               project guide to verify correctness.
//
// alu column meaning: 0=ADD, 1=SUB, 2=AND, 3=OR, 4=XOR, 5=SLT
// =============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module tb_control_unit;

    logic [6:0] opcode, funct7;
    logic [2:0] funct3;
    logic reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch, jump;
    logic [3:0] alu_ctrl;

    // .* auto-connects ports to identically-named signals
    control_unit dut (.*);

    // Task: set inputs, wait, print all control signals
    task apply(input logic [6:0] op, input logic [2:0] f3,
               input logic [6:0] f7, input string name);
        opcode = op; funct3 = f3; funct7 = f7;
        #10;
        $display("%-6s rw=%0d mr=%0d mw=%0d m2r=%0d asrc=%0d br=%0d jmp=%0d alu=%0d",
                   name, reg_write, mem_read, mem_write, mem_to_reg,
                   alu_src, branch, jump, alu_ctrl);
    endtask

    initial begin
        $dumpfile("tb_control_unit.vcd");
        $dumpvars(0, tb_control_unit);

        // R-type instructions
        apply(OPCODE_RTYPE, F3_ADD_SUB, F7_NORMAL, "ADD");
        apply(OPCODE_RTYPE, F3_ADD_SUB, F7_SUB,    "SUB");
        apply(OPCODE_RTYPE, F3_AND,     F7_NORMAL, "AND");
        apply(OPCODE_RTYPE, F3_OR,      F7_NORMAL, "OR");
        apply(OPCODE_RTYPE, F3_XOR,     F7_NORMAL, "XOR");
        apply(OPCODE_RTYPE, F3_SLT,     F7_NORMAL, "SLT");

        // I-type immediate instructions
        apply(OPCODE_ITYPE, F3_ADD_SUB, 7'b0,      "ADDI");
        apply(OPCODE_ITYPE, F3_AND,     7'b0,      "ANDI");
        apply(OPCODE_ITYPE, F3_OR,      7'b0,      "ORI");

        // Load instruction
        apply(OPCODE_LOAD,  F3_LW_SW,   7'b0,      "LW");

        // Store instruction
        apply(OPCODE_STYPE, F3_LW_SW,   7'b0,      "SW");

        // Branch instructions
        apply(OPCODE_BTYPE, F3_BEQ,     7'b0,      "BEQ");
        apply(OPCODE_BTYPE, F3_BNE,     7'b0,      "BNE");

        // Upper immediate
        apply(OPCODE_UTYPE, 3'b0,       7'b0,      "LUI");

        // Jump
        apply(OPCODE_JTYPE, 3'b0,       7'b0,      "JAL");

        $finish;
    end

endmodule
