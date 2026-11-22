/* SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001 */
/* Copyright (C) 2026 SnapKitty West */

/* Host-side verification of the V2 kernels in
 * gpu/malbolge_ternary_v2.cu, against V1 (gpu/malbolge_ternary.cu)
 * and against the Lean 4 definitions (lean/MalbolgeProcessorRoot.lean
 * for v1, lean/MalbolgeTryteV2.lean for v2).
 *
 * No CUDA toolchain or GPU needed. The v2 file is included directly
 * (it is dual-purpose: under a host compiler it is plain C). The v1
 * functions are copied verbatim with a v1_ prefix, the same way the
 * v1 harness copies them.
 *
 * What must hold:
 *   - v2 tryteToNat inverts natToTryte on ALL 59,049 values.
 *   - v2 tryteToNat matches the Lean v2 power-sum definition.
 *   - v2 SWAR ops (tryteAdd_swar, tryteSub_swar, crazyTryte_swar)
 *     match the v1 scalar loop ops bit for bit (the per-lane op is
 *     unchanged), and match the Lean reference.
 *   - v2 crazyTryte / decryptTryte / permuteTryte match v1 exactly.
 *   - v2 incrementTryte and decodeInstruction follow the FIXED
 *     tryteToNat, so they differ from v1 exactly where addressing
 *     changes, and match the Lean v2 reference.
 *   - v1 tryteToNat is also measured, to confirm the known failure
 *     count (58,806 of 59,049) it is being benchmarked against.
 *
 * Build: cc -std=c11 -O2 -Wall -Wextra -o verify_v2_host verify_v2_host.c
 * Run:   ./verify_v2_host
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

/* ---- V2 device functions, included directly from the .cu file ---- */
#include "../malbolge_ternary_v2.cu"

/* ---- V1 device functions, copied verbatim with a v1_ prefix ---- */

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

/* V1 tryteToNat: big-endian foldl, slot 0 is the most significant. */
static inline uint32_t v1_tryteToNat(uint32_t tryte) {
    uint32_t acc = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t trit = (tryte >> (2u * i)) & 3u;
        acc = acc * 3u + trit;
    }
    return acc % MEMORY_SIZE;
}

static inline uint32_t v1_tryteAdd(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t ta = (a >> (2u * i)) & 3u;
        uint32_t tb = (b >> (2u * i)) & 3u;
        out |= (v1_tritAdd(ta, tb) << (2u * i));
    }
    return out & TRYTE_MASK;
}

static inline uint32_t v1_tryteSub(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t ta = (a >> (2u * i)) & 3u;
        uint32_t tb = (b >> (2u * i)) & 3u;
        out |= (v1_tritSub(ta, tb) << (2u * i));
    }
    return out & TRYTE_MASK;
}

static inline uint32_t v1_incrementTryte(uint32_t t) {
    return natToTryte((v1_tryteToNat(t) + 1u) % MEMORY_SIZE);
}

static inline uint32_t v1_crazyTryte(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t ta = (a >> (2u * i)) & 3u;
        uint32_t tb = (b >> (2u * i)) & 3u;
        out |= (v1_crazyOp(ta, tb) << (2u * i));
    }
    return out & TRYTE_MASK;
}

static inline uint32_t v1_decryptTryte(uint32_t t, uint32_t addr) {
    uint32_t addrT = natToTryte(addr);
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t tt = (t >> (2u * i)) & 3u;
        uint32_t ta = (addrT >> (2u * i)) & 3u;
        out |= (v1_tritSub(tt, ta) << (2u * i));
    }
    return out & TRYTE_MASK;
}

static inline uint32_t v1_permuteTryte(uint32_t t) {
    uint32_t rotated = ((t >> 2u) & 0x3FFFFu) | ((t & 3u) << 18u);
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t x = (rotated >> (2u * i)) & 3u;
        out |= (v1_crazyOp(x, x) << (2u * i));
    }
    return out & TRYTE_MASK;
}

