# Mini RISC-V Instruction Decoder — Complete Line-by-Line Code Explanation

This document explains **every single line** of every file in the project,
written in plain language so that you can understand and explain it to
Dr. Shilpi Birla without hesitation.

---

## Table of Contents

1. [rtl/riscv_pkg.sv](#1-rtlriscv_pkgsv)
2. [rtl/field_extractor.sv](#2-rtlfield_extractorsv)
3. [rtl/imm_generator.sv](#3-rtlimm_generatorsv)
4. [rtl/instr_type_decoder.sv](#4-rtlinstr_type_decodersv)
5. [rtl/control_unit.sv](#5-rtlcontrol_unitsv)
6. [rtl/riscv_instr_decoder.sv](#6-rtlriscv_instr_decodersv)
7. [tb/sanity_and_gate.sv + tb.sv](#7-tbsanity_and_gatesv)
8. [tb/tb_selfcheck.sv](#8-tbtb_selfchecksv)
9. [run_vcs.sh](#9-run_vcssh)
10. [Key Concepts to Understand for the Viva](#10-key-concepts-for-viva)

---

## 1. rtl/riscv_pkg.sv

**Purpose:** A *package* in SystemVerilog is like a shared header file. Instead
of typing the same magic numbers in five different files (and risking typos),
we define them once here and every other file just says "give me everything from
riscv_pkg".

```systemverilog
package riscv_pkg;
```
> This line starts the package. Everything between here and `endpackage` is
> shared across all files that import it.

```systemverilog
    parameter logic [6:0] OPCODE_RTYPE = 7'b0110011;
```
> `parameter` means "a constant that never changes at runtime".
> `logic [6:0]` means a 7-bit value.
> `7'b0110011` means "7 bits, written in binary, value = 0110011".
> This is the opcode for R-type instructions (ADD, SUB, AND, OR, XOR, SLT).
> The bottom 7 bits of any ADD/SUB/AND/OR/XOR/SLT instruction will always be 0110011.

```systemverilog
    parameter logic [6:0] OPCODE_ITYPE = 7'b0010011; // addi, andi, ori
    parameter logic [6:0] OPCODE_LOAD  = 7'b0000011; // lw
```
> I-type arithmetic (ADDI/ANDI/ORI) and Load (LW) have *different* opcodes
> even though they use the same instruction layout. The decoder needs to
> handle both.

```systemverilog
    parameter logic [2:0] F3_ADD_SUB = 3'b000;
```
> `funct3` is the 3-bit field at bits [14:12] of the instruction. For ADD and
> ADDI, funct3 is 000. The difference between ADD and SUB is decided by funct7,
> not funct3.

```systemverilog
    parameter logic [3:0] ALU_ADD = 4'b0000;
    parameter logic [3:0] ALU_SUB = 4'b0001;
    ...
```
> These are 4-bit codes that our control_unit will output to tell a future ALU
> which operation to perform. 0=ADD, 1=SUB, 2=AND, 3=OR, 4=XOR, 5=SLT.

```systemverilog
    typedef enum logic [2:0] {
        R_TYPE  = 3'd0,
        I_TYPE  = 3'd1,
        ...
        INVALID = 3'd6
    } instr_type_e;
```
> `typedef enum` creates a named type. Instead of carrying a plain number to
> represent instruction type, we use *names* like `R_TYPE` or `B_TYPE`.
> This makes waveforms in GTKWave/DVE readable — you see "R_TYPE" instead of
> a meaningless binary number.
> `instr_type_e` is the type name; you declare signals of this type in other modules.

---

## 2. rtl/field_extractor.sv

**Purpose:** Every RISC-V instruction is 32 bits. Certain fields always sit at
the *same bit positions* regardless of instruction format. This module just
names those positions.

```systemverilog
module field_extractor (
    input  logic [31:0] instr,
    output logic [6:0]  opcode,
    ...
);
```
> `module` starts a hardware block (like a circuit in a chip).
> `input logic [31:0] instr` means: one 32-bit wire coming *in*.
> `output logic [6:0] opcode` means: one 7-bit wire going *out*.
> `[31:0]` = 32 bits, where bit 31 is the leftmost (most significant).

```systemverilog
    assign opcode = instr[6:0];
```
> `assign` creates a permanent wire connection.
> `instr[6:0]` means "take only bits 6 down to 0 from the 32-bit `instr` signal".
> So `opcode` is literally wired directly to those 7 bits — no logic, just a wire.

```systemverilog
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];
```
> Same idea for every other field. Each line says "these bits of the instruction
> are named this". The bit ranges come directly from the RISC-V specification.

**Important note:** This module always extracts ALL six fields even when some
are not meaningful (e.g., LUI has no rs1). That's fine — the other modules
just ignore the irrelevant outputs for each instruction type.

---

## 3. rtl/imm_generator.sv

**Purpose:** RISC-V instructions contain a constant number (called an
"immediate") that is split across different bit positions depending on the
format. This module reassembles those bits into a correct 32-bit signed number.

```systemverilog
import riscv_pkg::*;
```
> This line, placed *before* the module declaration, gives this module access
> to every name defined in riscv_pkg (OPCODE_ITYPE, OPCODE_LOAD, etc.).

```systemverilog
module imm_generator (
    input  logic [31:0] instr,
    output logic [31:0] imm
);
```
> Inputs: the 32-bit instruction.
> Output: a 32-bit signed immediate value.

```systemverilog
    logic [6:0] opcode;
    assign opcode = instr[6:0];
```
> We extract the opcode locally (just bits 6:0) to use in the case statement below.
> It's the same slice as field_extractor does, just done here again locally.

```systemverilog
    always_comb begin
        case (opcode)
```
> `always_comb` means: "re-evaluate everything inside this block whenever any
> input changes". It describes combinational (no-clock) logic.
> `case (opcode)` checks which value the opcode has and runs the matching branch.

```systemverilog
            OPCODE_ITYPE, OPCODE_LOAD: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end
```
> This handles ADDI, ANDI, ORI, and LW — all use the I-type immediate layout.
> `{20{instr[31]}}` means "repeat bit 31 twenty times". This is *sign extension*.
>   - If the immediate is positive (bit 31 = 0), the top 20 bits become 00000...0
>   - If the immediate is negative (bit 31 = 1), the top 20 bits become 11111...1
> After those 20 copies of the sign bit, we attach `instr[31:20]` (the 12 actual immediate bits).
> Result: a proper 32-bit signed number.

```systemverilog
            OPCODE_STYPE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
```
> For SW (S-type), the 12-bit immediate is *split*: upper 7 bits are at [31:25],
> lower 5 bits are at [11:7]. We join them with `{...,...}` then sign-extend.

```systemverilog
            OPCODE_BTYPE: begin
                imm = {{19{instr[31]}}, instr[31], instr[7],
                        instr[30:25], instr[11:8], 1'b0};
            end
```
> For BEQ/BNE (B-type), the bits are stored in a scrambled order in the instruction.
> Why scrambled? So that rs1, rs2, funct3, opcode stay at their usual positions.
> We unscramble by carefully placing each piece:
>   - 19 copies of sign bit (bit 31)
>   - bit 31 again = imm[12] (the sign bit of the immediate)
>   - bit 7  = imm[11]
>   - bits 30:25 = imm[10:5]
>   - bits 11:8  = imm[4:1]
>   - `1'b0` = imm[0] is always 0 (branch targets must be 2-byte aligned)
> Total bits: 19 + 1 + 1 + 6 + 4 + 1 = 32. ✓

```systemverilog
            OPCODE_UTYPE: begin
                imm = {instr[31:12], 12'b0};
            end
```
> For LUI: the upper 20 bits of the instruction ARE the upper 20 bits of the result.
> The lower 12 bits are just padded with zeros. No sign extension needed.

```systemverilog
            OPCODE_JTYPE: begin
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                        instr[20], instr[30:21], 1'b0};
            end
```
> For JAL: same scrambling idea as B-type but wider (20-bit immediate, not 12-bit).
>   - 11 sign-bit copies
>   - bit 31 = imm[20]
>   - bits 19:12 = imm[19:12]
>   - bit 20 = imm[11]
>   - bits 30:21 = imm[10:1]
>   - `1'b0` = imm[0] (always 0, jump targets are 2-byte aligned)
> Total: 11 + 1 + 8 + 1 + 10 + 1 = 32. ✓

```systemverilog
            default: begin
                imm = 32'd0;
            end
```
> R-type instructions have no immediate field. We output zero.
> The `default` also handles any unknown opcode safely.

---

## 4. rtl/instr_type_decoder.sv

**Purpose:** Simply looks at the 7-bit opcode and reports which of the six
RISC-V formats this instruction belongs to, as a human-readable enum value.

```systemverilog
import riscv_pkg::*;

module instr_type_decoder (
    input  logic [31:0]  instr,
    output instr_type_e  instr_type
);
```
> The output is of type `instr_type_e` — the enum we defined in riscv_pkg.
> This makes the waveform viewer show "R_TYPE" instead of "0", "I_TYPE" instead
> of "1", etc.

```systemverilog
    always_comb begin
        case (opcode)
            OPCODE_RTYPE:              instr_type = R_TYPE;
            OPCODE_ITYPE, OPCODE_LOAD: instr_type = I_TYPE;
            OPCODE_STYPE:              instr_type = S_TYPE;
            OPCODE_BTYPE:              instr_type = B_TYPE;
            OPCODE_UTYPE:              instr_type = U_TYPE;
            OPCODE_JTYPE:              instr_type = J_TYPE;
            default:                   instr_type = INVALID;
        endcase
    end
```
> Each line maps one opcode value to one format name.
> `OPCODE_ITYPE, OPCODE_LOAD:` on the same line means "either of these opcodes
> gives I_TYPE". Both ADDI (opcode 0010011) and LW (opcode 0000011) are I-type
> in terms of immediate layout, but they have different opcodes.
> `default:` catches any opcode not in our list and marks it INVALID.

---

## 5. rtl/control_unit.sv

**Purpose:** This is the "brain" of the decoder. Given the opcode, funct3,
and funct7, it decides what the rest of a processor should do. Each output is
a one-bit control signal (or a 4-bit code for the ALU).

```systemverilog
module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       alu_src,
    output logic       branch,
    output logic       jump,
    output logic [3:0] alu_ctrl
);
```
> Eight outputs:
> - `reg_write` = 1 means "write result back to register rd"
> - `mem_read`  = 1 means "read from data memory" (LW)
> - `mem_write` = 1 means "write to data memory" (SW)
> - `mem_to_reg`= 1 means "rd gets the memory value, not the ALU result" (LW only)
> - `alu_src`   = 1 means "ALU's second input is the immediate, not rs2"
> - `branch`    = 1 means "this might branch" (BEQ / BNE)
> - `jump`      = 1 means "unconditional jump" (JAL)
> - `alu_ctrl`  = 4-bit code for which ALU operation to run

```systemverilog
    always_comb begin
        // Safe defaults first
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        ...
        alu_ctrl   = ALU_ADD;
```
> We set every output to 0 (or ALU_ADD as a safe default) at the top of the
> always_comb block. The case statement below only changes what actually needs
> to differ from zero. This is the standard way to write control units — it
> guarantees every output is always assigned, preventing "latch inference"
> (an accidental memory element).

```systemverilog
        case (opcode)
            OPCODE_RTYPE: begin
                reg_write = 1'b1;   // result goes to rd
                alu_src   = 1'b0;   // operand 2 = rs2 (a register)
                case ({funct7, funct3})
                    {F7_NORMAL, F3_ADD_SUB}: alu_ctrl = ALU_ADD;
                    {F7_SUB,    F3_ADD_SUB}: alu_ctrl = ALU_SUB;
                    ...
                endcase
            end
```
> For R-type: we write to a register (reg_write=1), use rs2 as operand (alu_src=0).
> The *inner* case uses the *concatenation* `{funct7, funct3}` — a 10-bit value
> made by joining the two fields together. This lets us distinguish ADD from SUB
> (same funct3, different funct7) and from AND/OR/XOR (different funct3).
> `{F7_NORMAL, F3_ADD_SUB}` = `{7'b0000000, 3'b000}` = `10'b0000000000` → ADD
> `{F7_SUB,    F3_ADD_SUB}` = `{7'b0100000, 3'b000}` = `10'b0100000000` → SUB

```systemverilog
            OPCODE_LOAD: begin
                reg_write  = 1'b1;  // loaded value goes to rd
                mem_read   = 1'b1;  // read from memory
                mem_to_reg = 1'b1;  // rd value comes from memory, NOT ALU
                alu_src    = 1'b1;  // address = rs1 + imm
                alu_ctrl   = ALU_ADD;
            end
```
> LW (load word): the ALU computes the memory address (rs1 + immediate).
> `mem_to_reg=1` is what distinguishes LW from ADDI — both use the ALU with an
> immediate, but LW reads memory and puts THAT result in rd.

```systemverilog
            OPCODE_BTYPE: begin
                branch   = 1'b1;
                alu_src  = 1'b0;
                alu_ctrl = ALU_SUB;  // rs1 - rs2; if result=0 then equal
            end
```
> For BEQ and BNE, the ALU subtracts the two registers. If the result is zero,
> they are equal. The branch decision circuit (outside this project's scope) uses
> the zero flag from the ALU together with funct3 to choose BEQ vs BNE.
> Both instructions produce *identical* control signals from this module.

---

## 6. rtl/riscv_instr_decoder.sv

**Purpose:** The top-level module. It contains no logic of its own — it just
*instantiates* (creates copies of) the four sub-modules and *wires* them together.

```systemverilog
module riscv_instr_decoder (
    input  logic [31:0]  instr,
    output logic [6:0]   opcode,
    ...
    output logic [3:0]   alu_ctrl
);
```
> One input (the instruction), many outputs (everything the decoder produces).

```systemverilog
    field_extractor u_field_extractor (
        .instr  (instr),
        .opcode (opcode),
        ...
    );
```
> `field_extractor` is the module name (the type).
> `u_field_extractor` is the instance name (like a variable name for this copy).
> `.instr(instr)` means "connect the port named `instr` of field_extractor to
> the signal named `instr` in this top-level module".
> Named port connections (`.port(signal)`) are the standard in production code.

```systemverilog
    control_unit u_control_unit (
        .opcode  (opcode),
        .funct3  (funct3),
        .funct7  (funct7),
        ...
    );
```
> Notice: `opcode`, `funct3`, `funct7` here are the *outputs* of `u_field_extractor`
> above and the *inputs* of `u_control_unit` here. Both connect to the same top-level
> signal. This is how structural hardware works — a wire can be driven by one
> module and read by another.

---

## 7. tb/sanity_and_gate.sv

**Purpose:** A two-input AND gate, used only to verify that VCS is installed
and working before touching any real RISC-V code.

```systemverilog
module sanity_and_gate (
    input  logic a,
    input  logic b,
    output logic y
);
    assign y = a & b;
endmodule
```
> `&` is bitwise AND in SystemVerilog. For 1-bit signals it behaves like a
> logical AND. This is the smallest possible circuit — one logic gate.

**Testbench (sanity_and_gate_tb.sv):**

```systemverilog
`timescale 1ns/1ps
```
> This line tells the simulator that "1" in a delay means 1 nanosecond,
> and the precision is 1 picosecond. It must appear before the module.

```systemverilog
initial begin
    a = 0; b = 0; #10;
    $display("a=%0d b=%0d y=%0d", a, b, y);
```
> `initial begin ... end` runs exactly once at simulation time zero.
> `a = 0; b = 0;` sets inputs.
> `#10;` waits 10 time units (10 ns with our timescale) for combinational logic to settle.
> `$display(...)` prints a formatted line. `%0d` prints a decimal integer.

---

## 8. tb/tb_selfcheck.sv

**Purpose:** The most important testbench. It automatically compares every output
against a pre-computed expected value and prints PASS or FAIL. You can show the
professor "ALL 16 TESTS PASSED" as definitive proof the design is correct.

```systemverilog
    int pass_count = 0;
    int fail_count = 0;
```
> Integer counters to track results. `int` is a 32-bit signed integer, fine for
> counting up to ~2 billion — more than enough for 16 tests.

```systemverilog
    task check(
        input logic [31:0]       i,
        input string             name,
        input instr_type_e       exp_type,
        input logic signed [31:0] exp_imm,
        ...
    );
```
> A `task` is like a function in C. We define `check` once and call it 16 times.
> It takes the instruction hex, a name string, and the expected values for every
> signal. Inside, it applies the instruction, waits 10 ns, then compares.

```systemverilog
        ok = (instr_type === exp_type)   &&
             (imm       === exp_imm)     &&
             ...
```
> `===` is "case equality" — it treats unknown (X) values as mismatches.
> Regular `==` would ignore X, which could hide bugs during early simulation.
> `&&` is logical AND — all conditions must be true for `ok` to be 1.

```systemverilog
        if (ok) begin
            pass_count++;
            $display("PASS  %-6s ...", name, ...);
        end else begin
            fail_count++;
            $display("FAIL  %-6s ...", name, ...);
```
> If all 10 signal comparisons passed → print PASS and increment pass counter.
> If any signal is wrong → print FAIL (with the actual wrong values on the next line).
> `%-6s` means "left-justify string in a 6-character column" — for neat alignment.

```systemverilog
        if (fail_count == 0)
            $display("ALL %0d TESTS PASSED", pass_count);
        else begin
            $display("%0d PASSED, %0d FAILED", pass_count, fail_count);
            $error("...");
        end
```
> Final summary. `$error` causes VCS to flag the simulation as failed, which is
> useful in automated regression runs.

---

## 9. run_vcs.sh

**Purpose:** A shell script that runs all 7 testbenches in sequence on the lab
Linux machine (Alma Linux with Synopsys VCS).

```bash
#!/bin/bash
```
> "Shebang" line: tells the OS to run this file with the bash shell.

```bash
set -e
```
> "Exit on error": if any command fails (non-zero exit code), the script stops
> immediately instead of continuing and hiding the failure.

```bash
vcs -sverilog \
    rtl/riscv_pkg.sv \
    rtl/field_extractor.sv \
    ...
    -o simv_fe
./simv_fe
```
> `vcs` is the Synopsys VCS simulator command.
> `-sverilog` enables SystemVerilog (IEEE 1800) language support — same role as
> `-g2012` in Icarus Verilog.
> List all `.sv` files that are needed for this compilation unit.
> `-o simv_fe` names the compiled simulation binary.
> `./simv_fe` then runs that binary to produce output.
> The `\` at end of line is a line-continuation character — the command continues.

---

## 10. Key Concepts for Viva

### What is an instruction decoder?
A circuit that looks at a 32-bit instruction and figures out what it means:
which registers are involved, what constant number is embedded in it, and
which control signals to assert so the rest of the processor acts correctly.

### Why RISC-V?
RISC-V is open-source (no license fee), has a clean fixed-width 32-bit encoding,
and is designed so that common fields (opcode, rd, rs1, rs2) always sit at the
same bit positions across formats — making it ideal for a beginner decoder project.

### Why no clock?
A decoder is pure combinational logic. Its output depends only on the current
instruction input, not on any past history. Adding a clock would be wrong for
this circuit.

### Why are B-type and J-type bits scrambled?
To keep rs1, rs2, funct3, and opcode in their usual bit positions across all
formats. This lets the field_extractor slice those fields identically regardless
of format. The scrambled immediate bits are unscrambled by the imm_generator.

### Why do BEQ and BNE produce the same control signals?
The control_unit's job is to say "compare rs1 and rs2 and consider branching".
The distinction between "branch if equal" (funct3=000) and "branch if not equal"
(funct3=001) is made downstream, in a branch-decision circuit that looks at the
ALU's zero-flag combined with funct3. That circuit is outside this project's scope.

### Why does field_extractor output "don't-care" values for some formats?
field_extractor always reads all six fields because the hardware wires are always
connected. For LUI (which has no rs1/rs2/funct3), those outputs exist but are
meaningless — the control_unit and imm_generator for LUI simply don't use them.

### How did you verify correctness?
1. Each sub-module has its own testbench tested in isolation.
2. The final self-checking testbench (tb_selfcheck.sv) applies all 16 instructions
   to the complete top-level decoder and automatically compares 10 output signals
   per instruction against hand-calculated expected values.
3. The waveform (tb_selfcheck.vcd) can be opened in GTKWave to visually inspect
   that instr_type changes correctly through all six formats.

### What would you add to make a full CPU?
- A real ALU (takes alu_ctrl + two operands, computes the result)
- A register file (32 × 32-bit registers; reads rs1/rs2, writes to rd using reg_write)
- A data memory (reads when mem_read=1, writes when mem_write=1)
- A branch comparator (uses ALU zero-flag + funct3 to decide BEQ vs BNE)
- A program counter (increments by 4 normally, or jumps by imm for JAL/BEQ/BNE)

All the signals this decoder produces are exactly what those units would need.
