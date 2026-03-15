//For validation of cpu_stress_test
// -> check /tb_validation_kreacher/dut/u_kreacher_top/PMEM_interface_top_inst/\GEN_EVEN_MACROS[2].PRAM_even /sram_core_i/memory[0]=0x857319ea

//For validation of aes128_test
// -> check /tb_validation_kreacher/dut/u_kreacher_top/PMEM_interface_top_inst/\GEN_EVEN_MACROS[2].PRAM_even /sram_core_i/memory[0]=0xc063dcde

//For validation of fft_test
// -> check /tb_validation_kreacher/dut/u_kreacher_top/PMEM_interface_top_inst/\GEN_EVEN_MACROS[2].PRAM_even /sram_core_i/memory[0]=0x2de8aac0

//For validation of matmul_test
// -> check /tb_validation_kreacher/dut/u_kreacher_top/PMEM_interface_top_inst/\GEN_EVEN_MACROS[2].PRAM_even /sram_core_i/memory[0]=0x0d33d2c9

//**To simulate different programs, one needs to put the name of the mem file in parameter "ALGORITHM_FILE"**
`timescale 1ns/1ps

module tb_validation_kreacher;

  // Parameters
  localparam ALGORITHM_FILE = "aes128_test.mem";
  localparam CLK_PERIOD_NS = 30;           
  localparam RESET_CYCLES = 2;            
  localparam SIM_TIMEOUT_NS = 20_000_000;  // This simulation time applies to all C program

  localparam ADDR_BYTE_W = 17;
  localparam DATA_W      = 64;
  localparam external_mem_WORDS   = 8192;
  localparam external_mem_ADDR_W  = 14;

  // Clock & reset_n
  reg clk;
  reg reset_n;

  // Instantiate DUT (kreacher_top and external mem)
  reg irq0;
  reg irq1;
  
  wire acknowledge_irq0;
  wire acknowledge_irq1;
  
  validation_kreacher #(
  .ADDR_BYTE_W(ADDR_BYTE_W),
  .DATA_W(DATA_W),
  .external_mem_WORDS(external_mem_WORDS),
  .external_mem_ADDR_W(external_mem_ADDR_W),
  .ALGORITHM_FILE(ALGORITHM_FILE)
  ) dut(
	.I_CLK(clk),
  .I_A_RESET_L(reset_n),
	.I_INTR_H({irq1, irq0}),
	.O_INTR_ACK({acknowledge_irq1, acknowledge_irq0})
  );
  
  // clock generation
  initial begin
    clk = 0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  // Reset sequence
  initial begin
    reset_n = 0;
    repeat (RESET_CYCLES) @(posedge clk);
    reset_n = 1;
  end

  // Simulation timeout watchdog
  initial begin
    irq0 = 1'b0;
    irq1 = 1'b0;
    #(SIM_TIMEOUT_NS);
    $display("TIMEOUT: Simulation reached time limit of %0d ns at time %0t ns.", SIM_TIMEOUT_NS, $time);
    $finish;
  end


endmodule