static inline uint32_t v1_decodeInstruction(const uint32_t* mem, uint32_t C) {
    uint32_t addr = v1_tryteToNat(C);
    uint32_t dec  = v1_decryptTryte(mem[addr], addr);
    uint32_t d0 = dec & 3u;
    uint32_t d1 = (dec >> 2u) & 3u;
    uint32_t d2 = (dec >> 4u) & 3u;
    if (d0 == 0u) return 0u;
    if (d0 == 1u) return 1u;
    if (d1 == 0u) return 2u;
    if (d1 == 1u) return 3u;
    if (d2 == 0u) return 4u;
    return 5u;
}

/* ---- Independent reference: the Lean definitions, written directly ---- */

static uint32_t lean_tritAdd(uint32_t a, uint32_t b) { return (a + b) % 3u; }
static uint32_t lean_tritSub(uint32_t a, uint32_t b) { return (a + 3u - b) % 3u; }

/* Owner's crazyOp variant table (from MalbolgeProcessorRoot.lean). */
static const uint32_t LEAN_CRAZY[3][3] = {
    {1u, 0u, 0u},
    {2u, 2u, 1u},
    {0u, 2u, 2u},
};

static uint32_t lean_trit(uint32_t tryte, uint32_t i) {
    return (tryte >> (2u * i)) & 3u;
}

/* Lean v1 tryteToNat: foldl big-endian, slot 0 most significant. */
static uint32_t lean_tryteToNat_v1(uint32_t tryte) {
    uint32_t acc = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        acc = acc * 3u + lean_trit(tryte, i);
    return acc % MEMORY_SIZE;
}

/* Lean v2 tryteToNat (MalbolgeTryteV2.lean): power sum, slot i is 3^i. */
static uint32_t lean_tryteToNat_v2(uint32_t tryte) {
    uint32_t acc = 0u;
    uint32_t p = 1u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        acc += lean_trit(tryte, i) * p;
        p *= 3u;
    }
    return acc % MEMORY_SIZE;
}

/* Lean natToTryte: position i holds (n / 3^i) % 3. Same in v1 and v2. */
static uint32_t lean_natToTryte(uint32_t n) {
    uint32_t out = 0u;
    uint32_t p = 1u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        out |= (((n / p) % 3u) << (2u * i));
        p *= 3u;
    }
    return out & TRYTE_MASK;
}

static uint32_t lean_rotateLeft1(uint32_t t) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE - 1u; ++i)
        out |= (lean_trit(t, i + 1u) << (2u * i));
    out |= (lean_trit(t, 0u) << (2u * (TRYTE_SIZE - 1u)));
    return out & TRYTE_MASK;
}

static uint32_t lean_permuteTryte(uint32_t t) {
    uint32_t r = lean_rotateLeft1(t);
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t x = lean_trit(r, i);
        out |= (LEAN_CRAZY[x][x] << (2u * i));
    }
    return out & TRYTE_MASK;
}

static uint32_t lean_crazyTryte(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        out |= (LEAN_CRAZY[lean_trit(a, i)][lean_trit(b, i)] << (2u * i));
    return out & TRYTE_MASK;
}

static uint32_t lean_decryptTryte(uint32_t t, uint32_t addr) {
    uint32_t at = lean_natToTryte(addr);
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        out |= (lean_tritSub(lean_trit(t, i), lean_trit(at, i)) << (2u * i));
    return out & TRYTE_MASK;
}

static uint32_t lean_incrementTryte_v1(uint32_t t) {
    return lean_natToTryte((lean_tryteToNat_v1(t) + 1u) % MEMORY_SIZE);
}

static uint32_t lean_incrementTryte_v2(uint32_t t) {
    return lean_natToTryte((lean_tryteToNat_v2(t) + 1u) % MEMORY_SIZE);
}

static uint32_t lean_decodeInstruction_v2(const uint32_t* mem, uint32_t C) {
    uint32_t addr = lean_tryteToNat_v2(C);
    uint32_t dec = lean_decryptTryte(mem[addr], addr);
    uint32_t d0 = lean_trit(dec, 0u);
    uint32_t d1 = lean_trit(dec, 1u);
    uint32_t d2 = lean_trit(dec, 2u);
    if (d0 == 0u) return 0u;
    if (d0 == 1u) return 1u;
    if (d1 == 0u) return 2u;
    if (d1 == 1u) return 3u;
    if (d2 == 0u) return 4u;
    return 5u;
}

