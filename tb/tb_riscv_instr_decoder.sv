// =============================================================================
// File        : tb/tb_riscv_instr_decoder.sv
// Description : Integration testbench for the complete top-level decoder.
//               Applies all fifteen in-scope instructions and prints both the
//               decoded fields and the control signals on two lines per instruction.
//               Cross-check the output against Tables 9.1, 10.1, 11.5 and 12.1.
// =============================================================================

`timescale 1ns/1ps
import riscv_pkg::*;

module tb_riscv_instr_decoder;

    logic [31:0]  instr;
    logic [6:0]   opcode, funct7;
    logic [4:0]   rd, rs1, rs2;
    logic [2:0]   funct3;
    logic [31:0]  imm;
    instr_type_e  instr_type;
    logic reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch, jump;
    logic [3:0] alu_ctrl;

    // Connect all ports by name (.*) - every port maps to an identically named signal
    riscv_instr_decoder dut (.instr(instr), .opcode(opcode), .rd(rd),
                             .funct3(funct3), .rs1(rs1), .rs2(rs2),
                             .funct7(funct7), .imm(imm),
                             .instr_type(instr_type),
                             .reg_write(reg_write), .mem_read(mem_read),
                             .mem_write(mem_write), .mem_to_reg(mem_to_reg),
                             .alu_src(alu_src), .branch(branch),
                             .jump(jump), .alu_ctrl(alu_ctrl));

    // Task: apply one instruction, print decoded output on two lines
    task apply(input logic [31:0] i, input string name);
        instr = i;
        #10;
        $display("%-14s type=%-7s rd=%0d rs1=%0d rs2=%0d imm=%0d",
                   name, instr_type.name(), rd, rs1, rs2, $signed(imm));
        $display("               rw=%0d mr=%0d mw=%0d m2r=%0d asrc=%0d br=%0d jmp=%0d alu=%0d",
                   reg_write, mem_read, mem_write, mem_to_reg,
                   alu_src, branch, jump, alu_ctrl);
    endtask

    initial begin
        $dumpfile("tb_riscv_instr_decoder.vcd");
        $dumpvars(0, tb_riscv_instr_decoder);

        apply(32'h003100B3, "ADD");
        apply(32'h40628233, "SUB");
        apply(32'h009473B3, "AND");
        apply(32'h00C5E533, "OR");
        apply(32'h00F746B3, "XOR");
        apply(32'h0128A833, "SLT");
        apply(32'h00A30293, "ADDI");
        apply(32'h00F1F113, "ANDI");
        apply(32'h0081E113, "ORI");
        apply(32'h00812083, "LW");
        apply(32'h00322623, "SW");
        apply(32'h00208463, "BEQ");
        apply(32'hFE209EE3, "BNE");
        apply(32'h123452B7, "LUI");
        apply(32'h064000EF, "JAL");

        $finish;
    end

endmodule
