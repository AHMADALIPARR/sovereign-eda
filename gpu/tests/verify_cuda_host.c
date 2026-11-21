/* SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001 */
/* Copyright (C) 2026 SnapKitty West */

/* Host-side verification of the CUDA device functions in
 * gpu/malbolge_ternary.cu, against the Lean 4 definitions in
 * lean/MalbolgeProcessorRoot.lean.
 *
 * No CUDA toolchain or GPU needed: the device functions are copied
 * verbatim (CUDA qualifiers stripped) and checked against an
 * independent C implementation of the Lean definitions.
 *
 * NOTE: the CUDA functions are defined on valid packed trytes only
 * (every 2-bit trit is 0, 1, or 2). A trit value of 3 is out of
 * domain: tritAdd/tritSub do a single conditional subtract, and the
 * crazyOp LUT has no entry for it. So every test tryte here is built
 * from 00/01/10 groups only.
 *
 * Build: cc -std=c11 -O2 -Wall -Wextra -o verify_cuda_host verify_cuda_host.c
 * Run:   ./verify_cuda_host
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define TRYTE_SIZE   10u
#define MEMORY_SIZE  59049u
#define TRYTE_MASK   0x000FFFFFu

/* ---- Device functions, copied verbatim from malbolge_ternary.cu ---- */

static inline uint32_t tritAdd(uint32_t a, uint32_t b) {
    uint32_t s = a + b;
    return (s >= 3u) ? (s - 3u) : s;
}

static inline uint32_t tritSub(uint32_t a, uint32_t b) {
    uint32_t d = a + 3u - b;
    return (d >= 3u) ? (d - 3u) : d;
}

static inline uint32_t crazyOp(uint32_t a, uint32_t b) {
    const uint32_t CRAZY_LUT = 0x00281A01u;
    uint32_t k = ((a & 3u) << 2) | (b & 3u);
    return (CRAZY_LUT >> (2u * k)) & 3u;
}

static inline uint32_t tryteToNat(uint32_t tryte) {
    uint32_t acc = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t trit = (tryte >> (2u * i)) & 3u;
        acc = acc * 3u + trit;
    }
    return acc % MEMORY_SIZE;
}

static inline uint32_t natToTryte(uint32_t n) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t d = n % 3u;
        n /= 3u;
        out |= (d << (2u * i));
    }
    return out & TRYTE_MASK;
}

static inline uint32_t incrementTryte(uint32_t t) {
    return natToTryte((tryteToNat(t) + 1u) % MEMORY_SIZE);
}

static inline uint32_t crazyTryte(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t ta = (a >> (2u * i)) & 3u;
        uint32_t tb = (b >> (2u * i)) & 3u;
        out |= (crazyOp(ta, tb) << (2u * i));
    }
    return out & TRYTE_MASK;
}

static inline uint32_t decryptTryte(uint32_t t, uint32_t addr) {
    uint32_t addrT = natToTryte(addr);
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t tt = (t >> (2u * i)) & 3u;
        uint32_t ta = (addrT >> (2u * i)) & 3u;
        out |= (tritSub(tt, ta) << (2u * i));
    }
    return out & TRYTE_MASK;
}

static inline uint32_t permuteTryte(uint32_t t) {
    uint32_t rotated = ((t >> 2u) & 0x3FFFFu) | ((t & 3u) << 18u);
    uint32_t out = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t x = (rotated >> (2u * i)) & 3u;
        out |= (crazyOp(x, x) << (2u * i));
    }
    return out & TRYTE_MASK;
}

static inline uint32_t decodeInstruction(const uint32_t* mem, uint32_t C) {
    uint32_t addr = tryteToNat(C);
    uint32_t dec  = decryptTryte(mem[addr], addr);
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

/* Lean tryteToNat: foldl (fun acc t => acc * 3 + t) 0 over trits in order,
 * so trit 0 (bits 0-1) is the most significant digit. */
static uint32_t lean_tryteToNat(uint32_t tryte) {
    uint32_t acc = 0u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i)
        acc = acc * 3u + lean_trit(tryte, i);
    return acc % MEMORY_SIZE;
}

