`timescale 1ns/1ps

module tb_kreacher_top;

  // Clock & Reset
  reg I_CLK = 0;
  reg I_A_RESET_L = 0;   // active-low reset

  // Optional interrupt input
  reg I_INTR_H = 0;

  // Clock generation (100 MHz)
  always #5 I_CLK = ~I_CLK;

  // Reset sequence
  initial begin
    I_A_RESET_L = 0;     // hold reset low
    #100;
    I_A_RESET_L = 1;     // release reset
  end

  // DUT
  kreacher_top dut (
    .I_CLK       (I_CLK),
    .I_A_RESET_L (I_A_RESET_L),

    .I_INTR_H    (I_INTR_H),
    .O_INTR_ACK  ( )
  );

  // Optional — end simulation after some time
  initial begin
    $display("[%0t] Simulation start", $time);
    #5000;
    $display("[%0t] Simulation done", $time);
    $finish;
  end

endmodule

