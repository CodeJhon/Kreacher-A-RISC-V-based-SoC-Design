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
    input [XLEN-1:0]  IF_PC_step,
    input [XLEN-1:0]  IF_PC,
    input [31:0]      IF_canonical_instruction, 

    output [XLEN-1:0] IF_exec_result,

    //Control from/to IF_HK stage
    output            IF_control_transfer_en,
    output            IF_illegal_trap,

    //----------------------------EX Stage
    //Data from/to EX stage
    input [XLEN-1:0]  EX_exec_result,
    input [XLEN-1:0]  EX_RD,
    input [4:0]       EX_RD_addr_in,
    input [XLEN-1:0]  EX_csr_data_wr,
    input [11:0]      EX_csr_addr_wr_in,
    

    output [XLEN-1:0] EX_PC_step,
    output [XLEN-1:0] EX_PC,
    output [XLEN-1:0] EX_RS1,
    output [XLEN-1:0] EX_RS2,
    output [4:0]      EX_RD_addr_out,
    output [XLEN-1:0] EX_imm,
    output [XLEN-1:0] EX_csr_data_rd,
    output [11:0]     EX_csr_addr_wr_out,

    //Control from/to EX stage
    input             EX_regfile_we_in,
    input             EX_control_transfer_en,
    input             EX_csr_we_in,
    input             EX_restore_mstatus_in,

    output [1:0]      EX_sel_opa,
    output [1:0]      EX_sel_opb,
    output [5:0]      EX_sel_op,
    output            EX_regfile_we_out,
    output            EX_jump,
    output            EX_branch,
    output            EX_sel_exec_result,
    output            EX_csr_we_out,
    output            EX_restore_mstatus_out,

    output            EX_mem_wr_en,
    output [2:0]      EX_val_rd_type,
    output [2:0]      EX_val_wr_type,
    output            EX_result_type,
    output            EX_sleep,
    
    output [2:0]      EX_sel_writeback,

    //Flags
    output            EX_valid_data_read,
    output            EX_valid_data_write

);

// ---------------------------------- Implementation of modules
wire            illegal_instr;
wire            illegal_trap = illegal_instr && ~EX_control_transfer_en;

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
wire [XLEN-1:0] RS1;
wire [XLEN-1:0] RS2;
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
    .RS1        (RS1),
    .RS2        (RS2),

    // Control
    .regfile_we (in_regfile_we)
);

//Immediate Build (& Sign extension)
wire [XLEN-1:0] imm;
build_imm #(.XLEN(XLEN)) u_build_imm (
    .build_in(IF_canonical_instruction),
    .build_out(imm),
    .imm_type(imm_type)
);


//CSR Bank
wire [XLEN-1:0] csr_data_rd;
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
    .csr_data_rd(csr_data_rd)
);



// ------------------------------------- Connection to adjacent stage(s)
//IF_HK
assign IF_exec_result       = EX_exec_result;
assign IF_control_transfer_en       = EX_control_transfer_en;
assign IF_illegal_trap     = illegal_trap;

//EX
    //Data
assign EX_PC_step              = IF_PC_step;
assign EX_PC                = IF_PC;
assign EX_RS1               = RS1;
assign EX_RS2               = RS2;
assign EX_RD_addr_out       = IF_canonical_instruction[11:7];
assign EX_imm               = imm;
assign EX_csr_data_rd       = csr_data_rd;
assign EX_csr_addr_wr_out   = csr_addr_rd;
    //Control
assign EX_sel_opa           = sel_opa;
assign EX_sel_opb           = sel_opb;
assign EX_sel_op            = sel_op;
assign EX_regfile_we_out    = regfile_we;
assign EX_jump              = jump;
assign EX_branch            = branch;
assign EX_sel_exec_result   = sel_exec_result;
assign EX_csr_we_out        = csr_we;
assign EX_restore_mstatus_out = restore_mstatus;

assign EX_mem_wr_en         = mem_wr_en;
assign EX_val_rd_type       = val_rd_type;
assign EX_val_wr_type       = val_wr_type;
assign EX_result_type       = result_type;
assign EX_sleep             = sleep;

assign EX_sel_writeback     = sel_writeback;
    
    //Flags
assign EX_valid_data_read   = valid_data_read;
assign EX_valid_data_write  = valid_data_write;

endmodule