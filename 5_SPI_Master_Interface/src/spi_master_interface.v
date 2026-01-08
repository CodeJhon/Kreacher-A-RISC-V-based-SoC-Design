`timescale 1ns/1ps

module spi_master_interface #(
  parameter ADDR_BYTE_W = 17,     // byte address width
  parameter DATA_W      = 64      // data width: 32 or 64 bits
)(
  input  wire                   I_CLK,
  input  wire                   I_RSTN,

  // control
  input  wire                   start,
  input  wire                   is_write,          // 1=write, 0=read
  input  wire [ADDR_BYTE_W-1:0] byte_addr,         // must be aligned to DATA_W/8
  input  wire [15:0]            burst_len,         // number of DATA_W-bit words (>=1)

  // data
  input  wire [DATA_W-1:0]      wdata,             // provide per word for burst
  output reg  [DATA_W-1:0]      rdata,
  output reg                    rvalid,

  output reg                    busy,
  output reg                    done,

  // SPI pins
  output reg                    O_SS,              // active low
  output reg                    O_MOSI,            // master out
  input  wire                   I_MISO             // master in
);

  // -------------------------------------------------
  // Derived parameters (from DATA_W)
  // -------------------------------------------------
  // Number of bytes per word (4 for 32-bit, 8 for 64-bit)
  localparam integer BYTES_PER_WORD = DATA_W / 8;
  // Max bit index for one data word (31 or 63)
  localparam [6:0] BITCNT_MAX     = DATA_W - 1;

  // -------------------------------------------------
  // FSM encoding
  // -------------------------------------------------
  localparam [2:0]
    S_IDLE    = 3'd0,          // Idle : wait for start
    S_CS_LOW  = 3'd1,          // drive O_SS low
    S_HDR     = 3'd2,          // send 16-bit header
    S_WDATA   = 3'd3,          // write-data phase
    S_RDATA   = 3'd4,          // read-data phase
    S_CS_HIGH = 3'd5;          // drive O_SS high

  reg [2:0] state, state_next;

  // counters / registers
  reg [15:0] words_left, words_left_next;   // words remaining in the burst
  reg [4:0]  hdr_cnt,    hdr_cnt_next;      // 16-bit header counter (15..0)
  reg [6:0]  bit_cnt,    bit_cnt_next;      // data bit counter (covers 0..63)

  reg [ADDR_BYTE_W-1:0] addr_b, addr_b_next;  // current byte address
  reg [15:0]            hdr_shift, hdr_shift_next;  // header shift register

  reg [DATA_W-1:0]      tx_shift;        // transmit (TX) shift register
  reg [DATA_W-1:0]      rx_shift, rx_shift_next;    // receive (RX) shift register

  wire is_burst  = (burst_len > 16'd1);
  wire dummy_bit = is_burst ? 1'b1 : 1'b0;

  // -------------------------------------------------
  // Combinational next-state logic
  // -------------------------------------------------
  always @* begin
    // defaults
    state_next      = state;
    words_left_next = words_left;
    addr_b_next     = addr_b;
    hdr_cnt_next    = hdr_cnt;
    bit_cnt_next    = bit_cnt;
    hdr_shift_next  = hdr_shift;
    rx_shift_next   = rx_shift;

    done         = 1'b0;

    case (state)
      S_IDLE: begin
        if (start) begin
          addr_b_next     = byte_addr;
          // treat burst_len==0 as 1 word
          words_left_next = (burst_len == 16'd0) ? 16'd1 : burst_len;
          // header: {R/W, ADDR[13:0], DUMMY}
          // NOTE: still fixed 16-bit header; only low 14 bits of byte_addr are encoded.
          hdr_shift_next  = {is_write, byte_addr[16:3], dummy_bit}; // 1+14+1 = 16
          hdr_cnt_next    = 5'd15;
          state_next      = S_CS_LOW;
        end
      end

      S_CS_LOW: begin
        // one cycle to assert CS low, then start shifting header
        state_next = S_HDR;
      end

      S_HDR: begin
        // when header shift counter reaches zero, move to data phase
        if (hdr_cnt == 5'd0) begin
          bit_cnt_next = BITCNT_MAX;            // DATA_W-1
          state_next   = is_write ? S_WDATA : S_RDATA;
        end
      end

      S_WDATA: begin
        // one data word completed
        if (bit_cnt == 7'd0) begin
          if (words_left == 16'd1) begin
            state_next = S_CS_HIGH;
          end else begin
            // next DATA_W-bit word: bump byte address by BYTES_PER_WORD
            addr_b_next     = addr_b + BYTES_PER_WORD[ADDR_BYTE_W-1:0];
            words_left_next = words_left - 16'd1;
            bit_cnt_next    = BITCNT_MAX;
            state_next      = S_WDATA;     // continue burst
          end
        end
      end

      S_RDATA: begin
        if (bit_cnt == 7'd0) begin
          if (words_left == 16'd1) begin
            state_next = S_CS_HIGH;
          end else begin
            addr_b_next     = addr_b + BYTES_PER_WORD[ADDR_BYTE_W-1:0];
            words_left_next = words_left - 16'd1;
            bit_cnt_next    = BITCNT_MAX;
            state_next      = S_RDATA;
          end
        end
      end

      S_CS_HIGH: begin
        done    = 1'b1;
        state_next = S_IDLE;
      end

      default: begin
        state_next = S_IDLE;
      end
    endcase
  end

  // -------------------------------------------------
  // Sequential: posedge clock
  //  - advance FSM/counters
  //  - sample MISO into rx_shift
  //  - load tx_shift when entering S_WDATA (no shifting here)
  // -------------------------------------------------
  always @(posedge I_CLK or negedge I_RSTN) begin
    if (!I_RSTN) begin
      state      <= S_IDLE;
      words_left <= 16'd0;
      addr_b     <= {ADDR_BYTE_W{1'b0}};
      hdr_cnt    <= 5'd0;
      bit_cnt    <= 7'd0;
      hdr_shift  <= 16'd0;
      rx_shift   <= {DATA_W{1'b0}};
      rdata      <= {DATA_W{1'b0}};
      rvalid     <= 1'b0;
      busy       <= 1'b0;
      tx_shift   <= {DATA_W{1'b0}};
    end else begin
      state      <= state_next;
      words_left <= words_left_next;
      addr_b     <= addr_b_next;
      hdr_cnt    <= hdr_cnt_next;
      bit_cnt    <= bit_cnt_next;
      hdr_shift  <= hdr_shift_next;
      rx_shift   <= rx_shift_next;

      busy       <= (state_next != S_IDLE);
      rvalid     <= 1'b0;

      case (state)
        S_HDR: begin
          // shift header MSB-first on each posedge (sampling edge)
          hdr_shift <= {hdr_shift[14:0], 1'b0};
          if (hdr_cnt != 5'd0) hdr_cnt <= hdr_cnt - 5'd1;
        end

        S_RDATA: begin
          // sample MISO on posedge, MSB-first
          rx_shift <= {rx_shift[DATA_W-2:0], I_MISO};
          if (bit_cnt != 7'd0) bit_cnt <= bit_cnt - 7'd1;
          if (bit_cnt == 7'd0) begin
            // full DATA_W-bit word received
            rdata  <= {rx_shift[DATA_W-2:0], I_MISO};
            rvalid <= 1'b1;
          end
        end

        S_WDATA: begin
          // only count bits here; actual MOSI shift happens on negedge
          if (bit_cnt != 7'd0) bit_cnt <= bit_cnt - 7'd1;
        end
      endcase

      // Load tx_shift when:
      //  - just entering S_WDATA from S_HDR (first word), or
      //  - staying in S_WDATA and bit_cnt wrapped to BITCNT_MAX (next burst word)
      if ((state == S_HDR    && state_next == S_WDATA) ||
          (state == S_WDATA && bit_cnt == 7'd0 && state_next == S_WDATA)) begin
        tx_shift <= wdata;  // upstream must provide the next word in time
      end
    end
  end

  // -------------------------------------------------
  // Sequential: negedge clock
  //  - drive O_SS / O_MOSI
  //  - shift tx_shift for write on each negedge during S_WDATA
  // -------------------------------------------------
  always @(negedge I_CLK or negedge I_RSTN) begin
    if (!I_RSTN) begin
      O_SS   <= 1'b1;                 // idle deasserted
      O_MOSI <= 1'b0;
    end else begin
      case (state)
        S_IDLE: begin
          O_SS   <= 1'b1;
          O_MOSI <= 1'b0;
        end

        S_CS_LOW: begin
          O_SS <= 1'b0;
        end

        S_HDR: begin
          O_SS   <= 1'b0;
          O_MOSI <= hdr_shift[15];    // send header MSB first
        end

        S_WDATA: begin
          O_SS   <= 1'b0;
          O_MOSI <= tx_shift[DATA_W-1];
          // shift on negedge so peer samples stable data on next posedge
          tx_shift <= {tx_shift[DATA_W-2:0], 1'b0};
        end

        S_RDATA: begin
          O_SS   <= 1'b0;
          O_MOSI <= 1'b0;             // don't care during read data phase
        end

        S_CS_HIGH: begin
          O_SS   <= 1'b1;
          O_MOSI <= 1'b0;
        end

        default: begin
          O_SS   <= 1'b1;
          O_MOSI <= 1'b0;
        end
      endcase
    end
  end

endmodule


