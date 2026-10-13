#!/bin/bash
# =============================================================================
# File        : run_vcs.sh
# Description : Run all testbenches using Synopsys VCS on the lab Linux machine.
#               Execute this script from the repository root directory:
#                   chmod +x run_vcs.sh   (first time only, to make it executable)
#                   ./run_vcs.sh
#
# VCS command format:
#   vcs -sverilog [source files] -o [output binary] && ./[output binary]
#
# The -sverilog flag enables SystemVerilog support (IEEE 1800).
# =============================================================================

set -e   # Stop immediately if any command fails

echo "========================================================"
echo " Mini RISC-V Instruction Decoder - VCS Simulation Suite"
echo "========================================================"
echo ""

# ------------------------------------------------------------------
# Test 1: Sanity AND gate (toolchain check)
# ------------------------------------------------------------------
echo "--- Test 1: Sanity AND gate ---"
vcs -sverilog \
    tb/sanity_and_gate.sv \
    tb/sanity_and_gate_tb.sv \
    -o simv_sanity
./simv_sanity
echo ""

# ------------------------------------------------------------------
# Test 2: Field Extractor
# ------------------------------------------------------------------
echo "--- Test 2: Field Extractor ---"
vcs -sverilog \
    rtl/field_extractor.sv \
    tb/tb_field_extractor.sv \
    -o simv_fe
./simv_fe
echo ""

# ------------------------------------------------------------------
# Test 3: Immediate Generator (all 5 formats, positive and negative)
# ------------------------------------------------------------------
echo "--- Test 3: Immediate Generator ---"
vcs -sverilog \
    rtl/riscv_pkg.sv \
    rtl/imm_generator.sv \
    tb/tb_imm_generator.sv \
    -o simv_imm
./simv_imm
echo ""

# ------------------------------------------------------------------
# Test 4: Instruction Type Decoder
# ------------------------------------------------------------------
echo "--- Test 4: Instruction Type Decoder ---"
vcs -sverilog \
    rtl/riscv_pkg.sv \
    rtl/instr_type_decoder.sv \
    tb/tb_instr_type_decoder.sv \
    -o simv_itd
./simv_itd
echo ""

# ------------------------------------------------------------------
# Test 5: Control Unit (all 15 in-scope instructions)
# ------------------------------------------------------------------
echo "--- Test 5: Control Unit ---"
vcs -sverilog \
    rtl/riscv_pkg.sv \
    rtl/control_unit.sv \
    tb/tb_control_unit.sv \
    -o simv_cu
./simv_cu
echo ""

# ------------------------------------------------------------------
# Test 6: Top-Level Integration (all 15 instructions, combined output)
# ------------------------------------------------------------------
echo "--- Test 6: Top-Level Integration ---"
vcs -sverilog \
    rtl/riscv_pkg.sv \
    rtl/field_extractor.sv \
    rtl/imm_generator.sv \
    rtl/instr_type_decoder.sv \
    rtl/control_unit.sv \
    rtl/riscv_instr_decoder.sv \
    tb/tb_riscv_instr_decoder.sv \
    -o simv_top
./simv_top
echo ""

# ------------------------------------------------------------------
# Test 7: Self-Checking Testbench (final verification - must say ALL 16 TESTS PASSED)
# ------------------------------------------------------------------
echo "--- Test 7: Self-Checking Testbench ---"
vcs -sverilog \
    rtl/riscv_pkg.sv \
    rtl/field_extractor.sv \
    rtl/imm_generator.sv \
    rtl/instr_type_decoder.sv \
    rtl/control_unit.sv \
    rtl/riscv_instr_decoder.sv \
    tb/tb_selfcheck.sv \
    -o simv_sc
./simv_sc
echo ""

echo "========================================================"
echo " All tests completed."
echo "========================================================"
