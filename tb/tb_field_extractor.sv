// =============================================================================
// File        : tb/tb_field_extractor.sv
// Description : Testbench for the field_extractor module.
//               Applies four instructions (R, I, S, U types) and prints every
//               extracted field.  Only the fields marked in the project guide's
//               Table 9.1 need to be verified - others may show "don't care"
//               values since field_extractor always reads all six fields
//               regardless of the instruction format.
//
// Expected output:
//   ADD x1,x2,x3    instr=003100b3 opcode=0110011 rd=1  funct3=000 rs1=2  rs2=3  funct7=0000000
//   ADDI x5,x6,10   instr=00a30293 opcode=0010011 rd=5  funct3=000 rs1=6  rs2=10 funct7=0000000
//   SW x3,12(x4)    instr=00322623 opcode=0100011 rd=12 funct3=010 rs1=4  rs2=3  funct7=0000000
//   LUI x5,0x12345  instr=123452b7 opcode=0110111 rd=5  funct3=101 rs1=8  rs2=3  funct7=0001001
//   (rd/funct3/rs1/rs2/funct7 for LUI are don't-care - only opcode and rd matter)
// =============================================================================

`timescale 1ns/1ps

module tb_field_extractor;

    logic [31:0] instr;
    logic [6:0]  opcode, funct7;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;

    // Instantiate the field extractor
    field_extractor dut (
        .instr  (instr),
        .opcode (opcode),
        .rd     (rd),
        .funct3 (funct3),
        .rs1    (rs1),
        .rs2    (rs2),
        .funct7 (funct7)
    );

    // Task: apply one instruction and print all fields
    task apply(input logic [31:0] i, input string name);
        instr = i;
        #10;  // wait for combinational logic to settle
        $display("%-16s instr=%h opcode=%b rd=%0d funct3=%b rs1=%0d rs2=%0d funct7=%b",
                   name, instr, opcode, rd, funct3, rs1, rs2, funct7);
    endtask

    initial begin
        $dumpfile("tb_field_extractor.vcd");
        $dumpvars(0, tb_field_extractor);

        // Test 1: ADD x1, x2, x3  (R-type)
        apply(32'h003100B3, "ADD x1,x2,x3");

        // Test 2: ADDI x5, x6, 10  (I-type)
        apply(32'h00A30293, "ADDI x5,x6,10");

        // Test 3: SW x3, 12(x4)  (S-type)
        apply(32'h00322623, "SW x3,12(x4)");

        // Test 4: LUI x5, 0x12345  (U-type)
        apply(32'h123452B7, "LUI x5,0x12345");

        $finish;
    end

endmodule
