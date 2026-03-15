#include <stdint.h>

#if defined(__riscv)
#include "corelib.h"
__attribute__((section(".exit_value")))
volatile uint32_t exit_value;
#else
#include <stdio.h>
#endif

#define FFT_N 64
#define FFT_LOGN 6

static inline int32_t q15_mul(int32_t a, int32_t b) {
    return (int32_t)(((int64_t)a * (int64_t)b) >> 15);
}

static inline uint32_t bit_reverse6(uint32_t x) {
    uint32_t r = 0;
    r |= ((x >> 0) & 1u) << 5;
    r |= ((x >> 1) & 1u) << 4;
    r |= ((x >> 2) & 1u) << 3;
    r |= ((x >> 3) & 1u) << 2;
    r |= ((x >> 4) & 1u) << 1;
    r |= ((x >> 5) & 1u) << 0;
    return r;
}

static void fft_compute(int32_t xr[FFT_N], int32_t xi[FFT_N]) {
    static const int16_t wr[FFT_N / 2] = {
        32767, 32610, 32138, 31357, 30273, 28899, 27245, 25330,
        23170, 20787, 18204, 15446, 12539,  9512,  6393,  3212,
            0, -3212, -6393, -9512,-12539,-15446,-18204,-20787,
       -23170,-25330,-27245,-28899,-30273,-31357,-32138,-32610
    };

    static const int16_t wi[FFT_N / 2] = {
            0, -3212, -6393, -9512,-12539,-15446,-18204,-20787,
       -23170,-25330,-27245,-28899,-30273,-31357,-32138,-32610,
       -32768,-32610,-32138,-31357,-30273,-28899,-27245,-25330,
       -23170,-20787,-18204,-15446,-12539, -9512, -6393, -3212
    };

    for (uint32_t i = 0; i < FFT_N; i++) {
        uint32_t j = bit_reverse6(i);
        if (j > i) {
            int32_t tr = xr[i], ti = xi[i];
            xr[i] = xr[j]; xi[i] = xi[j];
            xr[j] = tr;    xi[j] = ti;
        }
    }

    for (uint32_t stage = 1; stage <= FFT_LOGN; stage++) {
        uint32_t m = 1u << stage;
        uint32_t mh = m >> 1;
        uint32_t step = FFT_N / m;

        for (uint32_t k = 0; k < FFT_N; k += m) {
            for (uint32_t j = 0; j < mh; j++) {
                uint32_t tw = j * step;
                int32_t c = wr[tw];
                int32_t s = wi[tw];

                uint32_t i0 = k + j;
                uint32_t i1 = i0 + mh;

                int32_t ar = xr[i0], ai = xi[i0];
                int32_t br = xr[i1], bi = xi[i1];

                int32_t tr = q15_mul(br, c) - q15_mul(bi, s);
                int32_t ti = q15_mul(br, s) + q15_mul(bi, c);

                xr[i0] = ar + tr;
                xi[i0] = ai + ti;
                xr[i1] = ar - tr;
                xi[i1] = ai - ti;
            }
        }
    }
}

static uint32_t signature_test(void) {
    static int32_t xr[FFT_N];
    static int32_t xi[FFT_N];

    for (uint32_t i = 0; i < FFT_N; i++) {
        xr[i] = (int32_t)(((i * 97u + 31u) & 0x3ffu) - 512) << 5;
        xi[i] = (int32_t)(((i * 29u + 11u) & 0x1ffu) - 256) << 5;
    }

    fft_compute(xr, xi);

#if !defined(__riscv)
    printf("FFT output (Q15-like fixed-point):\n");
    for (uint32_t i = 0; i < FFT_N; i++) {
        printf("X[%2u] = %d + j%d\n", i, xr[i], xi[i]);
    }
#endif

    uint64_t acc = 0x6a09e667f3bcc909ULL;
    for (uint32_t i = 0; i < FFT_N; i++) {
        acc ^= (uint64_t)(uint32_t)xr[i];
        acc += ((uint64_t)(uint32_t)xi[i] << (i & 15u));
        if (xr[i] < xi[i]) acc ^= 0x1111u;
        else               acc += 0x2222u;

        switch (i & 3u) {
            case 0: acc += 0x11111111ULL; break;
            case 1: acc ^= 0x22222222ULL; break;
            case 2: acc -= 0x33333333ULL; break;
            default: acc ^= (acc >> 7);   break;
        }
    }

    return (uint32_t)(acc ^ (acc >> 32));
}

int main(void) {
    uint32_t sig = signature_test();

#if defined(__riscv)
    exit_value = sig;
#else
    printf("fft_signature=0x%08x\n", sig);
    //fft_signature=0x2de8aac0
#endif

    return (int)sig;
}