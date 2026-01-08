`timescale 1ns/1ps

module tb_top_wrapper;

  // ----------------------------
  // Clock & Reset
  // ----------------------------
  reg I_CLK       = 0;
  reg I_A_RESET_L = 0;

  // ----------------------------
  // Interrupt Signals
  // ----------------------------
  reg  I_INTR_H   = 0;
  wire O_INTR_ACK;

  // ----------------------------
  // Clock Generation (50 MHz)
  // ----------------------------
  localparam CLK_PERIOD = 20;
  always #(CLK_PERIOD/2) I_CLK = ~I_CLK;

  // ----------------------------
  // DUT Instantiation
  // ----------------------------
  top_wrapper dut (
    .I_CLK       (I_CLK),
    .I_A_RESET_L (I_A_RESET_L),
    .I_INTR_H    (I_INTR_H),
    .O_INTR_ACK  (O_INTR_ACK)
  );

  // ----------------------------
  // Reset + Basic Stimulus
  // ----------------------------
  initial begin
    $display("[%0t] Starting simulation", $time);

    // Apply reset
    I_A_RESET_L = 0;
    #(CLK_PERIOD*5);

    I_A_RESET_L = 1;
    $display("[%0t] Reset released", $time);
//    #15000;
   end
   
endmodule
