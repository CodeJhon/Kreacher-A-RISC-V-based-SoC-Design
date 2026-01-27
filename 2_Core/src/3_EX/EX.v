`include "../../include/CORE_CONSTANTS.vh"

module EX #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Control
    output            EX_pause_request,

    //----------------------------ID Stage
    //Data from/to ID stage
    input [XLEN-1:0]  ID_PC_step,
    input [XLEN-1:0]  ID_PC,
    input [XLEN-1:0]  ID_RS1,
    input [XLEN-1:0]  ID_RS2,
    input [4:0]       ID_RD_addr_in,
    input [XLEN-1:0]  ID_imm,
    input [XLEN-1:0]  ID_csr_data_rd,
    input [11:0]      ID_csr_addr_wr_in,

    output [XLEN-1:0] ID_exec_result,
    output [XLEN-1:0] ID_RD,
    output [4:0]      ID_RD_addr_out,
    output [XLEN-1:0] ID_csr_data_wr,
    output [11:0]     ID_csr_addr_wr_out,

    //Control from/to ID stage
    input [1:0]       ID_sel_opa,
    input [1:0]       ID_sel_opb,
    input [5:0]       ID_sel_op,
    input             ID_regfile_we_in,
    input             ID_jump,
    input             ID_branch,
    input             ID_sel_exec_result,
    input             ID_csr_we_in,
    input             ID_restore_mstatus_in,

    input             ID_mem_wr_en,
    input [2:0]       ID_val_rd_type,
    input [2:0]       ID_val_wr_type,
    input             ID_result_type,
    input             ID_sleep,
    
    input [2:0]       ID_sel_writeback,

    output            ID_regfile_we_out,
    output            ID_control_transfer_en,
    output            ID_csr_we_out,
    output            ID_restore_mstatus_out,

    //Flags
    input             ID_valid_data_read,
    input             ID_valid_data_write,

    //----------------------------MEM Stage
    //Data from/to MEM stage
    input [XLEN-1:0]  MEM_RD,
    input [4:0]       MEM_RD_addr_in,
    input [XLEN-1:0]  MEM_csr_data_wr,
    input [11:0]      MEM_csr_addr_wr_in,

    output [XLEN-1:0] MEM_PC_step,
    output [XLEN-1:0] MEM_exec_result,
    output [XLEN-1:0] MEM_RS2,
    output [4:0]      MEM_RD_addr_out,
    output [XLEN-1:0] MEM_csr_data_rd,
    output [11:0]     MEM_csr_addr_wr_out,


    //Control from/to MEM stage
    input             MEM_regfile_we_in,
    input             MEM_csr_we_in,

    output            MEM_mem_wr_en,
    output [2:0]      MEM_val_rd_type,
    output [2:0]      MEM_val_wr_type,
    output            MEM_result_type,
    output            MEM_csr_we_out,
    output            MEM_sleep,
    
    output            MEM_regfile_we_out,
    
    output [2:0]      MEM_sel_writeback,

    //Flags
    output            MEM_valid_data_read,
    output            MEM_valid_data_write
);

// ---------------------------------- Implementation of modules

//Mux opa
reg [XLEN-1:0]  ALU_opa;
always @(ID_sel_opa, ID_RS1, ID_csr_data_rd) begin
    case (ID_sel_opa)
        `OPA_RS1: ALU_opa = ID_RS1;
        `OPA_CSR: ALU_opa = ID_csr_data_rd;
        default:  ALU_opa = 0;
    endcase
end

reg  [XLEN-1:0]  ALU_opb;
//Mux opb
always @(ID_sel_opb, ID_imm, ID_RS2, ID_RS1) begin
    case (ID_sel_opb)
        `OPB_IMM: ALU_opb = ID_imm;
        `OPB_RS2: ALU_opb = ID_RS2;
        `OPB_RS1: ALU_opb = ID_RS1;
        default:  ALU_opb = 0;
    endcase
end

//ALU
wire [XLEN-1:0]  ALU_out;
wire             branch_condition;
wire             pause_to_calculate;
ALU #(.XLEN(XLEN)) u_ALU (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(pause),

    //Operands & Operation Type
    .opa(ALU_opa),
    .opb(ALU_opb),
    .sel_operation(ID_sel_op),

    //Control
    .pause_to_calculate(pause_to_calculate),
    
    //Results
    .branch_condition(branch_condition),
    .ALU_result(ALU_out)
);

//PC+IMM
wire [XLEN-1:0] PC_plus_imm;
assign PC_plus_imm = ID_imm + ID_PC;

//Mux exec_result
reg [XLEN-1:0] exec_result;

always @(ID_sel_exec_result, ALU_out, PC_plus_imm) begin
    exec_result = ALU_out;
    case (ID_sel_exec_result)
        `exec_result_ALU:          exec_result = ALU_out;
        `exec_result_PC_plus_imm:  exec_result = PC_plus_imm;
    endcase
end

//jump result
wire control_transfer_en;
assign control_transfer_en = ID_jump | (branch_condition & ID_branch);


// ------------------------------------- Connection to adjacent stage(s)
//ID
assign ID_exec_result       = exec_result;
assign ID_RD                = MEM_RD;
assign ID_RD_addr_out       = MEM_RD_addr_in;
assign ID_regfile_we_out    = MEM_regfile_we_in;
assign ID_control_transfer_en       = control_transfer_en;
assign ID_csr_we_out        = MEM_csr_we_in;
assign ID_restore_mstatus_out = ID_restore_mstatus_in;

assign ID_csr_data_wr       = MEM_csr_data_wr;
assign ID_csr_addr_wr_out   = MEM_csr_addr_wr_in;

//MEM
assign MEM_PC_step             = ID_PC_step;
assign MEM_exec_result      = exec_result;
assign MEM_RS2              = ID_RS2;
assign MEM_RD_addr_out      = ID_RD_addr_in;
assign MEM_csr_data_rd      = ID_csr_data_rd;
assign MEM_csr_we_out       = ID_csr_we_in;
assign MEM_sleep            = ID_sleep;
assign MEM_csr_addr_wr_out  = ID_csr_addr_wr_in;

assign MEM_mem_wr_en        = ID_mem_wr_en;
assign MEM_val_rd_type      = ID_val_rd_type;
assign MEM_val_wr_type      = ID_val_wr_type;
assign MEM_result_type      = ID_result_type;

assign MEM_regfile_we_out   = ID_regfile_we_in;

assign MEM_sel_writeback    = ID_sel_writeback;

//Flags
assign MEM_valid_data_read   = ID_valid_data_read;
assign MEM_valid_data_write  = ID_valid_data_write;

//Control
assign EX_pause_request = pause_to_calculate;

endmodule