// =============================================================================
// File        : tb/tb_selfcheck.sv
// Description : Fully self-checking testbench for the complete decoder.
//               Applies 16 instructions (all 15 from the in-scope list plus
//               one extra ADDI with a negative immediate), checks 10 outputs
//               per instruction automatically, and prints a final PASS/FAIL
//               summary.
//
//               Expected final line: ALL 16 TESTS PASSED
// =============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module tb_selfcheck;

    logic [31:0]  instr;
    logic [6:0]   opcode, funct7;
    logic [4:0]   rd, rs1, rs2;
    logic [2:0]   funct3;
    logic [31:0]  imm;
    instr_type_e  instr_type;
    logic reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch, jump;
    logic [3:0] alu_ctrl;

    // Running totals for the final summary
    int pass_count = 0;
    int fail_count = 0;

    // Connect decoder
    riscv_instr_decoder dut (.instr(instr), .opcode(opcode), .rd(rd),
                             .funct3(funct3), .rs1(rs1), .rs2(rs2),
                             .funct7(funct7), .imm(imm),
                             .instr_type(instr_type),
                             .reg_write(reg_write), .mem_read(mem_read),
                             .mem_write(mem_write), .mem_to_reg(mem_to_reg),
                             .alu_src(alu_src), .branch(branch),
                             .jump(jump), .alu_ctrl(alu_ctrl));

    // ------------------------------------------------------------------
    // check task: applies one instruction and compares 10 output signals
    // against the expected values passed as arguments.
    // === (case equality) is used so an unknown (x) value is a mismatch.
    // ------------------------------------------------------------------
    task check(
        input logic [31:0]       i,
        input string             name,
        input instr_type_e       exp_type,
        input logic signed [31:0] exp_imm,
        input logic              exp_rw,
        input logic              exp_mr,
        input logic              exp_mw,
        input logic              exp_m2r,
        input logic              exp_asrc,
        input logic              exp_br,
        input logic              exp_jmp,
        input logic [3:0]        exp_alu
    );
        logic ok;
        instr = i;
        #10;  // wait for combinational logic to settle

        ok = (instr_type === exp_type)   &&
             (imm       === exp_imm)     &&
             (reg_write === exp_rw)      &&
             (mem_read  === exp_mr)      &&
             (mem_write === exp_mw)      &&
             (mem_to_reg === exp_m2r)    &&
             (alu_src   === exp_asrc)    &&
             (branch    === exp_br)      &&
             (jump      === exp_jmp)     &&
             (alu_ctrl  === exp_alu);

        if (ok) begin
            pass_count++;
            $display("PASS  %-6s type=%-7s imm=%0d",
                       name, instr_type.name(), $signed(imm));
        end else begin
            fail_count++;
            $display("FAIL  %-6s type=%-7s imm=%0d",
                       name, instr_type.name(), $signed(imm));
            $display("      rw=%0d mr=%0d mw=%0d m2r=%0d asrc=%0d br=%0d jmp=%0d alu=%0d",
                       reg_write, mem_read, mem_write, mem_to_reg,
                       alu_src, branch, jump, alu_ctrl);
        end
    endtask

    initial begin
        $dumpfile("tb_selfcheck.vcd");
        $dumpvars(0, tb_selfcheck);

        // instr         name    type     imm   rw mr mw m2r asrc br jmp alu
        check(32'h003100B3, "ADD",   R_TYPE,    0, 1, 0, 0, 0, 0, 0, 0, ALU_ADD);
        check(32'h40628233, "SUB",   R_TYPE,    0, 1, 0, 0, 0, 0, 0, 0, ALU_SUB);
        check(32'h009473B3, "AND",   R_TYPE,    0, 1, 0, 0, 0, 0, 0, 0, ALU_AND);
        check(32'h00C5E533, "OR",    R_TYPE,    0, 1, 0, 0, 0, 0, 0, 0, ALU_OR);
        check(32'h00F746B3, "XOR",   R_TYPE,    0, 1, 0, 0, 0, 0, 0, 0, ALU_XOR);
        check(32'h0128A833, "SLT",   R_TYPE,    0, 1, 0, 0, 0, 0, 0, 0, ALU_SLT);
        check(32'h00A30293, "ADDI",  I_TYPE,   10, 1, 0, 0, 0, 1, 0, 0, ALU_ADD);
        check(32'hFFB30293, "ADDI2", I_TYPE,   -5, 1, 0, 0, 0, 1, 0, 0, ALU_ADD);
        check(32'h00F1F113, "ANDI",  I_TYPE,   15, 1, 0, 0, 0, 1, 0, 0, ALU_AND);
        check(32'h0081E113, "ORI",   I_TYPE,    8, 1, 0, 0, 0, 1, 0, 0, ALU_OR);
        check(32'h00812083, "LW",    I_TYPE,    8, 1, 1, 0, 1, 1, 0, 0, ALU_ADD);
        check(32'h00322623, "SW",    S_TYPE,   12, 0, 0, 1, 0, 1, 0, 0, ALU_ADD);
        check(32'h00208463, "BEQ",   B_TYPE,    8, 0, 0, 0, 0, 0, 1, 0, ALU_SUB);
        check(32'hFE209EE3, "BNE",   B_TYPE,   -4, 0, 0, 0, 0, 0, 1, 0, ALU_SUB);
        check(32'h123452B7, "LUI",   U_TYPE, 32'h12345000, 1, 0, 0, 0, 1, 0, 0, ALU_ADD);
        check(32'h064000EF, "JAL",   J_TYPE,  100, 1, 0, 0, 0, 0, 0, 1, ALU_ADD);

        $display("----------------------------------------");
        if (fail_count == 0)
            $display("ALL %0d TESTS PASSED", pass_count);
        else begin
            $display("%0d PASSED, %0d FAILED", pass_count, fail_count);
            $error("Self-check testbench reported failing tests - see FAIL lines above.");
        end

        $finish;
    end

endmodule
