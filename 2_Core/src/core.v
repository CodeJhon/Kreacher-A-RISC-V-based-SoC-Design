module core #(parameter XLEN = 64)(//RV64I
    //Global
    input clk,
    input reset_n,

    // Interrupt pins (assumed to be synchronous)
    input irq0_sync,       
    input irq1_sync,

    output wire acknowledge_irq0,
    output wire acknowledge_irq1,

    //Flags
    output            valid_instr_fetch,
    output            valid_data_read,
    output            valid_data_write,

    //Pause requests (external)
    input             pause_request_scheduler,
    input             pause_request_initialization,
    input             pause_request_load_store,
    input             pause_request_partial_store,

    //Buses
    input  [31:0]     EIB,             //External Instruction Bus
    output [16:0]     EIAB,            //External Instruction Address Bus

    output [XLEN-1:0] EMAB,            //External Memory Address Bus
    output            EMCB,            //External Memory Control Bus
    output [XLEN-1:0] EMCB_mask,       //External Memory Control Bus -> Bit Mask
    output [XLEN-1:0] EMDB_out,        //External Memory Data Bus, output for the core, input for the external memory
    input  [XLEN-1:0] EMDB_in          //External Memory Data Bus, input for the core, output for the external memory
    
);

//------------------------------------------------------------ Pause signals

//Synchronized reset
wire reset_n_sync;

//Pause requests
wire IF_pause_request;
wire EX_pause_request;

//Stage pauses
wire pause_IF;
wire pause_ID;
wire pause_EX;

//Indicator of next stage
wire next_stage_en;

//------------------------------------- Interrupt Handler signals
//Inputs needed 
wire [XLEN-1:0] IF_next_program_PC;
wire [XLEN-1:0] IF_PC_step;
wire            mie;

//Outpus generated
wire             interrupt_mepc_we;
wire [XLEN-1:0]  interrupt_PC_to_mepc;


/*
    --- Wire terminology for Stage signals ---
    wire [LENGHT:0] (Fom Stage X)_Signal_Name_(To stage Y)
*/

//------------------------------------- Stage Data signals (Not for buses)

//exec_result
wire [XLEN-1:0] ID_exec_result_IF;
wire [XLEN-1:0] EX_exec_result_ID;
wire [XLEN-1:0] EX_exec_result_MEM;
wire [XLEN-1:0] MEM_exec_result_WB;

//PC_step
wire [XLEN-1:0] IF_PC_step_ID;
wire [XLEN-1:0] ID_PC_step_EX;
wire [XLEN-1:0] EX_PC_step_MEM;
wire [XLEN-1:0] MEM_PC_step_WB;

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

//csr_data_wr
wire [XLEN-1:0] WB_csr_data_wr_MEM;
wire [XLEN-1:0] MEM_csr_data_wr_EX;
wire [XLEN-1:0] EX_csr_data_wr_ID;

//csr_data_rd
wire [XLEN-1:0] ID_csr_data_rd_EX;
wire [XLEN-1:0] EX_csr_data_rd_MEM;
wire [XLEN-1:0] MEM_csr_data_rd_WB;

//csr_addr_wr_in
wire [11:0] ID_csr_addr_wr_in_EX;
wire [11:0] EX_csr_addr_wr_in_MEM;
wire [11:0] MEM_csr_addr_wr_in_WB;

//csr_addr_wr_out
wire [11:0] WB_csr_addr_wr_out_MEM;
wire [11:0] MEM_csr_addr_wr_out_EX;
wire [11:0] EX_csr_addr_wr_out_ID;

//------------------------------------- Stage Control (Not for buses)

//control_transfer_en
wire  EX_control_transfer_en_ID;
wire  ID_control_transfer_en_IF;

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

//sel_opa
wire [1:0] ID_sel_opa_EX;

//sel_opb
wire [1:0] ID_sel_opb_EX;

//sel_op
wire [5:0] ID_sel_op_EX;

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

assign     valid_data_read = EX_valid_data_read_MEM & (~IF_pause_request);

//valid_data_write
wire       ID_valid_data_write_EX;
wire       EX_valid_data_write_MEM;

assign     valid_data_write = EX_valid_data_write_MEM & (~IF_pause_request);

//csr_we_in
wire ID_csr_we_in_EX;
wire EX_csr_we_in_MEM;
wire MEM_csr_we_in_WB;

//csr_we_out
wire WB_csr_we_out_MEM;
wire MEM_csr_we_out_EX;
wire EX_csr_we_out_ID;

//restore_mstatus_in
wire ID_restore_mstatus_in_EX;

//restore_mstatus_out
wire EX_restore_mstatus_out_ID;

//sleep
wire ID_sleep_EX;
wire EX_sleep_MEM;

