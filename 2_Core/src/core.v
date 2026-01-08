module core #(parameter XLEN = 64)(//RV64I
    //Signals for verification purposes only
    `ifndef SYNTHESIS
        output              commit_valid,
        output [XLEN-1:0]   commit_PC,
        output [4:0]        commit_rd_addr,
        output [XLEN-1:0]   commit_rd_value,
        output [31:0]       commit_instruction,
    `endif

    //Global
    input clk,
    input reset_n,

    //Flags
    output            valid_instr_fetch,
    output            valid_data_read,
    output            valid_data_write,

    //Control
    input             pause_core,

    //Buses
    input  [31:0]     EIB,             //External Instruction Bus
    output [16:0]     EIAB,            //External Instruction Address Bus

    output [XLEN-1:0] EMAB,            //External Memory Address Bus
    output            EMCB,            //External Memory Control Bus
    output [XLEN-1:0] EMDB_out,        //External Memory Data Bus, output for the core, input for the external memory
    input  [XLEN-1:0] EMDB_in          //External Memory Data Bus, input for the core, output for the external memory
    
);

// Reset synchronizer -> async assert / sync deassert
reg reset_n_sync;
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)  reset_n_sync <= 1'b0;
    else           reset_n_sync <= 1'b1;
end

wire internal_core_pause = ~reset_n_sync | pause_core;

/*
    --- Wire terminology ---
    wire [LENGHT:0] (Fom Stage X)_Signal_Name_(To stage Y)
*/

//------------------------------------- Data signals (Not for buses)

//exec_result
wire [XLEN-1:0] ID_exec_result_IF;
wire [XLEN-1:0] EX_exec_result_ID;
wire [XLEN-1:0] EX_exec_result_MEM;
wire [XLEN-1:0] MEM_exec_result_WB;

//PC_4
wire [XLEN-1:0] IF_PC_4_ID;
wire [XLEN-1:0] ID_PC_4_EX;
wire [XLEN-1:0] EX_PC_4_MEM;
wire [XLEN-1:0] MEM_PC_4_WB;

//PC
wire [XLEN-1:0] IF_PC_ID;
wire [XLEN-1:0] ID_PC_EX;

//canonical_instruction
wire [31:0]     IF_canonical_instruction_ID;

//RD
wire [XLEN-1:0] WB_RD_MEM;
wire [XLEN-1:0] MEM_RD_EX;
wire [XLEN-1:0] EX_RD_ID;

//RS1
wire [XLEN-1:0] ID_RS1_EX;

//RS2
wire [XLEN-1:0] ID_RS2_EX;
wire [XLEN-1:0] EX_RS2_MEM;

//RD_addr_in
wire [4:0] ID_RD_addr_in_EX;
wire [4:0] EX_RD_addr_in_MEM;
wire [4:0] MEM_RD_addr_in_WB;

//RD_addr_out
wire [4:0] WB_RD_addr_out_MEM;
wire [4:0] MEM_RD_addr_out_EX;
wire [4:0] EX_RD_addr_out_ID;

//imm
wire [XLEN-1:0] ID_imm_EX;

//EMDB
wire [XLEN-1:0] MEM_EMDB_WB;

//------------------------------------- Control (Not for buses)

//sel_next_PC
wire  EX_sel_next_PC_ID;
wire  ID_sel_next_PC_IF;

//jump
wire  ID_jump_EX;

//branch
wire  ID_branch_EX;

//regfile_we_in
wire ID_regfile_we_in_EX;
wire EX_regfile_we_in_MEM;
wire MEM_regfile_we_in_WB;

//regfile_we_out
wire WB_regfile_we_out_MEM;
wire MEM_regfile_we_out_EX;
wire EX_regfile_we_out_ID;

//sel_exec_result
wire       ID_sel_exec_result_EX;

//sel_opb
wire [1:0] ID_sel_opb_EX;

//sel_op
wire [4:0] ID_sel_op_EX;

//mem_wr_en
wire ID_mem_wr_en_EX;
wire EX_mem_wr_en_MEM;

//val_rd_type
wire [2:0] ID_val_rd_type_EX;
wire [2:0] EX_val_rd_type_MEM;

//val_wr_type
wire [2:0] ID_val_wr_type_EX;
wire [2:0] EX_val_wr_type_MEM;

//result_type
wire       ID_result_type_EX;
wire       EX_result_type_MEM;

//sel_writeback
wire [2:0] ID_sel_writeback_EX;
wire [2:0] EX_sel_writeback_MEM;
wire [2:0] MEM_sel_writeback_WB;

//valid_data_read
wire       ID_valid_data_read_EX;
wire       EX_valid_data_read_MEM;

