// =============================================================================
// File        : ID.v
// Author      : Jhon Steven Pinto Hernandez
// Email       : jhonstevenpintoh@gmail.com
// Description :
//   Performs instruction decode, register operand selection, CSR handling, and control signal propagation to the execute stage.
// =============================================================================

`include "../../include/CORE_CONSTANTS.vh"

module ID #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Interrupt Handler
    input             take_interrupt_0,
    input             take_interrupt_1,

    input             interrupt_mepc_we,
    input [XLEN-1:0]  interrupt_PC_to_mepc,
    output            mie,

    //----------------------------IF_HK Stage
    //Data from/to IF_HK stage
    input [XLEN-1:0]      IF_PC_step,
    input [XLEN-1:0]      IF_PC,
    input [31:0]          IF_canonical_instruction, 

    output [XLEN-1:0]     IF_exec_result,

    //Control from/to IF_HK stage
    output                IF_control_transfer_en,
    output                IF_illegal_trap,

    //----------------------------EX Stage
    //Data from/to EX stage
    input [XLEN-1:0]      EX_exec_result,
    input [XLEN-1:0]      EX_RD,
    input [4:0]           EX_RD_addr_in,
    input [XLEN-1:0]      EX_csr_data_wr,
    input [11:0]          EX_csr_addr_wr_in,

    output reg [XLEN-1:0] EX_PC_step,
    output reg [XLEN-1:0] EX_PC,
    output reg [XLEN-1:0] EX_RS1,
    output reg [XLEN-1:0] EX_RS2,
    output reg [4:0]      EX_RD_addr_out,
    output reg [XLEN-1:0] EX_imm,
    output reg [XLEN-1:0] EX_csr_data_rd,
    output reg [11:0]     EX_csr_addr_wr_out,

    //Control from/to EX stage
    input                 EX_regfile_we_in,
    input                 EX_control_transfer_en,
    input                 EX_csr_we_in,
    input                 EX_restore_mstatus_in,

    output reg [1:0]      EX_sel_opa,
    output reg [1:0]      EX_sel_opb,
    output reg [5:0]      EX_sel_op,
    output reg            EX_regfile_we_out,
    output reg            EX_jump,
    output reg            EX_branch,
    output reg            EX_sel_exec_result,
    output reg            EX_csr_we_out,
    output reg            EX_restore_mstatus_out,

    output reg            EX_mem_wr_en,
    output reg [2:0]      EX_val_rd_type,
    output reg [2:0]      EX_val_wr_type,
    output reg            EX_result_type,
    output reg            EX_sleep,
    
    output reg [2:0]      EX_sel_writeback,

    //Flags
    output reg            EX_valid_data_read,
    output reg            EX_valid_data_write,

    //---------------------------- HCU (Hazard Control Unit)
    input                 ID_flush,
    input  [1:0]          ID_sel_RS1,
    input  [1:0]          ID_sel_RS2,
    input  [1:0]          ID_sel_csr_data_rd,
    
    output [4:0]          ID_RS1_addr,
    output [4:0]          ID_RS2_addr,
    output [11:0]         ID_csr_addr_rd,


    output reg [4:0]      EX_RS1_addr,
    output reg [4:0]      EX_RS2_addr

);

// Instruction valid signals -> Allow us to differentiate between observation of flush/reset and observations of actual program instructions
reg             instr_valid;

// ---------------------------------- Implementation of modules
wire            illegal_instr;
wire            illegal_trap = illegal_instr && ~EX_control_transfer_en && instr_valid;

wire [2:0]      imm_type;
wire            csr_re;
wire            read_mepc;

wire            jump;
wire            branch;
wire            restore_mstatus;

wire [1:0]      sel_opa;
wire [1:0]      sel_opb;
wire [5:0]      sel_op;
wire            regfile_we;

wire            csr_we;

wire            sel_exec_result;

wire            mem_wr_en;
wire [2:0]      val_wr_type;
wire [2:0]      val_rd_type;
wire            result_type;
wire            sleep;

wire [2:0]      sel_writeback;

wire            valid_data_read;
wire            valid_data_write;

control u_control (

    //---------------------- Inputs
    .canonical_instruction(IF_canonical_instruction),

    //----------------------- Outputs
    //Flags
    .valid_data_read(valid_data_read),
    .valid_data_write(valid_data_write),

    //Illegal Instruction
    .illegal_instr(illegal_instr),

    // ID
    .imm_type(imm_type),
    .csr_re(csr_re),
    .read_mepc(read_mepc),

    // EX
    .jump(jump),
    .branch(branch),
    .restore_mstatus(restore_mstatus),

    .sel_opa(sel_opa),
    .sel_opb(sel_opb),
    .sel_op(sel_op),
    .regfile_we(regfile_we),

    .sel_exec_result(sel_exec_result),

    .csr_we(csr_we),
    

    // MEM
    .mem_wr_en(mem_wr_en),
    .val_wr_type(val_wr_type),
    .val_rd_type(val_rd_type),
    .result_type(result_type),
    .sleep(sleep),

    // WB
    .sel_writeback(sel_writeback)
);


//Register File
wire [XLEN-1:0] regfile_RS1;
wire [XLEN-1:0] regfile_RS2;
wire in_regfile_we = EX_regfile_we_in && !pause;
regfile #(.XLEN(XLEN)) u_regfile (
    .clk        (clk),
    .reset_n    (reset_n),

    // Addresses
    .RS1_addr   (IF_canonical_instruction[19:15]),
    .RS2_addr   (IF_canonical_instruction[24:20]),
    .RD_addr    (EX_RD_addr_in),

    // Sources & Destinations
    .RD         (EX_RD),
    .RS1        (regfile_RS1),
    .RS2        (regfile_RS2),

    // Control
    .regfile_we (in_regfile_we)
);

// HCU Bypass muxes for RS1 & RS2
reg [XLEN-1:0] RS1;
reg [XLEN-1:0] RS2;
always @(regfile_RS1, regfile_RS2, EX_RD, ID_sel_RS1, ID_sel_RS2) begin
    case (ID_sel_RS1)
        `HCU_NO_BYPASS: RS1 = regfile_RS1;
        `HCU_BYPASS_WB: RS1 = EX_RD;
        default:        RS1 = {XLEN{1'd0}};
    endcase
    case (ID_sel_RS2)
        `HCU_NO_BYPASS: RS2 = regfile_RS2;
        `HCU_BYPASS_WB: RS2 = EX_RD;
        default:        RS2 = {XLEN{1'd0}};
    endcase
end

//Immediate Build (& Sign extension)
wire [XLEN-1:0] imm;
build_imm #(.XLEN(XLEN)) u_build_imm (
    .build_in(IF_canonical_instruction),
    .build_out(imm),
    .imm_type(imm_type)
);

//CSR Bank
wire [XLEN-1:0] csr_bank_data_rd;
wire in_csr_we = EX_csr_we_in && !pause;
//Logic to save in mepc the PC of the illegal instruction in the case that both cases happen at the same time 
// -> Which means we will re-execute the illegal instruction after doing MRET in the interrupt handler
reg [XLEN-1:0] interrupt_PC_to_mepc_f;
always @( * ) begin
    interrupt_PC_to_mepc_f = interrupt_PC_to_mepc;
    if(illegal_trap && !take_interrupt_1 && !take_interrupt_0)
        interrupt_PC_to_mepc_f = IF_PC;
end

wire [11:0] csr_addr_rd = read_mepc ? `MEPC_ADDR : IF_canonical_instruction[31:20];

