// =============================================================================
// File        : tb/sanity_and_gate.sv
// Description : A trivial two-input AND gate used as a toolchain sanity check.
//               If this compiles and simulates correctly then the simulator
//               (VCS / Icarus) is working end-to-end before any real code is run.
// =============================================================================

module sanity_and_gate (
    input  logic a,
    input  logic b,
    output logic y
);
    assign y = a & b;
endmodule