//illegal_trap
wire ID_illegal_trap_IF;

// ---------------------------------- Implementation of modules

pause_handler u_pause_handler (
    //Global
    .clk                (clk),
    .reset_n            (reset_n),

    //Flags
    .reset_n_sync       (reset_n_sync),

    // Interrupt pins (assumed to be synchronous)
    .irq0_sync          (irq0_sync),
    .irq1_sync          (irq1_sync),
    
    //Control
    .sleep              (EX_sleep_MEM),

    //Pause requests (external)
    .pause_request_scheduler        (pause_request_scheduler),
    .pause_request_initialization   (pause_request_initialization),
    .pause_request_load_store       (pause_request_load_store),
    .pause_request_partial_store    (pause_request_partial_store),
    
    //Pause requests (internal)
    .IF_pause_request   (IF_pause_request),
    .EX_pause_request   (EX_pause_request),
    
    //Output to stages
    .pause_IF           (pause_IF),
    .pause_ID           (pause_ID),
    .pause_EX           (pause_EX),

    //Indicator of next stage
    .next_stage_en       (next_stage_en)
);


wire IF_valid_instr_fetch;
IF_HK #(.XLEN(XLEN)) u_IF_HK (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(pause_IF),

    //Special pause signal
    .EX_pause_request   (EX_pause_request),
    
    //Interrupt Handler
    .acknowledge_irq0(acknowledge_irq0),
    .acknowledge_irq1(acknowledge_irq1),

    .next_program_PC(IF_next_program_PC),
    .PC_step(IF_PC_step),

    //Flags
    .IF_valid_instr_fetch(IF_valid_instr_fetch),
    
    //Buses
    .EIB(EIB),      //External Instruction Bus
    .EIAB(EIAB),     //External Instruction Address Bus 

    //Control
    .IF_pause_request(IF_pause_request),
    
    //----------------------------ID Stage
    //Data from/to ID stage
    .ID_exec_result(ID_exec_result_IF),

    .ID_PC_step(IF_PC_step_ID),
    .ID_PC(IF_PC_ID),
    
    .ID_canonical_instruction(IF_canonical_instruction_ID),

    //Control from/to ID stage
    .ID_control_transfer_en(ID_control_transfer_en_IF),
    .ID_illegal_trap(ID_illegal_trap_IF)
);


ID #(.XLEN(XLEN)) u_ID (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(pause_ID),

    //Interrupt Handler
    .acknowledge_irq0(acknowledge_irq0),
    .acknowledge_irq1(acknowledge_irq1),

    .interrupt_mepc_we(interrupt_mepc_we),
    .interrupt_PC_to_mepc(interrupt_PC_to_mepc),
    .mie(mie),

    //----------------------------IF_HK Stage
    //Data from/to IF_HK stage
    .IF_PC_step(IF_PC_step_ID),
    .IF_PC(IF_PC_ID),
    .IF_canonical_instruction(IF_canonical_instruction_ID),

    .IF_exec_result(ID_exec_result_IF),

    //Control from/to IF_HK stage
    .IF_control_transfer_en(ID_control_transfer_en_IF),
    .IF_illegal_trap(ID_illegal_trap_IF),

    //----------------------------EX Stage
    //Data from/to EX stage
    .EX_exec_result(EX_exec_result_ID),
    .EX_RD(EX_RD_ID),
    .EX_RD_addr_in(EX_RD_addr_out_ID),
    .EX_csr_data_wr(EX_csr_data_wr_ID),
    .EX_csr_addr_wr_in(EX_csr_addr_wr_out_ID),

    .EX_PC_step(ID_PC_step_EX),
    .EX_PC(ID_PC_EX),
    .EX_RS1(ID_RS1_EX),
    .EX_RS2(ID_RS2_EX),
    .EX_RD_addr_out(ID_RD_addr_in_EX),
    .EX_imm(ID_imm_EX),
    .EX_csr_data_rd(ID_csr_data_rd_EX),
    .EX_csr_addr_wr_out(ID_csr_addr_wr_in_EX),

    //Control from/to EX stage
    .EX_regfile_we_in(EX_regfile_we_out_ID),
    .EX_control_transfer_en(EX_control_transfer_en_ID),
    .EX_csr_we_in(EX_csr_we_out_ID),
    .EX_restore_mstatus_in(EX_restore_mstatus_out_ID),

    .EX_sel_exec_result(ID_sel_exec_result_EX),
    .EX_sel_opa(ID_sel_opa_EX),
    .EX_sel_opb(ID_sel_opb_EX),
    .EX_sel_op(ID_sel_op_EX),
    .EX_regfile_we_out(ID_regfile_we_in_EX),
    .EX_jump(ID_jump_EX),
    .EX_branch(ID_branch_EX),
    .EX_csr_we_out(ID_csr_we_in_EX),
    .EX_restore_mstatus_out(ID_restore_mstatus_in_EX),

    .EX_mem_wr_en(ID_mem_wr_en_EX),
    .EX_val_rd_type(ID_val_rd_type_EX),
    .EX_val_wr_type(ID_val_wr_type_EX),
    .EX_result_type(ID_result_type_EX),
    .EX_sleep(ID_sleep_EX),
    
    .EX_sel_writeback(ID_sel_writeback_EX),

    //Flags
    .EX_valid_data_read(ID_valid_data_read_EX),
    .EX_valid_data_write(ID_valid_data_write_EX)

);


