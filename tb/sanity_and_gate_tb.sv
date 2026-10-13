// =============================================================================
// File        : tb/sanity_and_gate_tb.sv
// Description : Testbench for the AND gate sanity check.
//               Applies all four input combinations and prints the output.
//               Expected output (every line):
//                 a=0 b=0 y=0
//                 a=0 b=1 y=0
//                 a=1 b=0 y=0
//                 a=1 b=1 y=1
// =============================================================================

`timescale 1ns/1ps

module sanity_and_gate_tb;

    logic a, b, y;

    // Instantiate the design under test (DUT)
    sanity_and_gate dut (
        .a (a),
        .b (b),
        .y (y)
    );

    initial begin
        // Tell the simulator to save all signal changes to a waveform file
        $dumpfile("sanity_and_gate.vcd");
        $dumpvars(0, sanity_and_gate_tb);

        // Apply all four input combinations; #10 waits 10 ns between each
        a = 0; b = 0; #10;
        $display("a=%0d b=%0d y=%0d", a, b, y);

        a = 0; b = 1; #10;
        $display("a=%0d b=%0d y=%0d", a, b, y);

        a = 1; b = 0; #10;
        $display("a=%0d b=%0d y=%0d", a, b, y);

        a = 1; b = 1; #10;
        $display("a=%0d b=%0d y=%0d", a, b, y);

        $finish;
    end

endmodule