wire csr_re_to_bank = csr_re | read_mepc;
csr_bank #(.XLEN(XLEN)) u_csr_bank (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(pause),

    //Interrupt Handler
    .take_interrupt_0(take_interrupt_0),
    .take_interrupt_1(take_interrupt_1),
    .interrupt_mepc_we(interrupt_mepc_we),
    .interrupt_PC_to_mepc(interrupt_PC_to_mepc_f),

    .mie(mie),

    //Illegal Instruction
    .illegal_trap(illegal_trap),
    .PC_illegal(IF_PC),

    //MRET signals
    .restore_mstatus(EX_restore_mstatus_in),

    //Inputs/Outputs from/to Zicsr HW
    .csr_we(in_csr_we),        //Write-enable
    .csr_re(csr_re_to_bank),        //Read-enable

    .csr_addr_rd(csr_addr_rd),
    .csr_addr_wr(EX_csr_addr_wr_in),
    .csr_data_wr(EX_csr_data_wr),
    .csr_data_rd(csr_bank_data_rd)
);

// HCU Bypass mux for csr_data_rd
reg [XLEN-1:0] csr_data_rd;
always @(ID_sel_csr_data_rd, csr_bank_data_rd, EX_csr_data_wr) begin
    case (ID_sel_csr_data_rd)
        `HCU_NO_BYPASS: csr_data_rd = csr_bank_data_rd;
        `HCU_BYPASS_WB: csr_data_rd = EX_csr_data_wr;
        default:        csr_data_rd = {XLEN{1'd0}};
    endcase
end

// ------------------------------------- Connection to adjacent stage(s)
//IF_HK
assign IF_exec_result       = EX_exec_result;
assign IF_control_transfer_en       = EX_control_transfer_en;
assign IF_illegal_trap     = illegal_trap;

task clear_id_stage;
begin
        //Flags / Internal 
    instr_valid         <= 1'd0;
        //Data
    EX_PC_step           <= {XLEN{1'd0}};
    EX_PC                <= {XLEN{1'd0}};
    EX_RS1               <= {XLEN{1'd0}};
    EX_RS2               <= {XLEN{1'd0}};
    EX_RD_addr_out       <= 5'd0;
    EX_imm               <= {XLEN{1'd0}};
    EX_csr_data_rd       <= {XLEN{1'd0}};
    EX_csr_addr_wr_out   <= 12'd0;
        //Control
    EX_sel_opa           <= 2'd0;
    EX_sel_opb           <= 2'd0;
    EX_sel_op            <= 6'd0;
    EX_regfile_we_out    <= 1'd0;
    EX_jump              <= 1'd0;
    EX_branch            <= 1'd0;
    EX_sel_exec_result   <= 1'd0;
    EX_csr_we_out        <= 1'd0;
    EX_restore_mstatus_out <= 1'd0;

    EX_mem_wr_en         <= 1'd0;
    EX_val_rd_type       <= 3'd0;
    EX_val_wr_type       <= 3'd0;
    EX_result_type       <= 1'd0;
    EX_sleep             <= 1'd0;

    EX_sel_writeback     <= 3'd0; 

    //Flags
    EX_valid_data_read   <= 1'd0;
    EX_valid_data_write  <= 1'd0;
end
endtask

task write_id_stage;
begin
        //Flags / Internal 
    instr_valid          <= 1'b1;
        //Data
    EX_PC_step              <= IF_PC_step;
    EX_PC                <= IF_PC;
    EX_RS1               <= RS1;
    EX_RS2               <= RS2;
    EX_RD_addr_out       <= IF_canonical_instruction[11:7];
    EX_imm               <= imm;
    EX_csr_data_rd       <= csr_data_rd;
    EX_csr_addr_wr_out   <= csr_addr_rd;
        //Control
    EX_sel_opa           <= sel_opa;
    EX_sel_opb           <= sel_opb;
    EX_sel_op            <= sel_op;
    EX_regfile_we_out    <= regfile_we;
    EX_jump              <= jump;
    EX_branch            <= branch;
    EX_sel_exec_result   <= sel_exec_result;
    EX_csr_we_out        <= csr_we;
    EX_restore_mstatus_out <= restore_mstatus;

    EX_mem_wr_en         <= mem_wr_en;
    EX_val_rd_type       <= val_rd_type;
    EX_val_wr_type       <= val_wr_type;
    EX_result_type       <= result_type;
    EX_sleep             <= sleep;

    EX_sel_writeback     <= sel_writeback;

    //Flags
    EX_valid_data_read   <= valid_data_read;
    EX_valid_data_write  <= valid_data_write;
end
endtask

//EX
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
        clear_id_stage;
    else if(!pause)begin
        if (ID_flush)
            clear_id_stage;
        else
            write_id_stage;
    end
        
end

//HCU
always@(posedge clk, negedge reset_n)begin
    if(!reset_n)begin
        EX_RS1_addr          <= 5'd0;
        EX_RS2_addr          <= 5'd0;
    end
    else if(!pause) begin
        EX_RS1_addr          <= IF_canonical_instruction[19:15];
        EX_RS2_addr          <= IF_canonical_instruction[24:20];
    end
end

assign ID_RS1_addr           = IF_canonical_instruction[19:15];
assign ID_RS2_addr           = IF_canonical_instruction[24:20];
assign ID_csr_addr_rd        = csr_addr_rd;

endmodule