/* Scalar loop reference for the SWAR add/sub (built from lean_tritAdd). */
static uint32_t lean_tryteAdd(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        out |= (lean_tritAdd(lean_trit(a, i), lean_trit(b, i)) << (2u * i));
    return out & TRYTE_MASK;
}

static uint32_t lean_tryteSub(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        out |= (lean_tritSub(lean_trit(a, i), lean_trit(b, i)) << (2u * i));
    return out & TRYTE_MASK;
}

/* ---- Test driver ---- */

static int failures = 0;

static void check(const char* name, uint32_t got, uint32_t want) {
    if (got != want) {
        printf("FAIL %s: got %u want %u\n", name, got, want);
        failures++;
    }
}

/* Valid packed trytes only: every 2-bit group is 00, 01, or 10. */
static const uint32_t VALS[] = {
    0x00000u, /* all Zero */
    0x55555u, /* all One  */
    0xAAAAAu, /* all Two  */
    0x00001u, /* trit0 = One */
    0x00002u, /* trit0 = Two */
    0x00004u, /* trit1 = One */
    0x00008u, /* trit1 = Two */
    0x40000u, /* trit9 = One */
    0x80000u, /* trit9 = Two */
    0x24924u, /* mixed, all groups valid */
    0x09249u, /* mixed, all groups valid */
};

/* Deterministic pseudo-random valid tryte (xorshift). */
static uint32_t rand_tryte(uint32_t* s) {
    uint32_t x = *s;
    x ^= x << 13u; x ^= x >> 17u; x ^= x << 5u;
    *s = x;
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t d = (x >> (2u * i)) & 3u;
        if (d == 3u) d = 1u;
        out |= (d << (2u * i));
    }
    return out & TRYTE_MASK;
}

