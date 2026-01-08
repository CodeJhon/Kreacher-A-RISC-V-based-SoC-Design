`include "MEMORY_CONSTANT.vh"

module PMEM_memory_interface
#(
    parameter PRAMs = 2,
    parameter XLEN = 64,     // Full data width
    parameter IXLEN = 32,    // Instruction width
    parameter ADDR_BYTE_W = 17
)
(
    // Memory controller interface
    input clk,
    input reset_n,
    input  [XLEN-1:0] inst_data_write,
    input  [ADDR_BYTE_W-1:0] data_read_write_adr,
    input  addr_data_valid,
    input  [ADDR_BYTE_W-1:0] inst_fetch_adr,
    input  addr_inst_valid,
    input  is_write_PRAM,

    output reg [XLEN-1:0] data_read,
    output reg [IXLEN-1:0] instruction_read,

    // Odd-even handler interface
    input  [XLEN-1:0] data_out1,
    input  [IXLEN-1:0] inst_out1,
    output [XLEN-1:0] data_in,
    output reg [ADDR_BYTE_W-1:0] addr_handler1,
    output cs_0,
    output cs_1,
    output reg we_0,
    output reg we_1,
    output addr_data_valid_h,
    output addr_inst_valid_h
);

// ---------- Wire/Reg declarations ----------
assign data_in = inst_data_write;

reg data_cs0, data_cs1;
reg inst_cs0, inst_cs1;
reg [1:0] old_data_read_write_adr;
reg [1:0] old_inst_fetch_adr;


assign addr_data_valid_h = addr_data_valid;
assign addr_inst_valid_h = addr_inst_valid;
// ---------- Address scheduler ----------

always@(*) begin
    if(!reset_n)
        addr_handler1 = 0;
    else if(addr_data_valid)
        addr_handler1 = data_read_write_adr;
    else if(addr_inst_valid)
        addr_handler1 = inst_fetch_adr;
    //else create hold state
end

// ---------- Data chip select ----------
always @(*) begin
    data_cs0 = 0;
    data_cs1 = 0;
    case ({data_read_write_adr[14:13], data_read_write_adr[2]})
        `PRAM_0: data_cs0 = addr_data_valid;
        `PRAM_1: data_cs1 = addr_data_valid;
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
    case ({inst_fetch_adr[14:13], inst_fetch_adr[2]})
        `PRAM_0: inst_cs0 = addr_inst_valid;
        `PRAM_1: inst_cs1 = addr_inst_valid;
        default: begin
            inst_cs0 = 0;
            inst_cs1 = 0;
        end
    endcase
end

assign cs_0 = data_cs0 || inst_cs0;
assign cs_1 = data_cs1 || inst_cs1;

// ---------- Write enable ----------
always @(*) begin
    we_0 = 0;
    we_1 = 0;
    case ({data_read_write_adr[14:13]})
        `HANDLER_0: begin
            we_0 = is_write_PRAM; 
            we_1 = is_write_PRAM;
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
        old_inst_fetch_adr <= inst_fetch_adr[14:13];
end

always @(*) begin
    instruction_read = 0;
    case(old_inst_fetch_adr)
        `HANDLER_0: instruction_read = inst_out1;
        default:    instruction_read = 0;
endcase
end

// ---------- Data read multiplexer ----------
always @(posedge clk, negedge reset_n) begin
    if (!reset_n)
        old_data_read_write_adr <= 2'b00;
    else if (addr_data_valid)
        old_data_read_write_adr <= data_read_write_adr[14:13];
end

always @(*) begin
    data_read = 0;
    case (old_data_read_write_adr)
        `HANDLER_0: data_read = data_out1;
        default:    data_read = 0;
    endcase
end

endmodule
