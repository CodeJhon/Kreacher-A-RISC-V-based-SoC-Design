`include "../../include/CORE_CONSTANTS.vh"

module EX #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //----------------------------ID Stage
    //Data from/to ID stage
    input [XLEN-1:0]      ID_PC_step,
    input [XLEN-1:0]      ID_PC,
    input [XLEN-1:0]      ID_RS1,
    input [XLEN-1:0]      ID_RS2,
    input [4:0]           ID_RD_addr_in,
    input [XLEN-1:0]      ID_imm,
    input [XLEN-1:0]      ID_csr_data_rd,
    input [11:0]          ID_csr_addr_wr_in,

    output [XLEN-1:0]     ID_exec_result,
    output [XLEN-1:0]     ID_RD,
    output [4:0]          ID_RD_addr_out,
    output [XLEN-1:0]     ID_csr_data_wr,
    output [11:0]         ID_csr_addr_wr_out,

    //Control from/to ID stage
    input [1:0]           ID_sel_opa,
    input [1:0]           ID_sel_opb,
    input [4:0]           ID_sel_op,
    input                 ID_regfile_we_in,
    input                 ID_jump,
    input                 ID_branch,
    input                 ID_sel_exec_result,
    input                 ID_csr_we_in,
    input                 ID_restore_mstatus_in,

    input                 ID_mem_wr_en,
    input [2:0]           ID_val_rd_type,
    input [2:0]           ID_val_wr_type,
    input                 ID_result_type,
    input                 ID_sleep,
    
    input [2:0]           ID_sel_writeback,

    output                ID_regfile_we_out,
    output                ID_control_transfer_en,
    output                ID_csr_we_out,
    output                ID_restore_mstatus_out,

    //Flags
    input             ID_valid_data_read,
    input             ID_valid_data_write,

    //----------------------------MEM Stage
    //Data from/to MEM stage
    input [XLEN-1:0]      MEM_RD,
    input [4:0]           MEM_RD_addr_in,
    input [XLEN-1:0]      MEM_FW_exec_result,
    input [XLEN-1:0]      MEM_csr_data_wr,
    input [11:0]          MEM_csr_addr_wr_in,

    output reg [XLEN-1:0] MEM_PC_step,
    output reg [XLEN-1:0] MEM_exec_result,
    output reg [XLEN-1:0] MEM_RS2,
    output reg [4:0]      MEM_RD_addr_out,
    output reg [XLEN-1:0] MEM_csr_data_rd,
    output reg [11:0]     MEM_csr_addr_wr_out,

    //Control from/to MEM stage
    input                 MEM_regfile_we_in,
    input                 MEM_csr_we_in,

    output reg            MEM_mem_wr_en,
    output reg [2:0]      MEM_val_rd_type,
    output reg [2:0]      MEM_val_wr_type,
    output reg            MEM_result_type,
    output reg            MEM_csr_we_out,
    output reg            MEM_sleep,
    
    output reg            MEM_regfile_we_out,
    
    output reg [2:0]      MEM_sel_writeback,

    //Flags
    output reg            MEM_valid_data_read,
    output reg            MEM_valid_data_write,
    
    //---------------------------- HCU (Hazard Control Unit)
    input       EX_flush,
    input [1:0] HCU_sel_RS1,
    input [1:0] HCU_sel_RS2,
    input [1:0] HCU_sel_csr_data_rd

);

// ---------------------------------- Implementation of modules

//Bypass Muxes for RS1 & RS2 (left  muxes)
reg  [XLEN-1:0]  RS1;
reg  [XLEN-1:0]  RS2;
always @(HCU_sel_RS1, HCU_sel_RS2, ID_RS1, ID_RS2, MEM_FW_exec_result, MEM_RD) begin
    case (HCU_sel_RS1)
        `HCU_NO_BYPASS:  RS1 = ID_RS1;
        `HCU_BYPASS_MEM: RS1 = MEM_FW_exec_result;
        `HCU_BYPASS_WB:  RS1 = MEM_RD;
        default:         RS1 = 0;
    endcase
    case (HCU_sel_RS2)
        `HCU_NO_BYPASS:  RS2 = ID_RS2;
        `HCU_BYPASS_MEM: RS2 = MEM_FW_exec_result;
        `HCU_BYPASS_WB:  RS2 = MEM_RD;
        default:         RS2 = 0;
    endcase
end

//Bypass Mux for csr_data_rd
reg [XLEN-1:0] csr_data_rd;
always @(HCU_sel_csr_data_rd, ID_csr_data_rd, MEM_FW_exec_result, MEM_csr_data_wr) begin
    case (HCU_sel_csr_data_rd)
        `HCU_NO_BYPASS:  csr_data_rd = ID_csr_data_rd;
        `HCU_BYPASS_MEM: csr_data_rd = MEM_FW_exec_result;
        `HCU_BYPASS_WB:  csr_data_rd = MEM_csr_data_wr;
        default:         csr_data_rd = 0;
    endcase
