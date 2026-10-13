// =============================================================================
// File        : tb/tb_instr_type_decoder.sv
// Description : Self-checking testbench for the instr_type_decoder module.
//               Applies one instruction of each of the six formats and checks
//               that the correct type enum value is produced.
//
// Expected output: all 6 lines should say PASS
// =============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module tb_instr_type_decoder;

    logic [31:0] instr;
    instr_type_e instr_type;

    // Instantiate the type decoder
    instr_type_decoder dut (
        .instr      (instr),
        .instr_type (instr_type)
    );

    // Task: apply one instruction, check the type, print PASS/FAIL
    task apply(input logic [31:0] i, input string name,
               input instr_type_e expected);
        instr = i;
        #10;
        if (instr_type == expected)
            $display("PASS  %-6s type=%s", name, instr_type.name());
        else
            $display("FAIL  %-6s type=%s expected=%s",
                       name, instr_type.name(), expected.name());
    endtask

    initial begin
        $dumpfile("tb_instr_type_decoder.vcd");
        $dumpvars(0, tb_instr_type_decoder);

        apply(32'h003100B3, "ADD",  R_TYPE);
        apply(32'h00A30293, "ADDI", I_TYPE);
        apply(32'h00322623, "SW",   S_TYPE);
        apply(32'h00208463, "BEQ",  B_TYPE);
        apply(32'h123452B7, "LUI",  U_TYPE);
        apply(32'h064000EF, "JAL",  J_TYPE);

        $finish;
    end

endmodule
