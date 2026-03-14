`include "../../include/CORE_CONSTANTS.vh"

module csr_bank  #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Interrupt Handler
    input                 take_interrupt_0,
    input                 take_interrupt_1,
    
    input                 interrupt_mepc_we,
    input      [XLEN-1:0] interrupt_PC_to_mepc,
    output                mie,

    //Illegal Instruction 
    input                 illegal_trap,
    input      [XLEN-1:0] PC_illegal,

    //MRET signals
    input                 restore_mstatus,

    //Inputs/Outputs from/to Zicsr HW
    input                 csr_we, //Write-enable
    input                 csr_re, //Read-enable

    input      [11:0]     csr_addr_rd,
    input      [11:0]     csr_addr_wr,
    input      [XLEN-1:0] csr_data_wr,
    output reg [XLEN-1:0] csr_data_rd

);

//Notes:
//  Illegal CSR access is raised for:
//   - any unsupported CSR address
//   - any write attempt to a read-only CSR (misa, mtvec)


//--------------------------------------------------------------------------  mstatus (RW) - Machine status register for interrupt-enable
reg mstatus_mie;
reg mstatus_mpie;
    
wire [XLEN-1:0] mstatus = {//CSR construction
    //  ----- WPRI------ | Disabled: -> SD, SXL, UXL, TSR, TW, TVM, MXR, SUM, MPRV, XS, FS
    {(((XLEN - 37) + 9) + 15){1'b0}},
    2'b11,                                  //MPP Fixed(Machine mode = 3)
    //WPRI | Disabled: -> SPP
    {((2) + 1){1'b0}},
    mstatus_mpie,                           //MPIE Writable
    //WPRI | Disabled: -> SPIE, UPIE
    {((2) + 1){1'b0}},
    mstatus_mie,                            //MIE Writable
    //WPRI | Disabled: -> SIE, UIE
    {((2) + 1){1'b0}}
};

//--------------------------------------------------------------------------  mepc (RW) - Machine exception program counter
reg [XLEN-1:1] mepc_reg;
wire [XLEN-1:0] mepc = {mepc_reg , 1'b0}; // always mepc[0] = 0 since IALIGN = 16

//--------------------------------------------------------------------------  mcause (RW) - Machine cause register
//      Note -> MSB shall not be writtable by SW and only legal exception codes can be stored 
reg [XLEN-1:0] mcause;

//Exception code Whitelist 
wire mcause_sw_writable = (csr_data_wr == `MCAUSE_ILLEGAL); //Only legal exception code writable by software: Illegal instruction

//---------------------------------------------------------------------------  misa (R) - Machine ISA register
localparam MISA = {//CSR construction
    2'b10,                          // MXL (XLEN = 64, then MXL = 2)
    {(XLEN-3 - 26 + 1){1'b0}},      // WLRL (Fixed as 0)
    //---------ISA Extensions
    {(25 - 13 +1){1'b0}},           // Z to N (Unsupported)
    1'b1,                           // M (Supported)
    {(11 - 9 +1){1'b0}},            // J to L (Unsupported)
    1'b1,                           // I (Supported)
    {(7 - 3 +1){1'b0}},             // H to D (Unsupported)
    1'b1,                           // C (Supported)
    {(1 - 0 +1){1'b0}} };           // A to B (Unsupported) 

//---------------------------------------------------------------------------  mtvec (R) - machine trap-vector base address
localparam MTVEC = {//CSR construction
    {(XLEN-1 - 2 +1){1'b0}}, //Base = 0
    1'b1 };                  //Mode = 1


//------------------------------------------------------------ Module implementation (Writable CSRs)

//Writing mepc -> by interrupt or illegal instruction
wire mepc_we = interrupt_mepc_we | illegal_trap;

//Value of PC to be stored in mepc
reg [XLEN-1:0] PC_to_mepc;
always @( * ) begin
    PC_to_mepc = {XLEN{1'b0}};
    //Interrupts have higher priority than illegal instructions
    if(interrupt_mepc_we)
        PC_to_mepc = interrupt_PC_to_mepc;
    else if(illegal_trap)
        PC_to_mepc = PC_illegal;
end

//CSR Writing
wire trap_taken = ~pause &( take_interrupt_0 | 
                            take_interrupt_1 | 
                            illegal_trap);

always @(posedge clk, negedge reset_n) begin    

    if(!reset_n)begin
        mstatus_mie  <= 1'b0;
        mstatus_mpie <= 1'b0;
        mepc_reg     <= {(XLEN-1){1'b0}};
        mcause       <= {XLEN{1'b0}};
    end
    
    else if(!pause) begin
        //-----------Writing done by Interrupt Hardware (Priority over Zicsr)
        if(mepc_we)begin
            mepc_reg   <= PC_to_mepc[XLEN-1:1];
        end

        if(trap_taken)begin
            //mie & mpie
            mstatus_mie <= 1'b0;
            mstatus_mpie <= mstatus_mie;

            //mcause
            if(take_interrupt_0)
                mcause <= `MCAUSE_IRQ0;
            else if(take_interrupt_1)
                mcause <= `MCAUSE_IRQ1;
            else if(illegal_trap)    
                mcause <= `MCAUSE_ILLEGAL;
        end

        //-----------Writing done by the MRET instruction
        else if(restore_mstatus)begin
            mstatus_mie <= mstatus_mpie;
            mstatus_mpie <= 1'b1;
        end
        
        //-------------Writing done by Zicsr
        if(csr_we)begin
            case (csr_addr_wr)
                `MSTATUS_ADDR: 
                    if(!trap_taken && !restore_mstatus)
                        {mstatus_mpie, mstatus_mie} <= {csr_data_wr[7], csr_data_wr[3]};
                `MEPC_ADDR:
                    if(!mepc_we)    
                        mepc_reg   <= csr_data_wr[XLEN-1:1];
                `MCAUSE_ADDR:
                    if(!trap_taken && !restore_mstatus)
                        if (mcause_sw_writable) 
                            mcause <= csr_data_wr;
            endcase
        end  
    end
    
end

//CSR Reading
always @( * )begin
    //Default case
    csr_data_rd      = {XLEN{1'b0}};
    
    if(csr_re)begin
        case (csr_addr_rd)
            `MSTATUS_ADDR: csr_data_rd = mstatus;
            `MEPC_ADDR:    csr_data_rd = mepc;
            `MCAUSE_ADDR:  csr_data_rd = mcause;
            `MISA_ADDR:    csr_data_rd = MISA;
            `MTVEC_ADDR:   csr_data_rd = MTVEC;    
        endcase    
    end
end


//-------------------------------- Outputs to interrupt handler
assign mie = mstatus_mie;

endmodule