EX #(.XLEN(XLEN)) u_EX (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(pause_EX),

    //Control
    .EX_pause_request(EX_pause_request),

    //----------------------------ID Stage
    //Data from/to ID stage
    .ID_PC_step(ID_PC_step_EX),
    .ID_PC(ID_PC_EX),
    .ID_RS1(ID_RS1_EX),
    .ID_RS2(ID_RS2_EX),
    .ID_RD_addr_in(ID_RD_addr_in_EX),
    .ID_imm(ID_imm_EX),
    .ID_csr_data_rd(ID_csr_data_rd_EX),
    .ID_csr_addr_wr_in(ID_csr_addr_wr_in_EX),

    .ID_exec_result(EX_exec_result_ID),
    .ID_RD(EX_RD_ID),
    .ID_RD_addr_out(EX_RD_addr_out_ID),
    .ID_csr_data_wr(EX_csr_data_wr_ID),
    .ID_csr_addr_wr_out(EX_csr_addr_wr_out_ID),

    //Control from/to ID stage
    .ID_sel_opa(ID_sel_opa_EX),
    .ID_sel_opb(ID_sel_opb_EX),
    .ID_sel_op(ID_sel_op_EX),
    .ID_regfile_we_in(ID_regfile_we_in_EX),
    .ID_jump(ID_jump_EX),
    .ID_branch(ID_branch_EX),
    .ID_sel_exec_result(ID_sel_exec_result_EX),
    .ID_csr_we_in(ID_csr_we_in_EX),
    .ID_restore_mstatus_in(ID_restore_mstatus_in_EX),

    .ID_mem_wr_en(ID_mem_wr_en_EX),
    .ID_val_rd_type(ID_val_rd_type_EX),
    .ID_val_wr_type(ID_val_wr_type_EX),
    .ID_result_type(ID_result_type_EX),
    .ID_sleep(ID_sleep_EX),
    
    .ID_sel_writeback(ID_sel_writeback_EX),
    .ID_regfile_we_out(EX_regfile_we_out_ID),
    .ID_control_transfer_en(EX_control_transfer_en_ID),
    .ID_csr_we_out(EX_csr_we_out_ID),
    .ID_restore_mstatus_out(EX_restore_mstatus_out_ID),

    //Flags
    .ID_valid_data_read(ID_valid_data_read_EX),
    .ID_valid_data_write(ID_valid_data_write_EX),

    //----------------------------MEM Stage
    //Data from/to MEM stage
    .MEM_RD(MEM_RD_EX),
    .MEM_RD_addr_in(MEM_RD_addr_out_EX),
    .MEM_csr_data_wr(MEM_csr_data_wr_EX),
    .MEM_csr_addr_wr_in(MEM_csr_addr_wr_out_EX),

    .MEM_PC_step(EX_PC_step_MEM),
    .MEM_exec_result(EX_exec_result_MEM),
    .MEM_RS2(EX_RS2_MEM),
    .MEM_RD_addr_out(EX_RD_addr_in_MEM),
    .MEM_csr_data_rd(EX_csr_data_rd_MEM),
    .MEM_csr_addr_wr_out(EX_csr_addr_wr_in_MEM),

    //Control from/to MEM stage
    .MEM_regfile_we_in(MEM_regfile_we_out_EX),
    .MEM_csr_we_in(MEM_csr_we_out_EX),

    .MEM_mem_wr_en(EX_mem_wr_en_MEM),
    .MEM_val_rd_type(EX_val_rd_type_MEM),
    .MEM_val_wr_type(EX_val_wr_type_MEM),
    .MEM_result_type(EX_result_type_MEM),
    .MEM_csr_we_out(EX_csr_we_in_MEM),
    .MEM_sleep(EX_sleep_MEM),

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
    .EMCB_mask(EMCB_mask), //Memory Bit mask
    .EMDB_in(EMDB_in), //Memory Data
    .EMDB_out(EMDB_out),

    //----------------------------EX Stage
    //Data from/to EX stage
    .EX_PC_step(EX_PC_step_MEM),
    .EX_exec_result(EX_exec_result_MEM),
    .EX_RS2(EX_RS2_MEM),
    .EX_RD_addr_in(EX_RD_addr_in_MEM),
    .EX_csr_data_rd(EX_csr_data_rd_MEM),
    .EX_csr_addr_wr_in(EX_csr_addr_wr_in_MEM),

    .EX_RD(MEM_RD_EX),
    .EX_RD_addr_out(MEM_RD_addr_out_EX),
    .EX_csr_data_wr(MEM_csr_data_wr_EX),
    .EX_csr_addr_wr_out(MEM_csr_addr_wr_out_EX),

    //Control from/to EX stage
    .EX_mem_wr_en(EX_mem_wr_en_MEM),
    .EX_val_rd_type(EX_val_rd_type_MEM),
    .EX_val_wr_type(EX_val_wr_type_MEM),
    .EX_result_type(EX_result_type_MEM),
    .EX_csr_we_in(EX_csr_we_in_MEM),
    
    .EX_regfile_we_in(EX_regfile_we_in_MEM),

    .EX_sel_writeback(EX_sel_writeback_MEM),

    .EX_regfile_we_out(MEM_regfile_we_out_EX),
    .EX_csr_we_out(MEM_csr_we_out_EX),

    //----------------------------WB Stage
    //Data from/to WB stage
    .WB_RD(WB_RD_MEM),
    .WB_RD_addr_in(WB_RD_addr_out_MEM),
    .WB_csr_data_wr(WB_csr_data_wr_MEM),
    .WB_csr_addr_wr_in(WB_csr_addr_wr_out_MEM),

    .WB_PC_step(MEM_PC_step_WB),
    .WB_exec_result(MEM_exec_result_WB),
    .WB_EMDB(MEM_EMDB_WB),
    .WB_RD_addr_out(MEM_RD_addr_in_WB),
    .WB_csr_data_rd(MEM_csr_data_rd_WB),
    .WB_csr_addr_wr_out(MEM_csr_addr_wr_in_WB),
    

    //Control from/to WB stage
    .WB_regfile_we_in(WB_regfile_we_out_MEM),
    .WB_csr_we_in(WB_csr_we_out_MEM),

    .WB_regfile_we_out(MEM_regfile_we_in_WB),
    .WB_csr_we_out(MEM_csr_we_in_WB),
    .WB_sel_writeback(MEM_sel_writeback_WB)
);