int main(void) {
    size_t nv = sizeof(VALS) / sizeof(VALS[0]);

    /* 1. Scalar trit tables: all 9 pairs each (v2 scalar refs = v1). */
    for (uint32_t a = 0; a < 3; a++)
        for (uint32_t b = 0; b < 3; b++) {
            check("v2-tritAdd", tritAdd(a, b), lean_tritAdd(a, b));
            check("v2-tritSub", tritSub(a, b), lean_tritSub(a, b));
            check("v2-crazyOp", crazyOp(a, b), LEAN_CRAZY[a][b]);
        }

    /* 2. THE roundtrip: v2 tryteToNat inverts natToTryte on ALL 59,049.
     * Also measure v1, to confirm the known failure count. */
    uint32_t v2_rt_fail = 0u, v1_rt_fail = 0u;
    for (uint32_t n = 0; n < MEMORY_SIZE; n++) {
        if (tryteToNat(natToTryte(n)) != n) v2_rt_fail++;
        if (v1_tryteToNat(natToTryte(n)) != n) v1_rt_fail++;
        check("v2-tryteToNat-vs-lean-v2", tryteToNat(natToTryte(n)),
              lean_tryteToNat_v2(natToTryte(n)));
        check("natToTryte", natToTryte(n), lean_natToTryte(n));
    }
    printf("roundtrip v2 failures: %u / 59049\n", v2_rt_fail);
    printf("roundtrip v1 failures: %u / 59049\n", v1_rt_fail);
    if (v2_rt_fail != 0u) failures++;
    if (v1_rt_fail != 58806u) {
        printf("NOTE v1 roundtrip failures differ from the known 58806\n");
        failures++;
    }
    for (size_t s = 0; s < nv; s++) {
        check("v2-tryteToNat-vals", tryteToNat(VALS[s]), lean_tryteToNat_v2(VALS[s]));
        check("v1-tryteToNat-vals", v1_tryteToNat(VALS[s]), lean_tryteToNat_v1(VALS[s]));
    }

    /* 3. SWAR ops vs v1 scalar loop ops and vs Lean, over every valid
     * tryte against the VALS spread, plus random pairs. */
    for (uint32_t n = 0; n < MEMORY_SIZE; n++) {
        uint32_t a = natToTryte(n);
        for (size_t j = 0; j < nv; j++) {
            uint32_t b = VALS[j];
            check("swar-add-vs-v1", tryteAdd_swar(a, b), v1_tryteAdd(a, b));
            check("swar-add-vs-lean", tryteAdd_swar(a, b), lean_tryteAdd(a, b));
            check("swar-sub-vs-v1", tryteSub_swar(a, b), v1_tryteSub(a, b));
            check("swar-sub-vs-lean", tryteSub_swar(a, b), lean_tryteSub(a, b));
            check("swar-crazy-vs-v1", crazyTryte_swar(a, b), v1_crazyTryte(a, b));
            check("swar-crazy-vs-lean", crazyTryte_swar(a, b), lean_crazyTryte(a, b));
            check("v2-crazyTryte-vs-v1", crazyTryte(a, b), v1_crazyTryte(a, b));
            check("v2-decryptTryte-vs-v1", decryptTryte(a, j), v1_decryptTryte(a, j));
        }
        check("v2-permuteTryte-vs-v1", permuteTryte(a), v1_permuteTryte(a));
        check("v2-permuteTryte-vs-lean", permuteTryte(a), lean_permuteTryte(a));
        check("v2-incrementTryte-vs-lean-v2", incrementTryte(a), lean_incrementTryte_v2(a));
    }
    {
        uint32_t s = 0x12345678u;
        for (uint32_t k = 0; k < 20000u; k++) {
            uint32_t a = rand_tryte(&s), b = rand_tryte(&s);
            check("swar-add-random", tryteAdd_swar(a, b), lean_tryteAdd(a, b));
            check("swar-sub-random", tryteSub_swar(a, b), lean_tryteSub(a, b));
            check("swar-crazy-random", crazyTryte_swar(a, b), lean_crazyTryte(a, b));
        }
    }

    /* 4. v2 incrementTryte vs Lean v2 on all 59,049 (already done in 3
     * for the natToTryte range; here the full tryte range via VALS is
     * covered by the loop above). Also v1 increment vs Lean v1. */
    for (uint32_t n = 0; n < MEMORY_SIZE; n += 97u) {
        uint32_t t = natToTryte(n);
        check("v1-incrementTryte-vs-lean-v1", v1_incrementTryte(t), lean_incrementTryte_v1(t));
    }

    /* 5. decodeInstruction v2: every branch, addresses by the FIXED
     * tryteToNat. Same construction as the v1 harness, but C and addr
     * go through the v2 functions and the Lean v2 reference. */
    {
        static uint32_t mem[MEMORY_SIZE];
        for (uint32_t a = 0; a < MEMORY_SIZE; a++) mem[a] = 0u;
        struct { uint32_t n; uint32_t d0, d1, d2; uint32_t want; } cases[] = {
            {0u, 0u, 0u, 0u, 0u}, /* Jmp */
            {1u, 1u, 0u, 0u, 1u}, /* Rot */
            {2u, 2u, 0u, 0u, 2u}, /* Out */
            {3u, 2u, 1u, 0u, 3u}, /* In  */
            {4u, 2u, 2u, 0u, 4u}, /* Nop */
            {5u, 2u, 2u, 1u, 5u}, /* End */
            {6u, 2u, 2u, 2u, 5u}, /* End */
        };
        for (size_t c = 0; c < sizeof(cases) / sizeof(cases[0]); c++) {
            uint32_t C = natToTryte(cases[c].n);
            uint32_t addr = tryteToNat(C);
            uint32_t target = (cases[c].d0) | (cases[c].d1 << 2u) | (cases[c].d2 << 4u);
            uint32_t at = natToTryte(addr);
            uint32_t enc = 0u;
            for (uint32_t i = 0; i < TRYTE_SIZE; i++)
                enc |= (v1_tritAdd(lean_trit(target, i), lean_trit(at, i)) << (2u * i));
            mem[addr] = enc;
            check("v2-decodeInstruction", decodeInstruction(mem, C), cases[c].want);
            check("v2-decodeInstruction-lean", lean_decodeInstruction_v2(mem, C), cases[c].want);
        }
    }

    if (failures == 0) {
        printf("ALL V2 CHECKS PASS\n");
        return 0;
    }
    printf("%d FAILURES\n", failures);
    return 1;
}
