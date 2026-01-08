module kreacher_top #(
    parameter ADDR_BYTE_W                 = 17,
    parameter XLEN                        = 64,
    parameter IXLEN                       = 32,
    parameter [ADDR_BYTE_W-1:0] BASE_ADDR = 17'h00000,  // init start address
    parameter [ADDR_BYTE_W-1:0] MEM_LIMIT = 17'h01FFF,   // MEM_LIMIT is an exclusive upper bound (init runs while addr < MEM_LIMIT)
    parameter [ADDR_BYTE_W-1:0] INCR      = 17'd8,
    parameter BURST_LEN                   = 16'd1024
)(
    `ifndef SYNTHESIS 
        output           commit_valid,
        output [XLEN-1:0]   commit_PC,
        output [31:0]   commit_instruction,
        output [4:0]     commit_rd_addr,
        output [XLEN-1:0]   commit_rd_value,
    `endif

    input I_CLK,
    input I_A_RESET_L,
                                                                                                               
    output O_SS,
    output O_MOSI,
    input O_MISO,
    input I_INTR_H,
    output O_INTR_ACK
);

//temp wires
wire clk;
assign clk = I_CLK;
wire reset;
assign reset = ~ I_A_RESET_L;

//core 
wire  EMCB;
wire  [ADDR_BYTE_W-1:0] EMAB;
wire  [XLEN-1:0] EMDB_write;
wire valid_data_read;
wire valid_data_write;
wire valid_instr_fetch;
wire  [ADDR_BYTE_W-1:0] EIAB;

wire  [XLEN-1:0] EMDB_read;
wire  pause_core;
wire  [IXLEN-1:0] EIB;

//Memory interface
wire [XLEN-1:0] data_read;
wire [IXLEN-1:0] instruction_read;
wire init_done;

wire addr_data_valid;
wire addr_inst_valid;
wire [XLEN-1:0] inst_data_write;
wire [ADDR_BYTE_W-1:0] data_read_write_adr;
wire [ADDR_BYTE_W-1:0] inst_fetch_adr;
wire is_write_PRAM;

//init_controller
wire [2:0] state;
wire burst_dim;
wire PRAM_in;
wire PRAM_addr_type;
wire SPI_rdata_type;
wire ROM_addr_type;
wire [ADDR_BYTE_W-1:0] INITIALIZATION_addr;
wire mem_init;
wire enable;
wire first_fetch;

//SPI top
wire rvalid;
wire [XLEN-1:0] rdata;  
wire busy;
wire done;
wire start;
wire is_write_SPI;
wire [ADDR_BYTE_W-1:0] byte_addr;
wire [ADDR_BYTE_W-1:0] burst_len;
wire [XLEN-1:0] wdata;

core #(.XLEN(XLEN)) core_inst (
`ifndef SYNTHESIS
    .commit_valid(commit_valid),
    .commit_PC(commit_PC),
    .commit_instruction(commit_instruction),
    .commit_rd_addr(commit_rd_addr),
    .commit_rd_value(commit_rd_value),
`endif
    .clk(clk), 
    .reset(reset),
    .EMAB(EMAB),
    .EMCB(EMCB),
    .EMDB_out(EMDB_write),
    .valid_instr_fetch(valid_instr_fetch),
    .valid_data_read(valid_data_read),
    .valid_data_write(valid_data_write),
    .EMDB_in(EMDB_read),
    .pause_core(pause_core),
    .EIAB(EIAB),
    .EIB(EIB)
);

Memory_controller #(.ADDR_BYTE_W(ADDR_BYTE_W),.XLEN(XLEN),.IXLEN(IXLEN),.BURST_LEN(BURST_LEN)) Memory_controller_inst (
    //core 
    .EMAB(EMAB),
    .EMCB(EMCB),
    .EMDB_write(EMDB_write),
    .valid_instr_fetch(valid_instr_fetch),
    .valid_data_read(valid_data_read),
    .valid_data_write(valid_data_write),
    .EMDB_read(EMDB_read),
    .pause_core(pause_core),
    .EIAB(EIAB),
    .EIB(EIB),

    //memory_interface
    .data_read(data_read),
    .instruction_read(instruction_read),
    .init_done(init_done),
    .addr_data_valid(addr_data_valid),
    .addr_inst_valid(addr_inst_valid),
    .inst_data_write(inst_data_write),
    .data_read_write_adr(data_read_write_adr),
    .inst_fetch_adr(inst_fetch_adr),
    .is_write_PRAM(is_write_PRAM),

    //Init_controller
    .state(state),
    .burst_dim(burst_dim),
    .PRAM_in(PRAM_in),
    .PRAM_addr_type(PRAM_addr_type),
    .SPI_rdata_type(SPI_rdata_type),
    .ROM_addr_type(ROM_addr_type),
    .INITIALIZATION_addr(INITIALIZATION_addr),
    .mem_init(mem_init),
    .enable(enable),
    .first_fetch(first_fetch),

    //SPI top
    .rvalid(rvalid),
    .rdata(rdata),
    .busy(busy),
    .done(done),
    .start(start),
    .is_write_SPI(is_write_SPI),
    .byte_addr(byte_addr),
    .burst_len(burst_len),
    .wdata(wdata)
);

spi_master_interface #(.ADDR_BYTE_W(ADDR_BYTE_W),.DATA_W(XLEN))spi_master_interface_inst(
    .I_CLK(clk),
    .I_RSTN(I_A_RESET_L),

    .start(start),
    .is_write(is_write_SPI),         
    .byte_addr(byte_addr),     
    .burst_len(burst_len),     

    .wdata(wdata),           
    .rdata(rdata),
    .rvalid(rvalid),
    .busy(busy),
    .done(done),

    //external memory
    .O_SS(O_SS),             
    .O_MOSI(O_MOSI),           
    .I_MISO(O_MISO) 
);

init_ctrl #(.ADDR_W(ADDR_BYTE_W), .BASE_ADDR(BASE_ADDR),.MEM_LIMIT(MEM_LIMIT),.INCR(INCR)) Init_controller_inst(
    .clk(clk),
    .rst(reset),
    .interrupt(interrupt),
    .enable(enable),
    .state(state),
    .SPI_rdata_type(SPI_rdata_type),
    .PRAM_addr_type(PRAM_addr_type),
    .PRAM_in(PRAM_in),
    .burst_dim(burst_dim),
    .ROM_addr_type(ROM_addr_type),
    .mem_init(mem_init),
    .INITIALIZATION_addr(INITIALIZATION_addr),
    .first_fetch(first_fetch)
);

PMEM_memory_interface_top  #(.ADDR_BYTE_W(ADDR_BYTE_W),.XLEN(XLEN),.IXLEN(IXLEN)) PMEM_memory_interface_top_inst(
    .inst_data_write(inst_data_write),
    .data_read_write_adr(data_read_write_adr),
    .addr_data_valid(addr_data_valid),
    .inst_fetch_adr(inst_fetch_adr),
    .addr_inst_valid(addr_inst_valid),
    .is_write_PRAM(is_write_PRAM),
    .data_read(data_read),
    .instruction_read(instruction_read),

    //PRAM
    .clk(clk),
    .reset(reset)
);

endmodule