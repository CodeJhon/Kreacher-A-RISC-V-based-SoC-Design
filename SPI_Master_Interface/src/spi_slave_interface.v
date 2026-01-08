`timescale 1ns/1ps

module spi_slave_interface #(
  parameter integer XLEN     = 64,
  parameter integer DATA_W   = 64,
  parameter integer ADDR14_W = 14
)(
  input  wire                 I_CLK,
  input  wire                 I_RSTN,
  input  wire                 I_SS_N,
  input  wire                 I_MOSI,
  output reg                  O_MISO,

  // RAM interface
  output wire                 ram_we,    
  output wire                 ram_cs,
  output reg  [ADDR14_W-1:0]  ram_addr,
  output wire [XLEN-1:0]      ram_wdata, 
  input  wire [XLEN-1:0]      ram_rdata
);

  assign ram_cs = ~I_SS_N;

  // FSM States
  localparam [1:0] S_IDLE=2'd0, S_HDR=2'd1, S_DATA=2'd2;
  reg [1:0] state;

  // Logic
  reg [15:0] hdr_shift;
  reg [4:0]  hdr_cnt;
  reg        is_write;
  wire [15:0] hdr_assembled = {hdr_shift[14:0], I_MOSI};
  
  reg [DATA_W-1:0] rx_shift; 
  reg [DATA_W-1:0] tx_shift; 
  reg [6:0]        bit_cnt;

  // ---------------------------------------------------------
  // 1. COMBINATORIAL WRITE LOGIC (The Fix)
  // ---------------------------------------------------------
  // Assert WE immediately when we are at the last bit (bit_cnt==0) 
  // of the DATA state, and it is a write operation.
  assign ram_we = (state == S_DATA && is_write && bit_cnt == 7'd0 && !I_SS_N);

  // Assemble the Write Data immediately using the current MOSI bit
  // so it is ready for the upcoming clock edge.
  assign ram_wdata = {rx_shift[DATA_W-2:0], I_MOSI};
  // ---------------------------------------------------------

  always @(posedge I_CLK or negedge I_RSTN) begin
    if (!I_RSTN) begin
      state     <= S_IDLE;
      hdr_shift <= 0;
      hdr_cnt   <= 0;
      is_write  <= 0;
      ram_addr  <= 0;
      // ram_we / ram_wdata removed from reset (now wires)
      rx_shift  <= 0;
      tx_shift  <= 0;
      bit_cnt   <= 0;
    end else begin
      if (I_SS_N) begin
        state <= S_IDLE;
      end else begin
        case (state)
          S_IDLE: begin
            state   <= S_HDR;
            hdr_cnt <= 5'd15;
          end

          S_HDR: begin
            hdr_shift <= {hdr_shift[14:0], I_MOSI};
            
            // Pre-fetch Address Logic
            if (hdr_cnt == 5'd1) begin
               ram_addr <= hdr_assembled[14:1];
            end

            if (hdr_cnt != 5'd0) begin
              hdr_cnt <= hdr_cnt - 1;
            end else begin
              is_write <= hdr_assembled[15];
              ram_addr <= hdr_assembled[14:1]; 
              state    <= S_DATA;
              bit_cnt  <= DATA_W - 1;
              if (!hdr_assembled[15]) tx_shift <= ram_rdata;
            end
          end

          S_DATA: begin
            if (is_write) begin
               rx_shift <= {rx_shift[DATA_W-2:0], I_MOSI};
            end

            // Burst Read Pre-fetch
            if (!is_write && bit_cnt == 32) begin
               ram_addr <= ram_addr + 1;
            end

            if (bit_cnt != 0) begin
               bit_cnt <= bit_cnt - 1;
            end else begin
               // --- WORD COMPLETE ---
               bit_cnt <= DATA_W - 1;

               if (is_write) begin
                  // WRITE MODE:
                  // The 'ram_we' wire is ALREADY High right now (combinatorial).
                  // The RAM will capture the write on this clock edge.
                  
                  // We only need to increment address for the NEXT word.
                  ram_addr <= ram_addr + 1; 
               end else begin
                  // READ MODE:
                  tx_shift <= ram_rdata;
               end
            end
          end
        endcase
      end
    end
  end

  // MISO Drive (Negedge) - Unchanged
  always @(negedge I_CLK or negedge I_RSTN) begin
    if (!I_RSTN) O_MISO <= 0;
    else begin
       if (I_SS_N || state != S_DATA || is_write) O_MISO <= 0;
       else begin
          O_MISO   <= tx_shift[DATA_W-1];
          tx_shift <= {tx_shift[DATA_W-2:0], 1'b0};
       end
    end
  end

endmodule