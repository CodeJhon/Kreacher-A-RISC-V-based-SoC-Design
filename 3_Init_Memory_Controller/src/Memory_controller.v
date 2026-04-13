// =============================================================================
// File        : Memory_controller.v
// Author      : Sanjai Palanisamy
// Email       : sanjai.palanisamy171@gmail.com
// Description :
//   This module manages memory accesses between the core, internal PRAM, and external 
// SPI ROM by controlling initialization, load/store operations, instruction fetches, 
// and masked partial read/write transactions.
// =============================================================================
`include "INIT_MEM_CONSTANTS.vh"

module Memory_controller #(
    parameter ADDR_BYTE_W       = 17,
    parameter ADDR_INIT_W       = 16,
    parameter XLEN              = 64,     // Full data width
    parameter IXLEN             = 32,     // Instruction width
    parameter BURST_LENGTH      = 16'd4096
)(
     // ================= Init controller interface =================
    input clk,
    input reset_n,
    input interrupt,
    input [3:0] state,
    input burst_dim,
    input PRAM_in,
    input PRAM_addr_type,
    input [1:0]SPI_rdata_type,
    input ROM_addr_type,
    input [ADDR_BYTE_W-1:0] INITIALIZATION_addr,
    input mem_init,
    input pre_fetch,
    input [1:0] write_enable_state,
    input write_state,
    output masking_enabled,
    output enable,
    output partial_write_done,
    output partial_read_done,

     // ================= Core interface =================
    input EMCB,
    input [XLEN-1:0] EMAB,
    input [XLEN-1:0] EMDB_write,
    input valid_instr_fetch,
    input valid_data_read,
    input valid_data_write,
    input [XLEN-1:0] EMCB_mask,
    output [XLEN-1:0] EMDB_read,
    output pause_request_scheduler,
    output pause_request_initialization,
    output pause_request_load_store,
    output pause_request_partial_store,

    // 32-bit core instruction interface
    input [ADDR_BYTE_W-1:0] EIAB,
    output [IXLEN-1:0] EIB,

     // ================= SPI interface =================
    input rvalid,
    input [XLEN-1:0] rdata,  
    input busy,
    input done,
    output reg start,
    output reg is_write_SPI,
    output [ADDR_BYTE_W-1:0] byte_addr,
    output [ADDR_INIT_W-1:0] burst_len,
    output reg [XLEN-1:0] wdata,
    output init_abort,

     // ================= Memory interface =================
    input [XLEN-1:0] data_read,
    input [IXLEN-1:0] instruction_read,
    input pause_to_schedule,
    output addr_data_valid,
    output addr_inst_valid,
    output [XLEN-1:0] inst_data_write,
    output [ADDR_BYTE_W-1:0] data_read_write_adr,
    output [ADDR_BYTE_W-1:0] inst_fetch_adr,
    output is_write_PRAM,
    output [XLEN-1:0] init_internal_mask
);

     // ================= Internal signals =================
    reg mem_sel_q;
    reg [XLEN-1:0] ROM_EMBD_read;
    reg [XLEN-1:0] initialize_rdata;
    reg [XLEN-1:0] partial_read_d;
    reg [XLEN-1:0] partial_read_q;
    reg [XLEN-1:0]internal_wdata;
    reg [XLEN-1:0]ext_wdata;
    reg [XLEN-1:0] ext_EMCB_mask;
    reg [XLEN-1:0] internal_EMCB_mask;
    wire [XLEN-1:0] default_mask;
    wire [ADDR_BYTE_W-1:0] mem_address;
    wire [ADDR_BYTE_W-1:0] EMAB_rom;
    wire [ADDR_BYTE_W-1:0] EMAB_pram;
    wire [XLEN-1:0] PRAM_EMBD_read;
    wire addr_data_valid_c;
    wire addr_pmem_data_valid_c;
    wire valid_instr_fetch_internal;
    wire pram_write_core;
    wire pram_write_init;
    wire full_write;
    wire full_read;
    wire ext_addr_hit;
    wire first_fetching;
    wire normal_write_enable;
    wire mem_sel;
    wire [XLEN-1:0] masked_wdata;

     // ================= local parameters =================
    localparam EXT_ADDR_BITS = 3'b000;

     // ================= Core signals =================
    assign valid_instr_fetch_internal   = (state == `S_NORMAL_OP) & ((valid_instr_fetch) & (!(done ? 1'b0 : (busy | mem_sel)))); 
    assign pause_request_initialization = state == `S_FIRST_FETCH || state == `S_WAIT || state == `S_START;
    assign pause_request_load_store     = (state == `S_PARTIAL_STORE_DONE)? 1'b0 : (done ? 1'b0 : (busy | mem_sel));
    assign pause_request_partial_store  = state == `S_PARTIAL_READ || state == `S_APPLY_MASK || state == `S_PARTIAL_WRITE;
    
    reg tick_for_internal_load;
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n)
            tick_for_internal_load <= 1'b1;
        else begin
            if(state == `S_NORMAL_OP)begin
                if((tick_for_internal_load == 1'b1) && (mem_sel == `INTERNAL) && (valid_data_read))
                    tick_for_internal_load <= 1'b0;
                else
                    tick_for_internal_load <= 1'b1;
            end
        end
    end
    reg pause_to_internal;
    always @( * ) begin
        pause_to_internal = 1'b0;
        if(state == `S_NORMAL_OP)
            pause_to_internal = (tick_for_internal_load & valid_data_read & (mem_sel == `INTERNAL));
    end
    assign pause_request_scheduler      = pause_to_schedule | pause_to_internal;

    assign EIB                          = instruction_read;
    assign EMDB_read                    = mem_sel_q ? ROM_EMBD_read : PRAM_EMBD_read;
    assign addr_data_valid_c            = valid_data_read | valid_data_write;
    assign addr_pmem_data_valid_c       = (state == `S_FIRST_FETCH) ? 1'b0: (~mem_sel) & addr_data_valid_c;

    // ================= Memory selection =================
    // Decide whether core access targets external SPI ROM or internal PRAM.
    // External access stalls core until SPI completes.
    

    assign ext_addr_hit = (EMAB[17:15] != EXT_ADDR_BITS);

    //to differntiate internal or external memory access

    assign mem_sel = addr_data_valid_c & ext_addr_hit;

    always@(posedge clk, negedge reset_n)begin
        if(!reset_n)begin
            mem_sel_q <= 1'b0;
        end
        else begin
            mem_sel_q <= mem_sel;
        end
    end

    assign mem_address         = EMAB[ADDR_BYTE_W-1:0];
    assign EMAB_rom            = mem_sel ? mem_address : {ADDR_BYTE_W{1'b0}};
    assign EMAB_pram           = mem_sel ? ((state == `S_NORMAL_OP)? mem_address: {ADDR_BYTE_W{1'b0}}) : mem_address;
    

    always@( * )begin
        ROM_EMBD_read          = {XLEN{1'b0}};
        initialize_rdata       = {XLEN{1'b0}};
        partial_read_d         = {XLEN{1'b0}};
        case(SPI_rdata_type)
            `INITIALIZATION_R      : begin
                initialize_rdata  = rdata;
            end
            `LOAD_STORE_OPERATION_R: begin
                ROM_EMBD_read     = rdata;
            end
            `PARTIAL_READ          : begin
                 partial_read_d    = rdata;
            end
        endcase
    end

    always@(posedge clk or negedge reset_n) begin
        if(!reset_n) 
            partial_read_q <= {XLEN{1'b0}};
        else if(state == `S_NORMAL_OP)         
            partial_read_q <= {XLEN{1'b0}}; //apply enable
        else if(state == `S_PARTIAL_READ)   
            partial_read_q <= partial_read_d;
        else                                
            partial_read_q <= partial_read_q; //hold
    end

    assign default_mask        = 64'hffff_ffff_ffff_ffff;
    assign PRAM_EMBD_read      = data_read;
    //FOR READING IT SHOULD BE HIGH
    assign full_write          = &(EMCB_mask);
    assign full_read           = !EMCB;
    assign init_internal_mask = mem_init ? default_mask : internal_EMCB_mask;

    always@( * )begin
        ext_EMCB_mask      = default_mask;
        internal_EMCB_mask = default_mask;
        case(mem_sel)
            1'b0: internal_EMCB_mask = EMCB_mask;
            1'b1: ext_EMCB_mask      = EMCB_mask;
        endcase
    end

    // ================= Init controller =================
    assign enable              = mem_init && rvalid;
    assign masking_enabled     = (ext_EMCB_mask != default_mask) && EMCB;
    assign partial_write_done  = done & (!rvalid);
    assign partial_read_done   = done & rvalid;

    // ================= SPI INTERFACE =================
    assign byte_addr          = ROM_addr_type ? EMAB_rom : INITIALIZATION_addr;

    assign normal_write_enable = EMCB & mem_sel;
    always@( * )begin
        is_write_SPI = 1'b0;
        case(write_enable_state)
            `LOAD_STORE_OPERATION_W : is_write_SPI = normal_write_enable;
            `INITIALIZATION_W       : is_write_SPI = 1'b0; //no writing to external
            `PARTIAL_WRITE          : is_write_SPI = 1'b1;
        endcase
    end

    always @( * ) begin
    start = 1'b0;  // default
    case (state)
        `S_IDLE,
        `S_WAIT,
        `S_FIRST_FETCH,
        `S_APPLY_MASK,
        `S_PARTIAL_STORE_DONE:
            start = 1'b0;

        `S_START,
        `S_PARTIAL_WRITE,
        `S_PARTIAL_READ:
            start = 1'b1;

        `S_NORMAL_OP: begin
            if ((full_read || full_write) && mem_sel)
                start = 1'b1;
            else
                start = 1'b0;
            end
        endcase
    end

    //To make it pulse instead of level sensitive signal
    assign init_abort         = interrupt && (state == `S_WAIT);
    assign burst_len          = burst_dim ? { {(ADDR_INIT_W-4){1'b0}}, 4'd1 } : BURST_LENGTH;


    always@( * )begin
        ext_wdata       = {XLEN{1'b0}};
        internal_wdata  = {XLEN{1'b0}};
        case(mem_sel)
            `INTERNAL : internal_wdata = EMDB_write;
            `EXTERNAL : ext_wdata      = EMDB_write;
        endcase
    end
    assign masked_wdata = (ext_wdata & EMCB_mask) | (partial_read_q & ~EMCB_mask); //partial masked data

    always@( * )begin
        wdata = {XLEN{1'b0}};
        case(write_state)
            `NORMAL_WDATA : wdata = ext_wdata;
            `MASKED_WDATA : wdata = masked_wdata;
        endcase
    end

    // =================  Memory interface =================
    assign first_fetching      = state == `S_FIRST_FETCH;
    assign inst_data_write     = PRAM_in ? internal_wdata : initialize_rdata;
    assign data_read_write_adr = PRAM_addr_type ? EMAB_pram : INITIALIZATION_addr;
    assign inst_fetch_adr      = first_fetching ? {{(ADDR_BYTE_W-4){1'b0}}, 4'd8} :  EIAB;
    assign pram_write_core     = EMCB & !mem_sel;
    assign pram_write_init     = mem_init;
    assign is_write_PRAM       = first_fetching ? 1'b0 : (pram_write_core | pram_write_init);
    assign addr_data_valid     = mem_init | addr_pmem_data_valid_c;
    assign addr_inst_valid     = valid_instr_fetch_internal | pre_fetch;
endmodule

