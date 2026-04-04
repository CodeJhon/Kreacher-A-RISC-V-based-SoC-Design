// =============================================================================
// File        : csr_mask.v
// Author      : Jhon Steven Pinto Hernandez
// Email       : jhonstevenpintoh@gmail.com
// Description :
//   Generates CSR access masks and privilege filtering for CSR operations in the pipelined core.
// =============================================================================

`include "../../include/CORE_CONSTANTS.vh"

module csr_mask #(parameter XLEN = 64)(
    input      [XLEN-1:0] in_raw,
    input      [11:0]     csr_addr,
    
    input      [XLEN-1:0] old_mcause,

    output reg [XLEN-1:0] out_masked
);

wire mstatus_mpie = in_raw[7];
wire mstatus_mie  = in_raw[3];

wire [XLEN-1:0] mstatus_mask = {//CSR construction
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

wire [XLEN-1:0] mepc_mask   =   {in_raw[XLEN-1:1] , 1'b0}; // always mepc[0] = 0 since IALIGN = 16

localparam MCAUSE_MASK      = {1'b0, 63'd2}; //MCause: Illegal instruction

always @( * ) begin
    case (csr_addr)
        `MSTATUS_ADDR: 
            out_masked = mstatus_mask;

        `MEPC_ADDR:    
            out_masked = mepc_mask;

        `MCAUSE_ADDR:begin//Only writable cause by software: Illegal instruction cause
            if(in_raw == `MCAUSE_ILLEGAL)
                out_masked = in_raw;
            else
                out_masked = old_mcause; 
        end  

        default:    
            out_masked = in_raw;
    endcase
end

endmodule