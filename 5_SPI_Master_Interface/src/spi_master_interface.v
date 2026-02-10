`timescale 1ns/1ps

module spi_master_interface #(
  parameter ADDR_BYTE_W = 17,
  parameter DATA_W      = 64
)(
  input  wire                   I_CLK,
  input  wire                   I_RSTN,

  input  wire                   start,
  input  wire                   abort,
  input  wire                   is_write,
  input  wire [ADDR_BYTE_W-1:0] byte_addr,   // 8B aligned for DATA_W=64
  input  wire [15:0]            burst_len,   // number of DATA_W words; 0 treated as 1

  input  wire [DATA_W-1:0]      wdata,
  output reg  [DATA_W-1:0]      rdata,
  output reg                    rvalid,

  output reg                    busy,
  output reg                    done,

  output reg                    O_SS,         // active low
  output reg                    O_MOSI,
  input  wire                   I_MISO
);

  localparam integer BYTES_PER_WORD = DATA_W / 8;
  localparam [6:0]   BITCNT_MAX     = DATA_W - 1;

  localparam [2:0]
    S_IDLE    = 3'd0,
    S_CS_LOW  = 3'd1,
    S_HDR     = 3'd2,
    S_WDATA   = 3'd3,
    S_RDATA   = 3'd4,
    S_CS_HIGH = 3'd5;

  // ------------------------------------------------------------
  // State / registers
  // ------------------------------------------------------------
  reg [2:0] state, next_state;

  reg [15:0] words_left, next_words_left;
  reg [4:0]  hdr_cnt,    next_hdr_cnt;
  reg [6:0]  bit_cnt;
  reg [7:0]  next_bit_cnt;

  reg [ADDR_BYTE_W:0] addr_b,     next_addr_b;
  reg [15:0]            hdr_shift,  next_hdr_shift;

  reg [DATA_W-1:0]      tx_shift,   next_tx_shift;
  reg [DATA_W-1:0]      rx_shift,   next_rx_shift;

  // Skip first RDATA cycle (dummy turnaround)
  reg                   skip_sample, next_skip_sample;

  // Next registered outputs
  reg [DATA_W-1:0]       next_rdata;
  reg                    next_rvalid;
  reg                    next_busy;
  reg                    next_done;
  reg                    next_O_SS;
  reg                    next_O_MOSI;

  // Header format (MSB-first):
  // [15]=RW, [14:1]=byte_addr[16:3], [0]=0 (dummy)
  wire [14:0] hdr_init = {byte_addr[16:3], 1'b0};

  // ------------------------------------------------------------
  // Combinational next-state logic
  // ------------------------------------------------------------
  always @* begin
    next_state       = state;

    next_words_left  = words_left;
    next_hdr_cnt     = hdr_cnt;
    next_bit_cnt     = bit_cnt;

    next_addr_b      = addr_b;
    next_hdr_shift   = hdr_shift;

    next_tx_shift    = tx_shift;
    next_rx_shift    = rx_shift;

    next_skip_sample = skip_sample;

    next_rdata       = rdata;
    next_rvalid      = 1'b0;
    next_done        = 1'b0;

    next_O_SS        = O_SS;
    next_O_MOSI      = O_MOSI;

    next_busy        = (next_state != S_IDLE);

    case (state)

      S_IDLE: begin
        next_O_SS        = 1'b1;
        next_O_MOSI      = 1'b0;
        next_busy        = 1'b0;
        next_skip_sample = 1'b0;

        if (start) begin
          next_addr_b     = byte_addr;
          next_words_left = (burst_len == 16'd0) ? 16'd1 : burst_len;

          next_hdr_shift  = hdr_init;
          next_hdr_cnt    = 5'd14;

          next_state      = S_CS_LOW;
          next_busy       = 1'b1;
        end
      end

      S_CS_LOW: begin
        next_O_SS        = 1'b0;
        next_O_MOSI      = is_write;
        next_state       = S_HDR;
        next_busy        = 1'b1;
        next_skip_sample = 1'b0;
      end

      S_HDR: begin
        next_O_SS   = 1'b0;
        next_O_MOSI = hdr_shift[14];
        next_busy   = 1'b1;

        next_hdr_shift = {hdr_shift[13:0], 1'b0};

        if (hdr_cnt != 5'd0) begin
          next_hdr_cnt = hdr_cnt - 5'd1;
        end else begin
          

          if (is_write) begin
            next_tx_shift    = wdata;
            next_state       = S_WDATA;
            next_skip_sample = 1'b0;
            next_bit_cnt = BITCNT_MAX + 1;
          end else begin
            next_rx_shift    = {DATA_W{1'b0}};
            next_state       = S_RDATA;
            next_skip_sample = 1'b1;   // one dummy cycle in RDATA
            next_bit_cnt = BITCNT_MAX;
          end
        end
      end

      S_WDATA: begin
        next_O_SS   = 1'b0;
        next_O_MOSI = tx_shift[DATA_W-1];
        next_busy   = 1'b1;


            next_tx_shift = {tx_shift[DATA_W-2:0], 1'b0};
    
            if (bit_cnt != 7'd0) begin
              next_bit_cnt = bit_cnt - 7'd1;
            end else begin
              if (words_left == 16'd1) begin
                next_state = S_CS_HIGH;
                next_O_SS        = 1'b1;
                next_O_MOSI      = 1'b0;
                next_done        = 1'b1;
                next_busy        = 1'b0;
              end else begin
                next_words_left = words_left - 16'd1;
                next_addr_b     = addr_b + BYTES_PER_WORD[ADDR_BYTE_W-1:0];
    
                next_tx_shift   = wdata;
                next_bit_cnt    = BITCNT_MAX+1;
                next_state      = S_WDATA;
              end
            end
          end
      S_RDATA: begin
        next_O_SS   = 1'b0;
        next_O_MOSI = 1'b0;
        next_busy   = 1'b1;

        if (abort) begin
          next_state = S_CS_HIGH;
          next_O_SS  = 1'b1;
        end
        else if (skip_sample) begin
          next_skip_sample = 1'b0;   // dummy turnaround
          next_rx_shift    = rx_shift;
          next_bit_cnt     = bit_cnt;
        end else begin
          next_rx_shift = {rx_shift[DATA_W-2:0], I_MISO};

          if (bit_cnt != 7'd0) begin
            next_bit_cnt = bit_cnt - 7'd1;
          end else begin
            next_rdata  = {rx_shift[DATA_W-2:0], I_MISO};
            next_rvalid = 1'b1;

            if (words_left == 16'd1) begin
              next_state = S_CS_HIGH;
              next_O_SS        = 1'b1;
              next_O_MOSI      = 1'b0;
              next_done        = 1'b1;
              next_busy        = 1'b0;
              next_skip_sample = 1'b0;
            end else begin
              next_words_left  = words_left - 16'd1;
              next_addr_b      = addr_b + BYTES_PER_WORD[ADDR_BYTE_W-1:0];
              next_bit_cnt     = BITCNT_MAX;
              next_state       = S_RDATA;
              next_skip_sample = 1'b0;
            end
          end
        end
      end

      S_CS_HIGH: begin
        next_O_SS        = 1'b1;
        next_O_MOSI      = 1'b0;
        next_done        = 1'b0;
        next_state       = S_IDLE;
        next_busy        = 1'b0;
        next_skip_sample = 1'b0;
      end

      default: begin
        next_state       = S_IDLE;
        next_O_SS        = 1'b1;
        next_O_MOSI      = 1'b0;
        next_busy        = 1'b0;
        next_skip_sample = 1'b0;
      end

    endcase
  end

  // ------------------------------------------------------------
  // Sequential register update
  // ------------------------------------------------------------
  always @(posedge I_CLK or negedge I_RSTN) begin
    if (!I_RSTN) begin
      state       <= S_IDLE;

      words_left  <= 16'd0;
      hdr_cnt     <= 5'd0;
      bit_cnt     <= 7'd0;

      addr_b      <= {ADDR_BYTE_W{1'b0}};
      hdr_shift   <= 16'd0;

      tx_shift    <= {DATA_W{1'b0}};
      rx_shift    <= {DATA_W{1'b0}};

      rdata       <= {DATA_W{1'b0}};
      rvalid      <= 1'b0;

      busy        <= 1'b0;
      done        <= 1'b0;

      O_SS        <= 1'b1;
      O_MOSI      <= 1'b0;

      skip_sample <= 1'b0;

    end else begin
      state       <= next_state;

      words_left  <= next_words_left;
      hdr_cnt     <= next_hdr_cnt;
      bit_cnt     <= next_bit_cnt;

      addr_b      <= next_addr_b;
      hdr_shift   <= next_hdr_shift;

      tx_shift    <= next_tx_shift;
      rx_shift    <= next_rx_shift;

      rdata       <= next_rdata;
      rvalid      <= next_rvalid;

      busy        <= next_busy;
      done        <= next_done;

      O_SS        <= next_O_SS;
      O_MOSI      <= next_O_MOSI;

      skip_sample <= next_skip_sample;
    end
  end

endmodule
