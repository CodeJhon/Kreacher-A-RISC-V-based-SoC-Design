ENTRY(_start)
<<<<<<< HEAD:0_Verification/auto_test/linker.ld
=======

>>>>>>> 09e5679 (Generate RV64 program for DMEM test.):3_Verification/auto_test/linker.ld
SECTIONS
{
    . = 0x80000000;

<<<<<<< HEAD:0_Verification/auto_test/linker.ld
    .text : { *(.text*) }
    .rodata : { *(.rodata*) }
    .data : { *(.data*) }
    .bss : { *(.bss*) }
=======
    /* ---------- code ---------- */
    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    /* ---------- data ---------- */
    .data : {
        *(.data*)
    }

    /* ---------- custom test region ---------- */
    . = 0x80020000;
    . = ALIGN(64);
    .program_memory : {
        *(.program_memory)
    }

    /* ---------- custom test region ---------- */
    . = ALIGN(64);
    .region_0 : {
        *(.region_0)
    }

    /* ---------- custom test region ---------- */
    . = ALIGN(64);
    .region_1 : {
        *(.region_1)
    }

    /* ---------- custom test region ---------- */
    . = ALIGN(64);
    .region_2 : {
        *(.region_2)
    }

    /* ---------- custom test region ---------- */
    . = ALIGN(64);
    .region_3 : {
        *(.region_3)
    }


    /* ---------- bss ---------- */
    .bss : {
        *(.bss*)
        *(COMMON)
    }
>>>>>>> 09e5679 (Generate RV64 program for DMEM test.):3_Verification/auto_test/linker.ld
}
