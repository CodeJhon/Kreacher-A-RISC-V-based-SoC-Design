#include <stdint.h>

#if defined(__riscv)
/* In the project framework, corelib provides startup/linker and an exit_value section. */
#include "corelib.h"

/* Put result into the framework-defined section so testbench can read it from DTCM (0x4000). */
__attribute__((section(".exit_value")))
volatile uint32_t exit_value;

#else
/* On Windows/host, use stdio for printing */
#include <stdio.h>
#endif

static inline uint64_t rotl64(uint64_t x, unsigned r) {
    r &= 63u;
    return (x << r) | (x >> ((64u - r) & 63u));
}

static uint32_t signature_test(void) {
    /* Static buffers: avoid huge stack on any platform */
    static uint8_t  b8[256];
    static uint16_t b16[128];
    static uint32_t b32[128];
    static uint64_t b64[128];

    /* Init: stores */
    for (uint32_t i = 0; i < 256; i++) b8[i]  = (uint8_t)(i * 3u + 1u);
    for (uint32_t i = 0; i < 128; i++) b16[i] = (uint16_t)(i * 5u + 7u);
    for (uint32_t i = 0; i < 128; i++) b32[i] = (uint32_t)(0x9e3779b9u ^ i);
    for (uint32_t i = 0; i < 128; i++) b64[i] = 0x0123456789abcdefULL ^ (uint64_t)i;

    uint64_t acc = 0x6a09e667f3bcc909ULL;
    uint64_t a   = 0xdeadbeefcafebabeULL;
    uint64_t b   = 0x0123456789abcdefULL;

    for (uint32_t i = 0; i < 128; i++) {
        /* loads (multi-width) */
        uint64_t x8  = (uint64_t)(uint8_t)(b8[i] ^ b8[i + 1]);
        uint64_t x16 = (uint64_t)(uint16_t)(b16[i] + (uint16_t)(b8[i] << 8));
        uint64_t x32 = (uint64_t)(uint32_t)(b32[i] ^ (uint32_t)(x16 * 13u));
        uint64_t x64 = b64[i] + (x32 << (i & 31u));

        /* ALU + shifts */
        a   = (a + x64) ^ rotl64(b, i);
        b   = (b - x32) + (a | (x16 << 17));
        acc ^= (a & b) + (x8 | (x64 >> 3));

        /* compares + branches */
        if ((int64_t)a < (int64_t)b) acc += 0x1111u; else acc ^= 0x2222u;
        if (a < b)                   acc += 0x33u;   else acc ^= 0x55u;

        /* RV64M-ish ops (mul/div/rem) */
        uint64_t den1 = (x32 | 3ULL) + 1ULL;
        uint64_t den2 = (x16 | 5ULL) + 1ULL;
        uint64_t m1   = (a ^ x64) * (b | 1ULL);
        uint64_t d1   = m1 / den1;
        uint64_t r1   = m1 % den2;
        acc ^= (d1 + r1);

        /* Signed div/rem */
        int64_t sa = (int64_t)(a | 1ULL);
        int64_t sb = (int64_t)(b | 3ULL);
        acc ^= (uint64_t)(sa / sb);
        acc ^= (uint64_t)(sa % sb);

        /* 32-bit arithmetic (encourage W-path) */
        int32_t  w0  = (int32_t)(acc ^ (acc >> 32));
        int32_t  w1  = (int32_t)((uint32_t)x32 + i);
        int32_t  w2  = (w0 + w1) ^ (w0 - w1);
        int32_t  w3  = (w2 >> (i & 31u)) ^ (w2 << (i & 31u));
        uint32_t uw2 = (uint32_t)w2;
        uint32_t uw3 = (uw2 >> (i & 31u)) ^ (uw2 << (i & 31u));

        int32_t  dw  = w3 / (w1 | 1);
        int32_t  rw  = w3 % (w1 | 3);
        uint32_t duw = uw3 / (uw2 | 1u);
        uint32_t ruw = uw3 % (uw2 | 3u);

        acc ^= (uint64_t)(uint32_t)dw ^ ((uint64_t)(uint32_t)rw << 7);
        acc ^= (uint64_t)duw ^ ((uint64_t)ruw << 9);

        /* switch (more control flow) */
        switch (i & 3u) {
            case 0: acc += 0x11111111ULL; break;
            case 1: acc ^= 0x22222222ULL; break;
            case 2: acc -= 0x33333333ULL; break;
            default: acc = rotl64(acc, 7); break;
        }

        /* more stores */
        b64[i] ^= acc;
        b32[i] += (uint32_t)acc;
    }

    return (uint32_t)(acc ^ (acc >> 32));
}

int main(void) {
    uint32_t sig = signature_test();

#if defined(__riscv)
    /* Framework verification: testbench reads this from .exit_value / DTCM */
    exit_value = sig;
#else
    /* Windows/host: print signature */
    printf("signature=0x%08x\n", sig);
#endif

    return (int)sig;
    //signature=0x857319ea
}