/* Lean natToTryte: position i holds (n / 3^i) % 3. */
static uint32_t lean_natToTryte(uint32_t n) {
    uint32_t out = 0u;
    uint32_t p = 1u;
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        out |= (((n / p) % 3u) << (2u * i));
        p *= 3u;
    }
    return out & TRYTE_MASK;
}

/* Lean rotateLeft1: element 0 moves to the last position, others shift down. */
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

static uint32_t lean_incrementTryte(uint32_t t) {
    return lean_natToTryte((lean_tryteToNat(t) + 1u) % MEMORY_SIZE);
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

/* Lean decodeInstruction: Jmp=0, Rot=1, Out=2, In=3, Nop=4, End=5. */
static uint32_t lean_decodeInstruction(const uint32_t* mem, uint32_t C) {
    uint32_t addr = lean_tryteToNat(C);
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

int main(void) {
    size_t nv = sizeof(VALS) / sizeof(VALS[0]);

    /* 1. Trit tables: all 9 pairs each. */
    for (uint32_t a = 0; a < 3; a++)
        for (uint32_t b = 0; b < 3; b++) {
            check("tritAdd", tritAdd(a, b), lean_tritAdd(a, b));
            check("tritSub", tritSub(a, b), lean_tritSub(a, b));
            check("crazyOp", crazyOp(a, b), LEAN_CRAZY[a][b]);
        }

    /* 2. natToTryte: every value 0..59048. tryteToNat: a spread of
     * valid packed trytes, plus the full natToTryte range round-tripped
     * through tryteToNat. */
    for (uint32_t n = 0; n < MEMORY_SIZE; n++)
        check("natToTryte", natToTryte(n), lean_natToTryte(n));
    for (size_t s = 0; s < nv; s++)
        check("tryteToNat", tryteToNat(VALS[s]), lean_tryteToNat(VALS[s]));
    for (uint32_t n = 0; n < MEMORY_SIZE; n += 97u)
        check("tryteToNat-natToTryte", tryteToNat(natToTryte(n)),
              lean_tryteToNat(lean_natToTryte(n)));

    /* 3. Composed tryte ops, over the valid trytes. */
    for (size_t i = 0; i < nv; i++)
        for (size_t j = 0; j < nv; j++) {
            check("crazyTryte", crazyTryte(VALS[i], VALS[j]),
                  lean_crazyTryte(VALS[i], VALS[j]));
            check("decryptTryte", decryptTryte(VALS[i], j),
                  lean_decryptTryte(VALS[i], j));
        }
    for (size_t i = 0; i < nv; i++) {
        check("permuteTryte", permuteTryte(VALS[i]), lean_permuteTryte(VALS[i]));
        check("incrementTryte", incrementTryte(VALS[i]),
              lean_incrementTryte(VALS[i]));
    }
    for (uint32_t n = 0; n < MEMORY_SIZE; n += 499u) {
        uint32_t t = natToTryte(n);
        check("permuteTryte-range", permuteTryte(t), lean_permuteTryte(t));
        check("incrementTryte-range", incrementTryte(t), lean_incrementTryte(t));
    }

    /* 4. decodeInstruction: every branch. The C register holds a tryte;
     * the address the VM reads is tryteToNat(C), so the encrypted target
     * must be stored at that address, not at the raw number. Build mem so
     * that decryptTryte(mem[addr], addr) yields the chosen (d0,d1,d2):
     * mem[addr] = zipWith tritAdd target (natToTryte addr). */
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
                enc |= (tritAdd(lean_trit(target, i), lean_trit(at, i)) << (2u * i));
            mem[addr] = enc;
            check("decodeInstruction", decodeInstruction(mem, C), cases[c].want);
            check("decodeInstruction-lean", lean_decodeInstruction(mem, C), cases[c].want);
        }
    }

    if (failures == 0) {
        printf("ALL CHECKS PASS\n");
        return 0;
    }
    printf("%d FAILURES\n", failures);
    return 1;
}
