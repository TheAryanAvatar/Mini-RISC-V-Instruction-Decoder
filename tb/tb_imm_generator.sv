// =============================================================================
// File        : tb/tb_imm_generator.sv
// Description : Self-checking testbench for the imm_generator module.
//               Tests all five immediate formats (I, S, B, U, J) including
//               both positive and negative values to verify sign extension.
//               Each test prints PASS or FAIL with the actual vs expected value.
//
// Expected output: all 11 lines should say PASS
// =============================================================================

`timescale 1ns/1ps

module tb_imm_generator;

    logic [31:0] instr;
    logic [31:0] imm;

    // Instantiate the immediate generator
    imm_generator dut (
        .instr (instr),
        .imm   (imm)
    );

    // Task: apply one instruction, compare against expected, print PASS/FAIL
    task apply(input logic [31:0] i, input string name, input int expected);
        instr = i;
        #10;  // let combinational logic settle
        if (imm === expected)
            $display("PASS  %-16s imm=%0d (0x%08h)", name, $signed(imm), imm);
        else
            $display("FAIL  %-16s imm=%0d, expected=%0d", name, $signed(imm), expected);
    endtask

    initial begin
        $dumpfile("tb_imm_generator.vcd");
        $dumpvars(0, tb_imm_generator);

        // --- I-type (ADDI) ---
        apply(32'h00A30293, "ADDI +10",    10);
        apply(32'hFFB30293, "ADDI -5",     -5);

        // --- I-type (LW) ---
        apply(32'h00812083, "LW +8",        8);
        apply(32'hFFC52483, "LW -4",       -4);

        // --- S-type (SW) ---
        apply(32'h00322623, "SW +12",      12);
        apply(32'hFE84AC23, "SW -8",       -8);

        // --- U-type (LUI) ---
        apply(32'h123452B7, "LUI",  32'h12345000);

        // --- B-type (BEQ, BNE) ---
        apply(32'h00208463, "BEQ +8",       8);
        apply(32'hFE209EE3, "BNE -4",      -4);

        // --- J-type (JAL) ---
        apply(32'h064000EF, "JAL +100",   100);
        apply(32'hFCFFF06F, "JAL -50",    -50);

        $finish;
    end

endmodule
