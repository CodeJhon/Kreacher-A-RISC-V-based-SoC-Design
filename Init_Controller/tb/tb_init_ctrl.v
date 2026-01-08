`timescale 1ns / 1ps

module tb_init_ctrl;

  // ------------------------------------------------------------
  // Parameters
  // ------------------------------------------------------------
  parameter ADDR_W = 17;
  parameter [ADDR_W-1:0]BASE_ADDR = 17'h00000;
  parameter [ADDR_W-1:0]MEM_LIMIT = 17'h01FFF;
  parameter INCR = 8;

  // ------------------------------------------------------------
  // DUT signals
  // ------------------------------------------------------------
  reg                 clk;
  reg                 rst;
  reg                 interrupt;
  reg                 enable;

  wire [2:0]           state;
  wire                 SPI_rdata_type;
  wire                 PRAM_Addr_type;
  wire                 PRAM_in;
  wire                 burst_dim;
  wire                 ROM_addr_type;
  wire                 mem_init;
  wire [ADDR_W-1:0]    addr;

  // ------------------------------------------------------------
  // Instantiate DUT
  // ------------------------------------------------------------
  init_ctrl #(
    .ADDR_W     (ADDR_W),
    .BASE_ADDR  (BASE_ADDR),
    .MEM_LIMIT  (MEM_LIMIT),
    .INCR       (INCR)
  ) dut (
    .clk            (clk),
    .rst            (rst),
    .interrupt      (interrupt),
    .enable         (enable),
    .state          (state),
    .SPI_rdata_type (SPI_rdata_type),
    .PRAM_Addr_type (PRAM_Addr_type),
    .PRAM_in        (PRAM_in),
    .burst_dim      (burst_dim),
    .ROM_addr_type  (ROM_addr_type),
    .mem_init       (mem_init),
    .addr           (addr)
  );

  // ------------------------------------------------------------
  // Clock generation: 100 MHz
  // ------------------------------------------------------------
  always #5 clk = ~clk;

  // ------------------------------------------------------------
  // Stimulus
  // ------------------------------------------------------------
  initial begin
    // Init
    clk       = 0;
    rst       = 1;
    enable    = 0;
    interrupt = 0;

    // Hold reset
    #20;
    rst = 0;

    // Start initialization
    @(posedge clk);
    enable = 1;

    // Run until SUCCESS
    while (state != 3'd3) begin
      @(posedge clk);
      $display("[%0t] state=%0d addr=0x%0h mem_init=%b",
               $time, state, addr, mem_init);
    end

    // Stop stepping
    enable = 0;

    $display("--------------------------------------------------");
    $display("Initialization completed at addr=0x%0h", addr);
    $display("--------------------------------------------------");

    #20;
    $finish;
  end

endmodule