assign     valid_data_read = EX_valid_data_read_MEM;

//valid_data_write
wire       ID_valid_data_write_EX;
wire       EX_valid_data_write_MEM;

assign     valid_data_write = EX_valid_data_write_MEM;


// ---------------------------------- Implementation of modules

IF_HK #(.XLEN(XLEN)) u_IF_HK (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(internal_core_pause),

    //Flags
    .valid_instr_fetch(valid_instr_fetch),
    
    //Buses
    .EIB(EIB),      //External Instruction Bus
    .EIAB(EIAB),     //External Instruction Address Bus 
    
    //----------------------------ID Stage
    //Data from/to ID stage
    .ID_exec_result(ID_exec_result_IF),

    .ID_PC_4(IF_PC_4_ID),
    .ID_PC(IF_PC_ID),
    .ID_canonical_instruction(IF_canonical_instruction_ID),

    //Control from/to ID stage
    .ID_sel_next_PC(ID_sel_next_PC_IF)
);


ID #(.XLEN(XLEN)) u_ID (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(internal_core_pause),

    //----------------------------IF_HK Stage
    //Data from/to IF_HK stage
    .IF_PC_4(IF_PC_4_ID),
    .IF_PC(IF_PC_ID),
    .IF_canonical_instruction(IF_canonical_instruction_ID),

    .IF_exec_result(ID_exec_result_IF),

    //Control from/to IF_HK stage
    .IF_sel_next_PC(ID_sel_next_PC_IF),

    //----------------------------EX Stage
    //Data from/to EX stage
    .EX_exec_result(EX_exec_result_ID),
    .EX_RD(EX_RD_ID),
    .EX_RD_addr_in(EX_RD_addr_out_ID),

    .EX_PC_4(ID_PC_4_EX),
    .EX_PC(ID_PC_EX),
    .EX_RS1(ID_RS1_EX),
    .EX_RS2(ID_RS2_EX),
    .EX_RD_addr_out(ID_RD_addr_in_EX),
    .EX_imm(ID_imm_EX),

    //Control from/to EX stage
    .EX_regfile_we_in(EX_regfile_we_out_ID),
    .EX_sel_next_PC(EX_sel_next_PC_ID),

    .EX_sel_exec_result(ID_sel_exec_result_EX),
    .EX_sel_opb(ID_sel_opb_EX),
    .EX_sel_op(ID_sel_op_EX),
    .EX_regfile_we_out(ID_regfile_we_in_EX),
    .EX_jump(ID_jump_EX),
    .EX_branch(ID_branch_EX),

    .EX_mem_wr_en(ID_mem_wr_en_EX),
    .EX_val_rd_type(ID_val_rd_type_EX),
    .EX_val_wr_type(ID_val_wr_type_EX),
    .EX_result_type(ID_result_type_EX),
    
    .EX_sel_writeback(ID_sel_writeback_EX),

    //Flags
    .EX_valid_data_read(ID_valid_data_read_EX),
    .EX_valid_data_write(ID_valid_data_write_EX)

);


EX #(.XLEN(XLEN)) u_EX (
    //Global
    .clk(clk),
    .reset_n(reset_n),

    //----------------------------ID Stage
    //Data from/to ID stage
    .ID_PC_4(ID_PC_4_EX),
    .ID_PC(ID_PC_EX),
    .ID_RS1(ID_RS1_EX),
    .ID_RS2(ID_RS2_EX),
    .ID_RD_addr_in(ID_RD_addr_in_EX),
    .ID_imm(ID_imm_EX),

    .ID_exec_result(EX_exec_result_ID),
    .ID_RD(EX_RD_ID),
    .ID_RD_addr_out(EX_RD_addr_out_ID),

    //Control from/to ID stage
    .ID_sel_opb(ID_sel_opb_EX),
    .ID_sel_op(ID_sel_op_EX),
    .ID_regfile_we_in(ID_regfile_we_in_EX),
    .ID_jump(ID_jump_EX),
    .ID_branch(ID_branch_EX),
    .ID_sel_exec_result(ID_sel_exec_result_EX),

    .ID_mem_wr_en(ID_mem_wr_en_EX),
    .ID_val_rd_type(ID_val_rd_type_EX),
    .ID_val_wr_type(ID_val_wr_type_EX),
    .ID_result_type(ID_result_type_EX),
    
    .ID_sel_writeback(ID_sel_writeback_EX),
    .ID_regfile_we_out(EX_regfile_we_out_ID),
    .ID_sel_next_PC(EX_sel_next_PC_ID),

    //Flags
    .ID_valid_data_read(ID_valid_data_read_EX),
    .ID_valid_data_write(ID_valid_data_write_EX),

    //----------------------------MEM Stage
    //Data from/to MEM stage
    .MEM_RD(MEM_RD_EX),
    .MEM_RD_addr_in(MEM_RD_addr_out_EX),

    .MEM_PC_4(EX_PC_4_MEM),
    .MEM_exec_result(EX_exec_result_MEM),
    .MEM_RS2(EX_RS2_MEM),
    .MEM_RD_addr_out(EX_RD_addr_in_MEM),

    //Control from/to MEM stage
    .MEM_regfile_we_in(MEM_regfile_we_out_EX),

    .MEM_mem_wr_en(EX_mem_wr_en_MEM),
    .MEM_val_rd_type(EX_val_rd_type_MEM),
    .MEM_val_wr_type(EX_val_wr_type_MEM),
    .MEM_result_type(EX_result_type_MEM),

    .MEM_regfile_we_out(EX_regfile_we_in_MEM),
    
    .MEM_sel_writeback(EX_sel_writeback_MEM),

    //Flags
    .MEM_valid_data_read(EX_valid_data_read_MEM),
    .MEM_valid_data_write(EX_valid_data_write_MEM)
);


