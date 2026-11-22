/* SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001 */
/* Copyright (C) 2026 SnapKitty West */

/* Malbolge ternary kernels, V2. Benchmark variant. V1 is untouched.
 *
 * The three changes, all from the v1 review:
 *   1. tryteToNat reads slot i as the 3^i digit (iterate i = 9 down to 0),
 *      so it inverts natToTryte. V1 folded the stored array big-endian.
 *   2. The trit operations are SWAR: all 10 trits of a packed tryte are
 *      evaluated in parallel inside one uint32_t, from the 0x55555 /
 *      0xAAAAA bitplanes. No 10-iteration loop, no per-lane call.
 *   3. The PTX crazy_op uses bfe.u32 (see malbolge_ternary_v2.ptx).
 *      The scalar crazyOp LUT below is kept for reference only.
 *
 * Same packed format as v1: one tryte is 10 trits x 2 bits in a uint32_t
 * (00 = Zero, 01 = One, 10 = Two), TRYTE_MASK 0x000FFFFF. Same crazy
 * table as v1 (the owner's variant, LUT 0x00281A01). Same natToTryte.
 *
 * The per-trit operations (tritAdd / tritSub / crazyOp) are IDENTICAL
 * to v1; only tryteToNat differs. So crazyTryte, decryptTryte and
 * permuteTryte agree with v1 bit for bit, while incrementTryte and
 * decodeInstruction follow the corrected addressing.
 *
 * Dual-purpose: under nvcc this is a CUDA file; under a host C
 * compiler (with __device__ / __forceinline__ defined away) it
 * compiles as plain C, so the host harness includes it directly
 * instead of copying the functions. The kernels are CUDA-only.
 */

#include <stdint.h>

#ifdef __CUDACC__
#include <cuda_runtime.h>
#else
#define __device__
#define __forceinline__ static inline
#endif

#define TRYTE_SIZE   10u
#define MEMORY_SIZE  59049u
#define TRYTE_MASK   0x000FFFFFu  /* 10 trits * 2 bits */
#define PLANE_LO     0x00055555u  /* low bit of each 2-bit lane */
#define PLANE_HI     0x000AAAAAu  /* high bit of each 2-bit lane */

/* Lean: inductive Trit | Zero (0) | One (1) | Two (2) */
__device__ __forceinline__ uint32_t trit_mask(uint32_t t) {
    return (t & 3u) == 3u ? 0u : (t & 3u);
}

/* Lean: tritAdd (a b : Trit) : Trit. Scalar reference, same as v1. */
__device__ __forceinline__ uint32_t tritAdd(uint32_t a, uint32_t b) {
    uint32_t s = a + b;
    return (s >= 3u) ? (s - 3u) : s;
}

/* Lean: tritSub (a b : Trit) : Trit. Scalar reference, same as v1. */
__device__ __forceinline__ uint32_t tritSub(uint32_t a, uint32_t b) {
    uint32_t d = a + 3u - b;
    return (d >= 3u) ? (d - 3u) : d;
}

/* Lean: crazyOp (a b : Trit) : Trit. Scalar reference, same as v1.
 * LUT indexed by (a << 2) | b, 2 bits per entry -> 0x00281A01. */
__device__ __forceinline__ uint32_t crazyOp(uint32_t a, uint32_t b) {
    const uint32_t CRAZY_LUT = 0x00281A01u;
    uint32_t k = ((a & 3u) << 2) | (b & 3u);
    return (CRAZY_LUT >> (2u * k)) & 3u;
}

/* ---- SWAR packed trit operations ----
 * Each lane is a 2-bit trit. a0/a1 and b0/b1 are the bitplanes
 * (bits at even positions 0,2,...,18). Most terms AND at least one
 * positive bitplane, so no cross-lane carry or borrow can occur:
 * each output bit depends only on the input bits at its own
 * position. The exception is the crazy r0 term
 * (~a1 & ~a0 & ~b1 & ~b0), which is made only of complements: a
 * bare ~x is all ones in the odd slots and the upper bits, so that
 * term leaks there. r1 and r0 are therefore masked to PLANE_LO
 * before combining, which confines every term to the bitplane.
 * r = (r1 << 1) | r0 rebuilds the packed tryte.
 *
 * The boolean forms are the per-lane truth tables, verified by
 * hand and by exhaustive execution in gpu/tests/verify_v2_host.c.
 */

