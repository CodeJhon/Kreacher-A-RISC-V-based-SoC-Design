// =============================================================================
// File        : PMEM_interface.v
// Author      : Sanjai Palanisamy
// Email       : sanjai.palanisamy171@gmail.com
// Description :
//   This module connects instruction and data memory requests from the memory controller
// to the appropriate memory handlers and PRAM banks, managing chip select, write enable, 
// address scheduling, and read data multiplexing.
// =============================================================================
`include "MEMORY_CONSTANT.vh"

module PMEM_interface
#(
    parameter XLEN              = 64,       //Full data width
    parameter IXLEN             = 32,       //Instruction width
    parameter ADDR_BYTE_W       = 17,       //Address width
    parameter NUM_HANDLERS      = 4,        //Handler count
    parameter PRAMS_PER_HANDLER = 2,        //PRAMS per hanler
    parameter NUM_PRAMS         = NUM_HANDLERS * PRAMS_PER_HANDLER //PRAM count
)
(
    // Memory controller interface
    input                      clk,
    input                      reset_n,
    input  [XLEN-1:0]          inst_data_write,
    input  [ADDR_BYTE_W-1:0]   data_read_write_adr,
    input                      addr_data_valid,
    input  [ADDR_BYTE_W-1:0]   inst_fetch_adr,
    input                      addr_inst_valid,
    input                      is_write_PRAM,
	input  [XLEN-1:0] 		   init_internal_mask,
    output [IXLEN-1:0]         EIB_instruction_read,
    output                     pause_to_schedule,
    output reg [XLEN-1:0]      data_read,

    // Odd-even handler interface
    input [(XLEN*NUM_HANDLERS)-1:0]          data_out,
    input  [(IXLEN*NUM_HANDLERS)-1:0]        inst_out,
    output  [(ADDR_BYTE_W*NUM_HANDLERS)-1:0] addr_handler,
    
	output [XLEN-1:0] 		   init_internal_mask_odd_even,
    output                     addr_data_valid_h,
    output wire                addr_inst_valid_h,
    output [NUM_PRAMS-1:0]     cs,
    output reg [NUM_PRAMS-1:0] we,
    output [NUM_HANDLERS-1:0]  pause_to_schedule_odd_even,
    output [XLEN-1:0]          data_in
);

// ---------- Wire/Reg declarations ----------
wire [1:0]                    data_handler_sel;
wire [1:0]                    inst_handler_sel;
wire [2:0]                    inst_pram_sel;
wire [NUM_PRAMS-1:0]          macro_cs;

reg [NUM_PRAMS-1:0]           data_cs;
reg [NUM_PRAMS-1:0]           inst_cs;
reg [1:0]                     old_data_read_write_adr;
reg [1:0]                     old_inst_fetch_adr;
reg [IXLEN-1:0]               old_instruction_read;
reg [IXLEN-1:0]               instruction_read;

// wire [ADDR_BYTE_W-1:0] addr_handler_p[NUM_HANDLERS-1:0];
wire [(ADDR_BYTE_W*NUM_HANDLERS)-1:0] addr_handler_p;

// ---------- Pause to schedule flag to update data valid signal ----------
wire addr_data_valid_gated;
wire is_write_PRAM_gated;
reg pause_to_schedule_flag;

assign data_in              = inst_data_write;
assign inst_handler_sel     = inst_fetch_adr[14:13];
assign data_handler_sel     = data_read_write_adr[14:13];
assign inst_pram_sel        = {inst_handler_sel, inst_fetch_adr[2]};

always@(posedge clk or negedge reset_n)begin
    if(!reset_n)begin
        pause_to_schedule_flag <= 1'b0;
    end
    else begin
        pause_to_schedule_flag <= pause_to_schedule;
    end
end

//pause the core, even if one of the pause_to_scheduler is acvtiated
assign pause_to_schedule = |(pause_to_schedule_odd_even);

//this flag is to differentiate data valid signal in the next cycle of pause scheduler
assign addr_data_valid_gated = pause_to_schedule_flag ? 1'b0 : addr_data_valid;

//is to overcome the data_valid signal from the core in the next cycle of pause scheduler
assign is_write_PRAM_gated   = pause_to_schedule_flag ? 1'b0 : is_write_PRAM;

reg reserve_flag;
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
        reserve_flag <= 1'b0;
    else begin
        if(pause_to_schedule)
            reserve_flag <= 1'b1;
        else if(reserve_flag && !addr_inst_valid)
            reserve_flag <= 1'b1;
        else
            reserve_flag <= 1'b0;
    end
end

//old instruction during pasue handler
assign EIB_instruction_read  = reserve_flag ? old_instruction_read : instruction_read;

assign addr_data_valid_h     = addr_data_valid_gated;
assign addr_inst_valid_h     = addr_inst_valid;

assign init_internal_mask_odd_even = init_internal_mask;

// ---------- Data chip select ----------
always @( * ) begin
    data_cs ={NUM_PRAMS{1'b0}};
    case (data_handler_sel)
        `HANDLER_0: 
            data_cs[1:0] = {2{addr_data_valid_gated}};
        `HANDLER_1: 
            data_cs[3:2] = {2{addr_data_valid_gated}};
        `HANDLER_2: 
            data_cs[5:4] = {2{addr_data_valid_gated}};
        `HANDLER_3: 
            data_cs[7:6] = {2{addr_data_valid_gated}};
    endcase
end

// ---------- Instruction chip select ----------
always @( * ) begin
    inst_cs = {NUM_PRAMS{1'b0}};
    case (inst_pram_sel)
        `PRAM_0: 
            inst_cs[0] = addr_inst_valid_h;
        `PRAM_1:
            inst_cs[1] = addr_inst_valid_h;
        `PRAM_2: 
            inst_cs[2] = addr_inst_valid_h;
        `PRAM_3: 
            inst_cs[3] = addr_inst_valid_h;
        `PRAM_4: 
            inst_cs[4] = addr_inst_valid_h;
        `PRAM_5: 
            inst_cs[5] = addr_inst_valid_h;
        `PRAM_6: 
            inst_cs[6] = addr_inst_valid_h;
        `PRAM_7: 
            inst_cs[7] = addr_inst_valid_h;
        default: 
            inst_cs    = {NUM_PRAMS{1'b0}};
    endcase
end

assign macro_cs = data_cs | inst_cs;

// ---------- Address scheduler ----------
genvar s;
generate
    for(s = 0; s < NUM_HANDLERS; s = s + 1)begin: GEN_SCHEDULERS
        scheduler #(
            .ADDR_BYTE_W(ADDR_BYTE_W)
        )scheduler_s(
            .clk(clk),
            .reset_n(reset_n),
            .addr_inst(inst_fetch_adr),
            .addr_data(data_read_write_adr),
            .addr_inst_valid(addr_inst_valid),
            .addr_data_valid(addr_data_valid_gated),
            .cs_odd(macro_cs[(s*2)+1]),
            .cs_even(macro_cs[(s*2)]),
            .addr_handler(addr_handler_p[(s+1)*ADDR_BYTE_W-1 -: ADDR_BYTE_W]),
            .pause_to_schedule(pause_to_schedule_odd_even[s])
        );
    end
endgenerate

// ---------- Write enable ----------
always @( * ) begin
    we = {NUM_PRAMS{1'b0}};
    case (data_handler_sel)
        `HANDLER_0: 
            we[1:0] = {2{is_write_PRAM_gated}}; 
        
        `HANDLER_1: 
            we[3:2] = {2{is_write_PRAM_gated}}; 
        
        `HANDLER_2:
            we[5:4] = {2{is_write_PRAM_gated}}; 
        
        `HANDLER_3: 
            we[7:6] = {2{is_write_PRAM_gated}}; 
    endcase
end

// ---------- Instruction read multiplexer ----------
always @(posedge clk, negedge reset_n) begin
    if (!reset_n)
        old_inst_fetch_adr <= 2'b00;
    else if (addr_inst_valid)
        old_inst_fetch_adr <= inst_handler_sel;
end

// ---------- Instruction from different handler-------
always @( * ) begin
    instruction_read         =  {IXLEN{1'b0}};
    case(old_inst_fetch_adr)
        `HANDLER_0: 
            instruction_read = inst_out[(IXLEN*1)-1:0];
        `HANDLER_1: 
            instruction_read = inst_out[(IXLEN*2)-1:(IXLEN*1)];
        `HANDLER_2: 
            instruction_read = inst_out[(IXLEN*3)-1:(IXLEN*2)];
        `HANDLER_3: 
            instruction_read = inst_out[(IXLEN*4)-1:(IXLEN*3)];
    endcase
end

//----------To send old instruction to core during pause scheduler------
always@(posedge clk, negedge reset_n)begin
    if(!reset_n)begin
        old_instruction_read <= 32'b0;
    end
    else if(addr_inst_valid && !reserve_flag) begin
        old_instruction_read <= instruction_read;
    end
end

// ---------- Data read multiplexer ----------
always @(posedge clk, negedge reset_n) begin
    if (!reset_n)
        old_data_read_write_adr <= 2'b00;
    else if (addr_data_valid_gated)
        old_data_read_write_adr <= data_handler_sel;
end

always @( * ) begin
    data_read = {XLEN{1'b0}};
    case (old_data_read_write_adr)
        `HANDLER_0: 
            data_read = data_out[(XLEN*1)-1:0];
        `HANDLER_1: 
            data_read = data_out[(XLEN*2)-1:(XLEN*1)];
        `HANDLER_2: 
            data_read = data_out[(XLEN*3)-1:(XLEN*2)];
        `HANDLER_3: 
            data_read = data_out[(XLEN*4)-1:(XLEN*3)];
    endcase
end

assign addr_handler = addr_handler_p;
assign cs =  macro_cs;

endmodule