MEM #(.XLEN(XLEN)) u_MEM (
    //Global
    .clk(clk),
    .reset_n(reset_n),

    // Buses
    .EMAB(EMAB), //Memory Address
    .EMCB(EMCB), //Memory Control
    .EMDB_in(EMDB_in), //Memory Data
    .EMDB_out(EMDB_out),

    //----------------------------EX Stage
    //Data from/to EX stage
    .EX_PC_4(EX_PC_4_MEM),
    .EX_exec_result(EX_exec_result_MEM),
    .EX_RS2(EX_RS2_MEM),
    .EX_RD_addr_in(EX_RD_addr_in_MEM),

    .EX_RD(MEM_RD_EX),
    .EX_RD_addr_out(MEM_RD_addr_out_EX),

    //Control from/to EX stage
    .EX_mem_wr_en(EX_mem_wr_en_MEM),
    .EX_val_rd_type(EX_val_rd_type_MEM),
    .EX_val_wr_type(EX_val_wr_type_MEM),
    .EX_result_type(EX_result_type_MEM),
    
    .EX_regfile_we_in(EX_regfile_we_in_MEM),

    .EX_sel_writeback(EX_sel_writeback_MEM),

    .EX_regfile_we_out(MEM_regfile_we_out_EX),

    //----------------------------WB Stage
    //Data from/to WB stage
    .WB_RD(WB_RD_MEM),
    .WB_RD_addr_in(WB_RD_addr_out_MEM),
    .WB_regfile_we_in(WB_regfile_we_out_MEM),

    .WB_PC_4(MEM_PC_4_WB),
    .WB_exec_result(MEM_exec_result_WB),
    .WB_EMDB(MEM_EMDB_WB),
    .WB_RD_addr_out(MEM_RD_addr_in_WB),
    .WB_regfile_we_out(MEM_regfile_we_in_WB),

    //Control from/to WB stage
    .WB_sel_writeback(MEM_sel_writeback_WB)
);


WB #(.XLEN(XLEN)) u_WB (
    //Global
    .clk(clk),
    .reset_n(reset_n),

    //----------------------------MEM Stage
    //Data from/to MEM stage
    .MEM_PC_4(MEM_PC_4_WB),
    .MEM_exec_result(MEM_exec_result_WB),
    .MEM_EMDB(MEM_EMDB_WB),
    .MEM_RD_addr_in(MEM_RD_addr_in_WB),
    .MEM_regfile_we_in(MEM_regfile_we_in_WB),

    .MEM_RD(WB_RD_MEM),
    .MEM_RD_addr_out(WB_RD_addr_out_MEM),
    .MEM_regfile_we_out(WB_regfile_we_out_MEM),

    //Control from/to WB stage
    .WB_sel_writeback(MEM_sel_writeback_WB)
);

//-------------------------------------- Extra -> Module for used for verification commits

`ifndef SYNTHESIS
    verification_commits #(.XLEN(XLEN)) u_verification_commits(
        //Signals retrieved from the core
        .IF_PC(IF_PC_ID),
        .IF_canonical_instruction(IF_canonical_instruction_ID),
        
        .WB_regfile_we(WB_regfile_we_out_MEM),
        .WB_RD_addr(WB_RD_addr_out_MEM),
        .WB_RD(WB_RD_MEM),

        //Output used for the framework
        .commit_valid(commit_valid),
        .commit_PC(commit_PC),
        .commit_rd_addr(commit_rd_addr),
        .commit_rd_value(commit_rd_value),
        .commit_instruction(commit_instruction)
    );
`endif


endmodule