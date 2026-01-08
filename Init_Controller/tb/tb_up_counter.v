`timescale 1ns / 1ps

module tb_up_counter;

    // Parameters
    parameter INCR     = 8;
    parameter LOAD_DIM = 17;

    // DUT signals
    reg clk;
    reg enable;
    reg reset;
    reg [LOAD_DIM-1:0] load_value;
    reg [LOAD_DIM-1:0] max_value;
    wire [LOAD_DIM-1:0] count;

    // DUT instantiation
    up_counter #(
        .INCR(INCR),
        .LOAD_DIM(LOAD_DIM)
    ) dut (
        .clk(clk),
        .enable(enable),
        .reset(reset),
        .load_value(load_value),
        .max_value(max_value),
        .count(count)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk        = 0;
        enable     = 0;
        reset      = 0;
        load_value = 0;
        max_value  = 0;

        // --------------------
        // Apply reset
        // --------------------
        #2;
        load_value = 17'd32;
        max_value  = 17'd96;
        reset      = 1;

        #10;
        reset      = 0;

        // --------------------
        // Enable counting
        // --------------------
        #10;
        enable = 1;

        // Let it run (wrap should occur)
        #120;

        // --------------------
        // Disable (hold)
        // --------------------
        enable = 0;
        #30;

        // --------------------
        // Change base & max
        // --------------------
        load_value = 17'd100;
        max_value  = 17'd140;
        #10;

        // Reset again
        reset = 1;
        #10;
        reset = 0;

        // Enable again
        enable = 1;
        #80;

        // End simulation
        $finish;
    end

    // Monitor
    initial begin
        $monitor("T=%0t | rst=%b en=%b | count=%0d",
                 $time, reset, enable, count);
    end

    // Optional waveform dump
    initial begin
        $dumpfile("up_counter.vcd");
        $dumpvars(0, tb_up_counter);
    end

endmodule
