/* SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001 */
/* Copyright (C) 2026 SnapKitty West */

/* Benchmark: v1 scalar-loop tryte ops vs v2 SWAR tryte ops, on the
 * host CPU. This is a PROXY only: there is no GPU, no nvcc, no
 * ptxas on this VM, so no GPU timing is claimed. What it measures
 * is the host-C cost of the v1 10-iteration loop (with per-lane
 * function calls inlined by the host compiler) against the v2
 * straight-line bitplane ops. The direction and rough magnitude
 * should carry to the GPU (fewer instructions per tryte), but the
 * exact GPU speedup is a Jetson measurement, not this number.
 *
 * Static PTX instruction counts are counted separately with grep
 * over the .ptx files (see STATUS.md).
 *
 * Build: cc -std=c11 -O2 -Wall -Wextra -o bench_v1_v2 bench_v1_v2.c
 * Run:   ./bench_v1_v2
 */

#define _POSIX_C_SOURCE 199309L

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/* V2 functions, included directly. */
#include "../malbolge_ternary_v2.cu"

/* V1 scalar loop ops (verbatim copies, v1_ prefix). */
static inline uint32_t v1_tritAdd(uint32_t a, uint32_t b) {
    uint32_t s = a + b;
    return (s >= 3u) ? (s - 3u) : s;
}
static inline uint32_t v1_tritSub(uint32_t a, uint32_t b) {
    uint32_t d = a + 3u - b;
    return (d >= 3u) ? (d - 3u) : d;
}
static inline uint32_t v1_crazyOp(uint32_t a, uint32_t b) {
    const uint32_t CRAZY_LUT = 0x00281A01u;
    uint32_t k = ((a & 3u) << 2) | (b & 3u);
    return (CRAZY_LUT >> (2u * k)) & 3u;
}
static inline uint32_t v1_tryteAdd(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        out |= (v1_tritAdd((a >> (2u * i)) & 3u, (b >> (2u * i)) & 3u) << (2u * i));
    return out & TRYTE_MASK;
}
static inline uint32_t v1_tryteSub(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        out |= (v1_tritSub((a >> (2u * i)) & 3u, (b >> (2u * i)) & 3u) << (2u * i));
    return out & TRYTE_MASK;
}
static inline uint32_t v1_crazyTryte(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        out |= (v1_crazyOp((a >> (2u * i)) & 3u, (b >> (2u * i)) & 3u) << (2u * i));
    return out & TRYTE_MASK;
}
static inline uint32_t v1_tryteToNat(uint32_t tryte) {
    uint32_t acc = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        acc = acc * 3u + ((tryte >> (2u * i)) & 3u);
    return acc % MEMORY_SIZE;
}

/* Deterministic valid-tryte stream (xorshift). */
static uint32_t rng_state = 0x12345678u;
static uint32_t rand_tryte(void) {
    uint32_t x = rng_state;
    x ^= x << 13u; x ^= x >> 17u; x ^= x << 5u;
    rng_state = x;
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t d = (x >> (2u * i)) & 3u;
        if (d == 3u) d = 1u;
        out |= (d << (2u * i));
    }
    return out & TRYTE_MASK;
}

static double now_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

/* Time fn(a,b) over N pre-generated pairs; return seconds per call.
 * The trytes are pre-generated so the RNG is not in the timed loop.
 * The sink prevents the compiler from deleting the loop. */
typedef uint32_t (*binop_t)(uint32_t, uint32_t);
static double time_binop(binop_t fn, const uint32_t* A, const uint32_t* B,
                         uint64_t n, uint32_t* sink) {
    double t0 = now_sec();
    for (uint64_t k = 0; k < n; k++)
        *sink ^= fn(A[k & 4095ull], B[k & 4095ull]);
    double t1 = now_sec();
    return (t1 - t0) / (double)n;
}

typedef uint32_t (*unop_t)(uint32_t);
static double time_unop(unop_t fn, const uint32_t* A,
                        uint64_t n, uint32_t* sink) {
    double t0 = now_sec();
    for (uint64_t k = 0; k < n; k++)
        *sink ^= fn(A[k & 4095ull]);
    double t1 = now_sec();
    return (t1 - t0) / (double)n;
}

int main(void) {
    const uint64_t N = 20000000ull; /* 20M calls per op */
    uint32_t sink = 0u;

    /* Pre-generate a small cache-resident tryte stream (not timed):
     * 4096 pairs = 32 KB, fits in L1, so the timed loop measures the
     * op cost, not main-memory latency. */
    const uint64_t W = 4096ull;
    uint32_t* A = malloc(W * sizeof(uint32_t));
    uint32_t* B = malloc(W * sizeof(uint32_t));
    if (!A || !B) { printf("alloc failed\n"); return 1; }
    for (uint64_t k = 0; k < W; k++) { A[k] = rand_tryte(); B[k] = rand_tryte(); }

    printf("Host CPU proxy benchmark (no GPU on this VM; see header).\n");
    printf("20M pre-generated random valid-tryte calls per op, ns per call:\n\n");

    double v1_add = time_binop(v1_tryteAdd, A, B, N, &sink);
    double v2_add = time_binop(tryteAdd_swar, A, B, N, &sink);
    double v1_sub = time_binop(v1_tryteSub, A, B, N, &sink);
    double v2_sub = time_binop(tryteSub_swar, A, B, N, &sink);
    double v1_crz = time_binop(v1_crazyTryte, A, B, N, &sink);
    double v2_crz = time_binop(crazyTryte_swar, A, B, N, &sink);
    double v1_nat = time_unop(v1_tryteToNat, A, N, &sink);
    double v2_nat = time_unop(tryteToNat, A, N, &sink);

    printf("tryteAdd   v1 loop %8.2f ns   v2 SWAR %8.2f ns   ratio %.2fx\n",
           v1_add * 1e9, v2_add * 1e9, v1_add / v2_add);
    printf("tryteSub   v1 loop %8.2f ns   v2 SWAR %8.2f ns   ratio %.2fx\n",
           v1_sub * 1e9, v2_sub * 1e9, v1_sub / v2_sub);
    printf("crazyTryte v1 loop %8.2f ns   v2 SWAR %8.2f ns   ratio %.2fx\n",
           v1_crz * 1e9, v2_crz * 1e9, v1_crz / v2_crz);
    printf("tryteToNat v1 loop %8.2f ns   v2 loop %8.2f ns   ratio %.2fx\n",
           v1_nat * 1e9, v2_nat * 1e9, v1_nat / v2_nat);
    printf("sink=%u (prevents dead-code elimination)\n", sink);
    free(A); free(B);
    return 0;
}
