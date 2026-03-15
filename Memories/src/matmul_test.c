#include <stdint.h>

#if defined(__riscv)
#include "corelib.h"
__attribute__((section(".exit_value")))
volatile uint32_t exit_value;
#else
#include <stdio.h>
#endif

static uint32_t signature_test(void) {
    static int32_t A[16][16];
    static int32_t B[16][16];
    static int32_t C[16][16];

    for (uint32_t i = 0; i < 16; i++) {
        for (uint32_t j = 0; j < 16; j++) {
            A[i][j] = (int32_t)((i * 17u + j * 7u + 3u) & 0xffu) - 128;
            B[i][j] = (int32_t)((i * 11u + j * 13u + 5u) & 0xffu) - 128;
            C[i][j] = 0;
        }
    }

    for (uint32_t i = 0; i < 16; i++) {
        for (uint32_t j = 0; j < 16; j++) {
            int64_t sum = 0;
            for (uint32_t k = 0; k < 16; k++) {
                sum += (int64_t)A[i][k] * (int64_t)B[k][j];
            }
            C[i][j] = (int32_t)sum;
        }
    }

#if !defined(__riscv)
    printf("Matrix multiplication result C=A*B:\n");
    for (uint32_t i = 0; i < 16; i++) {
        for (uint32_t j = 0; j < 16; j++) {
            printf("%8d ", C[i][j]);
        }
        printf("\n");
    }
#endif

    uint64_t acc = 0x510e527fade682d1ULL;
    for (uint32_t i = 0; i < 16; i++) {
        for (uint32_t j = 0; j < 16; j++) {
            acc ^= (uint64_t)(uint32_t)C[i][j];
            acc += ((uint64_t)(uint32_t)C[i][j] << ((i + j) & 15u));

            if (C[i][j] < 0) acc ^= 0x1111u;
            else             acc += 0x2222u;

            switch ((i + j) & 3u) {
                case 0: acc += 0x11111111ULL; break;
                case 1: acc ^= 0x22222222ULL; break;
                case 2: acc -= 0x33333333ULL; break;
                default: acc ^= (acc >> 11);  break;
            }
        }
    }

    return (uint32_t)(acc ^ (acc >> 32));
}

int main(void) {
    uint32_t sig = signature_test();

#if defined(__riscv)
    exit_value = sig;
#else
    printf("matmul_signature=0x%08x\n", sig);
    //matmul_signature=0x0d33d2c9
#endif

    return (int)sig;
}