/* (a + b) mod 3, all 10 lanes in parallel. */
__device__ __forceinline__ uint32_t tryteAdd_swar(uint32_t a, uint32_t b) {
    uint32_t a0 = a & PLANE_LO;
    uint32_t a1 = (a >> 1u) & PLANE_LO;
    uint32_t b0 = b & PLANE_LO;
    uint32_t b1 = (b >> 1u) & PLANE_LO;
    uint32_t r1 = (~a1 & ~a0 & b1) | (~a1 & a0 & b0 & ~b1) | (a1 & ~b1 & ~b0);
    uint32_t r0 = (~a1 & ~a0 & b0 & ~b1) | (~a1 & a0 & ~b1 & ~b0) | (a1 & b1);
    return (((r1 & PLANE_LO) << 1u) | (r0 & PLANE_LO)) & TRYTE_MASK;
}

/* (a - b) mod 3, all 10 lanes in parallel. */
__device__ __forceinline__ uint32_t tryteSub_swar(uint32_t a, uint32_t b) {
    uint32_t a0 = a & PLANE_LO;
    uint32_t a1 = (a >> 1u) & PLANE_LO;
    uint32_t b0 = b & PLANE_LO;
    uint32_t b1 = (b >> 1u) & PLANE_LO;
    uint32_t r1 = (a1 & ~b1 & ~b0) | (~a1 & ~a0 & b0 & ~b1) | (~a1 & a0 & b1);
    uint32_t r0 = (~a1 & a0 & ~b1 & ~b0) | (a1 & b0 & ~b1) | (~a1 & ~a0 & b1);
    return (((r1 & PLANE_LO) << 1u) | (r0 & PLANE_LO)) & TRYTE_MASK;
}

/* crazyOp, all 10 lanes in parallel. Owner's variant table. */
__device__ __forceinline__ uint32_t crazyTryte_swar(uint32_t a, uint32_t b) {
    uint32_t a0 = a & PLANE_LO;
    uint32_t a1 = (a >> 1u) & PLANE_LO;
    uint32_t b0 = b & PLANE_LO;
    uint32_t b1 = (b >> 1u) & PLANE_LO;
    uint32_t r1 = (a0 & ~a1 & ~b1) | (a1 & ~b1 & b0) | (a1 & b1 & ~b0);
    uint32_t r0 = (~a1 & ~a0 & ~b1 & ~b0) | (~a1 & a0 & b1);
    return (((r1 & PLANE_LO) << 1u) | (r0 & PLANE_LO)) & TRYTE_MASK;
}

/* Lean: tryteToNat, FIXED. Slot i is the 3^i digit (iterate high to
 * low, Horner form), so tryteToNat (natToTryte n) = n. This is the
 * same value as the power-sum form in lean/MalbolgeTryteV2.lean. */
__device__ __forceinline__ uint32_t tryteToNat(uint32_t tryte) {
    uint32_t acc = 0u;
#ifdef __CUDACC__
    #pragma unroll
#endif
    for (int32_t i = (int32_t)TRYTE_SIZE - 1; i >= 0; --i) {
        uint32_t trit = (tryte >> (2u * (uint32_t)i)) & 3u;
        acc = acc * 3u + trit;
    }
    return acc % MEMORY_SIZE;
}

/* Lean: natToTryte (n : Nat) : Tryte. Unchanged from v1. */
__device__ __forceinline__ uint32_t natToTryte(uint32_t n) {
    uint32_t out = 0u;
#ifdef __CUDACC__
    #pragma unroll
#endif
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t d = n % 3u;
        n /= 3u;
        out |= (d << (2u * i));
    }
    return out & TRYTE_MASK;
}

/* Lean: incrementTryte t := natToTryte ((tryteToNat t + 1) % memorySize).
 * Follows the fixed tryteToNat, so it differs from v1. */
__device__ __forceinline__ uint32_t incrementTryte(uint32_t t) {
    return natToTryte((tryteToNat(t) + 1u) % MEMORY_SIZE);
}

/* Lean: crazyTryte a b := zipWith crazyOp a b. SWAR, no loop.
 * Agrees with v1 bit for bit (the per-lane op is unchanged). */
__device__ __forceinline__ uint32_t crazyTryte(uint32_t a, uint32_t b) {
    return crazyTryte_swar(a, b);
}

/* Lean: decryptTryte t addr := zipWith tritSub t (natToTryte addr).
 * SWAR, no loop. Agrees with v1 bit for bit. */