WB #(.XLEN(XLEN)) u_WB (
    //Global
    .clk(clk),
    .reset_n(reset_n),

    //----------------------------MEM Stage
    //Data from/to MEM stage
    .MEM_PC_step(MEM_PC_step_WB),
    .MEM_exec_result(MEM_exec_result_WB),
    .MEM_EMDB(MEM_EMDB_WB),
    .MEM_RD_addr_in(MEM_RD_addr_in_WB),
    .MEM_csr_data_rd(MEM_csr_data_rd_WB),
    .MEM_csr_addr_wr_in(MEM_csr_addr_wr_in_WB),

    .MEM_RD(WB_RD_MEM),
    .MEM_RD_addr_out(WB_RD_addr_out_MEM),
    .MEM_csr_data_wr(WB_csr_data_wr_MEM),
    .MEM_csr_addr_wr_out(WB_csr_addr_wr_out_MEM),
    

    //Control from/to WB stage
    .MEM_regfile_we_in(MEM_regfile_we_in_WB),
    .MEM_sel_writeback(MEM_sel_writeback_WB),
    .MEM_csr_we_in(MEM_csr_we_in_WB),

    .MEM_regfile_we_out(WB_regfile_we_out_MEM),
    .MEM_csr_we_out(WB_csr_we_out_MEM)
);

wire core_program_jump = ID_control_transfer_en_IF | ID_illegal_trap_IF; 
interrupt_handler #(.XLEN(XLEN), .WB(3'd1)) u_interrupt_handler (
    //Global
    .clk(clk),
    .reset_n(reset_n),

    // Interrupt pins (assumed to be synchronous)
    .irq0_sync(irq0_sync),
    .irq1_sync(irq1_sync),

    .acknowledge_irq0(acknowledge_irq0),
    .acknowledge_irq1(acknowledge_irq1),
    
    //PC signals (from IF stage)
    .PC_step(IF_PC_step),
    .next_program_PC(IF_next_program_PC),

    //Control
    .core_program_jump(core_program_jump),
    .next_stage_en(next_stage_en),
    .mie(mie),

    //Outputs to core
    .interrupt_mepc_we(interrupt_mepc_we),
    .interrupt_PC_to_mepc(interrupt_PC_to_mepc)
);

//-------------------------- Output assignations
assign valid_instr_fetch = IF_valid_instr_fetch | ~reset_n_sync;


endmodule