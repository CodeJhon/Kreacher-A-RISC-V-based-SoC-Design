`include "INIT_MEM_CONSTANTS.vh"
`timescale 1ns/1ps

module Memory_controller #(
    parameter ADDR_BYTE_W = 17,
    parameter XLEN = 64,     // Full data width
    parameter IXLEN = 32,     // Instruction width
    parameter BURST_LEN = 16'd1024
)(
    // -------------------------
    // Init controller interface
    // -------------------------
    input [2:0] state,
    input burst_dim,
    input PRAM_in,
    input PRAM_addr_type,
    input SPI_rdata_type,
    input ROM_addr_type,
    input [ADDR_BYTE_W-1:0] INITIALIZATION_addr,
    input mem_init,
    input first_fetch,
    output enable,

    // -------------------------
    // Core interface
    // -------------------------
    input EMCB,
    input [ADDR_BYTE_W-1:0] EMAB,
    input [XLEN-1:0] EMDB_write,
    input valid_instr_fetch,
    input valid_data_read,
    input valid_data_write,
    output [XLEN-1:0] EMDB_read,
    output pause_core,

    // 32-bit core instruction interface
    input [ADDR_BYTE_W-1:0] EIAB,
    output [IXLEN-1:0] EIB,

    // -------------------------
    // SPI interface
    // -------------------------
    input rvalid,
    input [XLEN-1:0] rdata,  
    input busy,
    input done,
    output start,
    output is_write_SPI,
    output [ADDR_BYTE_W-1:0] byte_addr,
    output [ADDR_BYTE_W-1:0] burst_len,
    output [XLEN-1:0] wdata,

    // -------------------------
    // Memory interface
    // -------------------------
    input [XLEN-1:0] data_read,
    input [IXLEN-1:0] instruction_read,
    input init_done,
    output addr_data_valid,
    output addr_inst_valid,
    output [XLEN-1:0] inst_data_write,
    output [ADDR_BYTE_W-1:0] data_read_write_adr,
    output [ADDR_BYTE_W-1:0] inst_fetch_adr,
    output is_write_PRAM
);

    // -------------------------
    // Internal signals
    // -------------------------
    reg [1:0] mem_sel;
    wire [ADDR_BYTE_W-1:0] mem_address;
    wire [ADDR_BYTE_W-1:0] EMAB_rom;
    wire [ADDR_BYTE_W-1:0] EMAB_pram;
    wire [XLEN-1:0] ROM_EMBD_read;
    wire [XLEN-1:0] initialize_rdata;
    wire [XLEN-1:0] PRAM_EMBD_read;
    wire EMDB_write_w;
    wire instantiation_state;
    wire addr_data_valid_c;
    
    // -------------------------
    // Core signals
    // -------------------------
    assign pause_core  = (state != `S_SUCCESS) || busy;
    assign EIB         = instruction_read;
    assign EMDB_read   = mem_sel ? ROM_EMBD_read : PRAM_EMBD_read;
    assign addr_data_valid_c = valid_data_read || valid_data_write;

    // -------------------------
    // Memory selection
    // -------------------------
    always @(*) begin //to differntiate internal or external memory access
        if (addr_data_valid_c)
            mem_sel = (EMAB[16:15] != 2'b00);
        else
            mem_sel = 1'b0;
    end
    assign mem_address   = EMAB[16:0];
    assign EMAB_rom      = mem_sel ? mem_address : 0;
    assign EMAB_pram     = mem_sel ? 0 : mem_address;
    assign EMDB_write_w  = mem_sel ? 0 : EMDB_write;
    assign ROM_EMBD_read = SPI_rdata_type ? rdata : 0;
    assign initialize_rdata = SPI_rdata_type ? 0 : rdata;
    assign PRAM_EMBD_read   = data_read;
    assign instantiation_state = (state == `S_WAIT) || (state == `S_START);

    // -------------------------
    // Init controller
    // -------------------------
    assign enable       = mem_init && rvalid;

    // -------------------------
    // SPI interface
    // -------------------------
    assign byte_addr     = ROM_addr_type ? EMAB_rom : INITIALIZATION_addr;
    assign is_write_SPI  = instantiation_state ? 1'b0 : (EMCB && mem_sel);
    assign start         = (state == `S_START) || mem_sel;
    assign burst_len     = burst_dim ? 16'd1 : BURST_LEN;
    assign wdata         = mem_sel ? EMDB_write : 0;

    // -------------------------
    // Memory interface
    // -------------------------
    assign inst_data_write       = PRAM_in ? EMDB_write_w : initialize_rdata;
    assign data_read_write_adr  = PRAM_addr_type ? EMAB_pram : INITIALIZATION_addr;
    assign inst_fetch_adr       = EIAB;
    assign is_write_PRAM        = mem_init || (~mem_sel && EMCB);
    assign addr_data_valid      = mem_init || addr_data_valid_c;
    assign addr_inst_valid      = valid_instr_fetch || first_fetch;

endmodule
