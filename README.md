# Mini RISC-V Instruction Decoder

A SystemVerilog implementation of a combinational instruction decoder for a
subset of the RV32I base integer instruction set, built as a final-year
B.Tech ECE mini-project.

## Team

- Aryan
- Abhimanyu

## Course

B.Tech, Electronics and Communication Engineering – Final Year

## Project Description

Every processor works by repeatedly fetching a 32-bit binary number (an instruction)
and figuring out what that number is asking it to do. The circuit that performs this
"figuring out" is called an instruction decoder. This project builds exactly that
circuit for a simplified version of RISC-V.

The decoder is purely combinational — it has no clock and no memory of past inputs.
Given a 32-bit instruction, it immediately produces:
- The individual fields (opcode, rd, funct3, rs1, rs2, funct7)
- A sign-extended 32-bit immediate value
- The instruction format type (R / I / S / B / U / J)
- Eight control signals to drive an ALU, register file, and memory in a complete CPU

## Supported Instructions

| Mnemonic | Format | Opcode    | funct3 | funct7  | Meaning                       |
|----------|--------|-----------|--------|---------|-------------------------------|
| ADD      | R      | 0110011   | 000    | 0000000 | rd = rs1 + rs2                |
| SUB      | R      | 0110011   | 000    | 0100000 | rd = rs1 - rs2                |
| AND      | R      | 0110011   | 111    | 0000000 | rd = rs1 AND rs2              |
| OR       | R      | 0110011   | 110    | 0000000 | rd = rs1 OR rs2               |
| XOR      | R      | 0110011   | 100    | 0000000 | rd = rs1 XOR rs2              |
| SLT      | R      | 0110011   | 010    | 0000000 | rd = (rs1 < rs2) ? 1 : 0     |
| ADDI     | I      | 0010011   | 000    | –       | rd = rs1 + immediate          |
| ANDI     | I      | 0010011   | 111    | –       | rd = rs1 AND immediate        |
| ORI      | I      | 0010011   | 110    | –       | rd = rs1 OR immediate         |
| LW       | I      | 0000011   | 010    | –       | rd = memory[rs1 + immediate]  |
| SW       | S      | 0100011   | 010    | –       | memory[rs1 + immediate] = rs2 |
| BEQ      | B      | 1100011   | 000    | –       | if (rs1 == rs2) branch        |
| BNE      | B      | 1100011   | 001    | –       | if (rs1 != rs2) branch        |
| LUI      | U      | 0110111   | –      | –       | rd = immediate << 12          |
| JAL      | J      | 1101111   | –      | –       | rd = return addr; jump        |

## Repository Layout

```
.
├── README.md
├── .gitignore
├── run_vcs.sh              ← single script to run all tests on the lab machine
├── docs/
│   └── project_guide.pdf
├── rtl/                    ← synthesisable design files
│   ├── riscv_pkg.sv        ← shared constants and types
│   ├── field_extractor.sv  ← bit-slices the 6 instruction fields
│   ├── imm_generator.sv    ← reconstructs the 32-bit signed immediate
│   ├── instr_type_decoder.sv ← classifies into R/I/S/B/U/J
│   ├── control_unit.sv     ← generates the 8 control signals
│   └── riscv_instr_decoder.sv ← top-level: wires all 4 sub-modules
└── tb/                     ← simulation testbenches (not hardware)
    ├── sanity_and_gate.sv
    ├── sanity_and_gate_tb.sv
    ├── tb_field_extractor.sv
    ├── tb_imm_generator.sv
    ├── tb_instr_type_decoder.sv
    ├── tb_control_unit.sv
    ├── tb_riscv_instr_decoder.sv
    └── tb_selfcheck.sv     ← final self-checking testbench
```

## How to Simulate (Lab – Synopsys VCS on Alma Linux)

Run the provided script from the repository root:

```bash
chmod +x run_vcs.sh    # only needed once
./run_vcs.sh
```

This runs all 7 testbenches in sequence. The final output should be:

```
ALL 16 TESTS PASSED
```

### Run a single testbench manually

```bash
# Self-checking testbench only (the most important one):
vcs -sverilog \
    rtl/riscv_pkg.sv rtl/field_extractor.sv rtl/imm_generator.sv \
    rtl/instr_type_decoder.sv rtl/control_unit.sv rtl/riscv_instr_decoder.sv \
    tb/tb_selfcheck.sv -o simv_sc
./simv_sc
```

## How to View Waveforms

After running the self-check, a waveform file `tb_selfcheck.vcd` is produced.
Open it in GTKWave (if available on the lab machine):

```bash
gtkwave tb_selfcheck.vcd
```

Then add `instr`, `instr_type`, `imm`, `reg_write`, `alu_ctrl`, `branch`, `jump`
to the waveform view to see all 16 instructions decoded in sequence.

## Design Architecture

Four independently-tested sub-modules feed into one top-level wrapper:

```
instr (32-bit) → field_extractor  → opcode, rd, funct3, rs1, rs2, funct7
instr (32-bit) → imm_generator    → imm (sign-extended 32-bit immediate)
instr (32-bit) → instr_type_decoder → instr_type (R/I/S/B/U/J enum)
opcode + funct3 + funct7 → control_unit → 8 control signals
```

All four run in parallel on the same instruction — this is how real hardware works.

## Limitations / Future Work

This decoder handles 15 representative instructions covering all 6 RISC-V formats.
Not included (by design, to keep the scope manageable):
- Remaining RV32I instructions (SLTI, shifts, AUIPC, JALR, …)
- Execution (no ALU, register file, or memory)
- Compressed (16-bit) instructions
- Multiply/divide, atomics, floating point
- Exception and interrupt handling

Natural next steps: add a real ALU, a register file, and a branch comparator to
turn this decoder into a complete single-cycle RISC-V CPU.