__device__ __forceinline__ uint32_t decryptTryte(uint32_t t, uint32_t addr) {
    return tryteSub_swar(t, natToTryte(addr));
}

/* Lean: permuteTryte t := map (fun x => crazyOp x x) (rotateLeft1 t).
 * Rotate is one shot; the crazyOp is SWAR with a = b. Agrees with v1. */
__device__ __forceinline__ uint32_t permuteTryte(uint32_t t) {
    uint32_t rotated = ((t >> 2u) & 0x3FFFFu) | ((t & 3u) << 18u);
    return crazyTryte_swar(rotated, rotated);
}

/* Lean: MalbolgeInstruction: Jmp=0, Rot=1, Out=2, In=3, Nop=4, End=5.
 * Follows the fixed tryteToNat, so addresses differ from v1. */
__device__ __forceinline__ uint32_t decodeInstruction(const uint32_t* mem, uint32_t C) {
    uint32_t addr = tryteToNat(C);
    uint32_t dec  = decryptTryte(mem[addr], addr);
    uint32_t d0 = dec & 3u;
    uint32_t d1 = (dec >> 2u) & 3u;
    uint32_t d2 = (dec >> 4u) & 3u;

    if (d0 == 0u) return 0u; /* Jmp */
    if (d0 == 1u) return 1u; /* Rot */
    if (d1 == 0u) return 2u; /* Out */
    if (d1 == 1u) return 3u; /* In */
    if (d2 == 0u) return 4u; /* Nop */
    return 5u;               /* End */
}

#ifdef __CUDACC__
/* Elementwise Ternary Arithmetic Kernel, V2 (op: 0=tritAdd, 1=tritSub,
 * 2=crazyOp, 3=permute). SWAR: no loop, no per-lane call. */
extern "C" __global__ void ternary_arith_kernel_v2(
    const uint32_t* __restrict__ A,
    const uint32_t* __restrict__ B,
    uint32_t* __restrict__ C,
    uint32_t op,
    uint32_t n)
{
    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= n) return;

    uint32_t va = A[idx] & TRYTE_MASK;
    uint32_t vb = B[idx] & TRYTE_MASK;
    uint32_t res = 0u;

    if (op == 0u) {
        res = tryteAdd_swar(va, vb);
    } else if (op == 1u) {
        res = tryteSub_swar(va, vb);
    } else if (op == 2u) {
        res = crazyTryte_swar(va, vb);
    } else {
        res = permuteTryte(va);
    }
    C[idx] = res & TRYTE_MASK;
}

/* Deterministic Malbolge Processor Step Kernel, V2 (one 59049-tryte VM
 * per thread). Same structure as v1; the step functions are the v2
 * ones, so addressing follows the fixed tryteToNat. */
struct MalbolgeRegsDevice {
    uint32_t A, C, D, stepCount;
};

extern "C" __global__ void malbolge_run_kernel_v2(
    MalbolgeRegsDevice* __restrict__ regs,
    uint32_t* __restrict__ memPool, /* numVMs * 59049 trytes */
    uint32_t* __restrict__ lastOut,
    uint32_t steps,
    uint32_t numVMs)
{
    uint32_t vm = blockIdx.x * blockDim.x + threadIdx.x;
    if (vm >= numVMs) return;

    uint32_t* mem = memPool + (size_t)vm * MEMORY_SIZE;
    MalbolgeRegsDevice r = regs[vm];

    for (uint32_t s = 0u; s < steps; ++s) {
        uint32_t instr = decodeInstruction(mem, r.C);
        if (instr == 5u) break; /* End */

        uint32_t dAddr = tryteToNat(r.D);
        if (instr == 0u) { /* Jmp */
            r.C = mem[dAddr];
            r.D = incrementTryte(r.D);
        } else if (instr == 1u) { /* Rot */
            uint32_t mv = mem[dAddr];
            r.A = crazyTryte(r.A, mv);
            mem[dAddr] = permuteTryte(mv);
            r.D = incrementTryte(r.D);
        } else if (instr == 2u) { /* Out */
            lastOut[vm] = tryteToNat(r.A);
            r.D = incrementTryte(r.D);
        } else if (instr == 3u) { /* In */
            r.A = natToTryte(lastOut[vm]);
            r.D = incrementTryte(r.D);
        } else { /* Nop */
            r.D = incrementTryte(r.D);
        }
        r.stepCount += 1u;
    }
    regs[vm] = r;
}
#endif /* __CUDACC__ */