end

//Mask csr_data_rd by modifying the read-only bits of writable csr's
wire [XLEN-1:0] csr_data_rd_masked;
csr_mask #(.XLEN(64)) u_csr_mask (
    .in_raw    (csr_data_rd),
    .csr_addr  (ID_csr_addr_wr_in),
    .old_mcause(ID_csr_data_rd),

    .out_masked(csr_data_rd_masked)
);


//Mux opa
reg [XLEN-1:0]  ALU_opa;
always @(ID_sel_opa, RS1, ID_csr_data_rd) begin
    case (ID_sel_opa)
        `OPA_RS1: ALU_opa = RS1;
        `OPA_CSR: ALU_opa = csr_data_rd_masked;
        default:  ALU_opa = 0;
    endcase
end

reg  [XLEN-1:0]  ALU_opb;
//Mux opb
always @(ID_sel_opb, ID_imm, RS2, RS1) begin
    case (ID_sel_opb)
        `OPB_IMM: ALU_opb = ID_imm;
        `OPB_RS2: ALU_opb = RS2;
        `OPB_RS1: ALU_opb = RS1;
        default:  ALU_opb = 0;
    endcase
end


//ALU
wire [XLEN-1:0]  ALU_out;
wire             branch_condition;
ALU #(.XLEN(XLEN)) u_ALU (
    .opa(ALU_opa),
    .opb(ALU_opb),
    .sel_operation(ID_sel_op),
    
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
always @(posedge clk, negedge reset_n) begin
    if(!reset_n || EX_flush)begin
        MEM_PC_step             <= 0;
        MEM_exec_result      <= 0;
        MEM_RS2              <= 0;
        MEM_RD_addr_out      <= 0;
        MEM_csr_data_rd      <= 0;
        MEM_csr_we_out       <= 0;
        MEM_sleep            <= 0;
        MEM_csr_addr_wr_out  <= 0;

        MEM_mem_wr_en        <= 0;
        MEM_val_rd_type      <= 0;
        MEM_val_wr_type      <= 0;
        MEM_result_type      <= 0;

        MEM_regfile_we_out   <= 0;

        MEM_sel_writeback    <= 0;

        //Flags
        MEM_valid_data_read   <= 0;
        MEM_valid_data_write  <= 0;
    end
    else if(!pause) begin
        MEM_PC_step             <= ID_PC_step;
        MEM_exec_result      <= exec_result;
        MEM_RS2              <= RS2;
        MEM_RD_addr_out      <= ID_RD_addr_in;
        MEM_csr_data_rd      <= csr_data_rd_masked;
        MEM_csr_we_out       <= ID_csr_we_in;
        MEM_sleep            <= ID_sleep;
        MEM_csr_addr_wr_out  <= ID_csr_addr_wr_in;

        MEM_mem_wr_en        <= ID_mem_wr_en;
        MEM_val_rd_type      <= ID_val_rd_type;
        MEM_val_wr_type      <= ID_val_wr_type;
        MEM_result_type      <= ID_result_type;

        MEM_regfile_we_out   <= ID_regfile_we_in;

        MEM_sel_writeback    <= ID_sel_writeback;

        //Flags
        MEM_valid_data_read   <= ID_valid_data_read;
        MEM_valid_data_write  <= ID_valid_data_write;
    end
end

endmodule