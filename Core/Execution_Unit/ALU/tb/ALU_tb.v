`timescale 1ns / 1ps
module ALU_tb;

    // Testbench signals
    reg a;        // input a
    reg b;        // input b
    wire y;       // output y

    ALU uut (
        .a(a),
        .b(b),
        .y(y)
    );

    // Test sequence
    initial begin
        // Initialize inputs
        a = 0; b = 0;
        #10;  // wait 10 ns

        a = 0; b = 1;
        #10;

        a = 1; b = 0;
        #10;

        a = 1; b = 1;
        #10;

        // Finish simulation
        $finish;
    end

endmodule
