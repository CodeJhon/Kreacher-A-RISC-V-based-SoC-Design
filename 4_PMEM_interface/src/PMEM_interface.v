`include "MEMORY_CONSTANT.vh"

module PMEM_interface
#(
    parameter PRAMS = 2,        //PRAM count
    parameter XLEN = 64,        // Full data width
    parameter IXLEN = 32,       // Instruction width
    parameter ADDR_BYTE_W = 17  //Address width
)
(
    // Memory controller interface
    input  clk,
    input  reset_n,
    input  [XLEN-1:0] inst_data_write,
    input  [ADDR_BYTE_W-1:0] data_read_write_adr,
    input  addr_data_valid,
    input  [ADDR_BYTE_W-1:0] inst_fetch_adr,
    input  addr_inst_valid,
    input  is_write_PRAM,
    output reg [XLEN-1:0] data_read,
    output [IXLEN-1:0] EIB_instruction_read,
    output pause_to_schedule,

    // Odd-even handler interface
    input  [XLEN-1:0] data_out1,
    input  [IXLEN-1:0] inst_out1,
    output [XLEN-1:0] data_in,
    output [ADDR_BYTE_W-1:0] addr_handler1,
    output reg we_0,
    output reg we_1,
    output cs_0,
    output cs_1,
    output addr_data_valid_h,
    output addr_inst_valid_h
);

// ---------- Wire/Reg declarations ----------
wire [1:0]data_handler_sel;
wire [1:0] inst_handler_sel;
wire [3:0]data_pram_sel;
wire [3:0] inst_pram_sel;

reg data_cs0, data_cs1;
reg inst_cs0, inst_cs1;
reg [1:0] old_data_read_write_adr;
reg [1:0] old_inst_fetch_adr;
reg [IXLEN-1:0] old_instruction_read;
reg [IXLEN-1:0] instruction_read;

// ---------- Pause to schedule flag to update data valid signal ----------
wire addr_data_valid_gated;
reg pause_to_schedule_flag;

assign data_in = inst_data_write;
assign inst_pram_sel = {inst_fetch_adr[14:13], inst_fetch_adr[2]};
assign data_pram_sel = {data_read_write_adr[14:13], data_read_write_adr[2]};
assign inst_handler_sel = inst_fetch_adr[14:13];
assign data_handler_sel = data_read_write_adr[14:13];

always@(posedge clk or negedge reset_n)begin
    if(!reset_n)begin
        pause_to_schedule_flag <= 1'b0;
    end
    else begin
        pause_to_schedule_flag <= pause_to_schedule;
    end
end

//this flag is to differentiate data valid signal in the next cycle of pause scheduler
assign addr_data_valid_gated = pause_to_schedule_flag ? 1'b0 : addr_data_valid;

//is to overcome the data_valid signal from the core in the next cycle of pause scheduler
assign is_write_PRAM_gated   = pause_to_schedule_flag ? 1'b0 : is_write_PRAM;

//old instruction during pasue handler
assign EIB_instruction_read  = pause_to_schedule_flag ? old_instruction_read : instruction_read;

assign addr_data_valid_h     = addr_data_valid_gated;
assign addr_inst_valid_h     = addr_inst_valid;

// ---------- Address scheduler ----------
scheduler #(.ADDR_BYTE_W(ADDR_BYTE_W)) scheduler_inst(
    .clk(clk),
    .reset_n(reset_n),
    .addr_inst(inst_fetch_adr),
    .addr_data(data_read_write_adr),
    .addr_inst_valid(addr_inst_valid),
    .addr_data_valid(addr_data_valid_gated),
    .cs_odd(cs_1),
    .cs_even(cs_0),
    .addr_handler(addr_handler1),
    .pause_to_schedule(pause_to_schedule)
);

// ---------- Data chip select ----------
always @(*) begin
    data_cs0 = 0;
    data_cs1 = 0;
    case (data_handler_sel)
        `HANDLER_0: begin
            data_cs0 = addr_data_valid_gated;
            data_cs1 = addr_data_valid_gated;
        end
        default: begin
            data_cs0 = 0;
            data_cs1 = 0;
        end
    endcase
end

// ---------- Instruction chip select ----------
always @(*) begin
    inst_cs0 = 0;
    inst_cs1 = 0;
    case (inst_pram_sel)
        `PRAM_0: inst_cs0 = addr_inst_valid;
        `PRAM_1: inst_cs1 = addr_inst_valid;
        default: begin
            inst_cs0 = 0;
            inst_cs1 = 0;
        end
    endcase
end

assign cs_0 = data_cs0 | inst_cs0;
assign cs_1 = data_cs1 | inst_cs1;

// ---------- Write enable ----------
always @(*) begin
    we_0 = 0;
    we_1 = 0;
    case (data_handler_sel)
        `HANDLER_0: begin
            we_0 = is_write_PRAM_gated; 
            we_1 = is_write_PRAM_gated;
        end
        default: begin
            we_0 = 0;
            we_1 = 0;
        end
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
always @(*) begin
    case(old_inst_fetch_adr)
        `HANDLER_0: instruction_read = inst_out1;
        default:    instruction_read = 0;
endcase
end

//----------To send old instruction to core during pause scheduler------
always@(posedge clk, negedge reset_n)begin
    if(!reset_n)begin
        old_instruction_read <= 32'b0;
    end
    else begin
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

always @(*) begin
    data_read = 0;
    case (old_data_read_write_adr)
        `HANDLER_0: data_read = data_out1;
        default:    data_read = 0;
    endcase
end

endmodule
