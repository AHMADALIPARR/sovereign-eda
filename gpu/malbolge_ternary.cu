#include <stdint.h>
#include <cuda_runtime.h>

#define TRYTE_SIZE   10u
#define MEMORY_SIZE  59049u
#define TRYTE_MASK   0x000FFFFFu  // 10 trits * 2 bits

// Lean: inductive Trit | Zero (0) | One (1) | Two (2)
__device__ __forceinline__ uint32_t trit_mask(uint32_t t) {
    return (t & 3u) == 3u ? 0u : (t & 3u);
}

// Lean: tritAdd (a b : Trit) : Trit
__device__ __forceinline__ uint32_t tritAdd(uint32_t a, uint32_t b) {
    uint32_t s = a + b;
    return (s >= 3u) ? (s - 3u) : s;
}

// Lean: tritSub (a b : Trit) : Trit
__device__ __forceinline__ uint32_t tritSub(uint32_t a, uint32_t b) {
    uint32_t d = a + 3u - b;
    return (d >= 3u) ? (d - 3u) : d;
}

// Lean: crazyOp (a b : Trit) : Trit
// LUT indexed by (a << 2) | b, 2 bits per entry -> 0x00281A01
__device__ __forceinline__ uint32_t crazyOp(uint32_t a, uint32_t b) {
    constexpr uint32_t CRAZY_LUT = 0x00281A01u;
    uint32_t k = ((a & 3u) << 2) | (b & 3u);
    return (CRAZY_LUT >> (2u * k)) & 3u;
}

// Lean: tryteToNat (foldl (fun acc t => acc * 3 + tritToNat t) 0)
// Guaranteed < 59049 (memorySize) when all 10 trits < 3
__device__ __forceinline__ uint32_t tryteToNat(uint32_t tryte) {
    uint32_t acc = 0u;
    #pragma unroll
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t trit = (tryte >> (2u * i)) & 3u;
        acc = acc * 3u + trit;
    }
    return acc % MEMORY_SIZE;
}

// Lean: natToTryte (n : Nat) : Tryte
__device__ __forceinline__ uint32_t natToTryte(uint32_t n) {
    uint32_t out = 0u;
    #pragma unroll
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t d = n % 3u;
        n /= 3u;
        out |= (d << (2u * i));
    }
    return out & TRYTE_MASK;
}

// Lean: incrementTryte t := natToTryte ((tryteToNat t + 1) % memorySize)
__device__ __forceinline__ uint32_t incrementTryte(uint32_t t) {
    return natToTryte((tryteToNat(t) + 1u) % MEMORY_SIZE);
}

// Lean: crazyTryte a b := zipWith crazyOp a b
__device__ __forceinline__ uint32_t crazyTryte(uint32_t a, uint32_t b) {
    uint32_t out = 0u;
    #pragma unroll
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t ta = (a >> (2u * i)) & 3u;
        uint32_t tb = (b >> (2u * i)) & 3u;
        out |= (crazyOp(ta, tb) << (2u * i));
    }
    return out & TRYTE_MASK;
}

// Lean: decryptTryte t addr := zipWith tritSub t (natToTryte addr)
__device__ __forceinline__ uint32_t decryptTryte(uint32_t t, uint32_t addr) {
    uint32_t addrT = natToTryte(addr);
    uint32_t out = 0u;
    #pragma unroll
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t tt = (t >> (2u * i)) & 3u;
        uint32_t ta = (addrT >> (2u * i)) & 3u;
        out |= (tritSub(tt, ta) << (2u * i));
    }
    return out & TRYTE_MASK;
}

// Lean: permuteTryte t := map (fun x => crazyOp x x) (rotateLeft1 t)
__device__ __forceinline__ uint32_t permuteTryte(uint32_t t) {
    uint32_t rotated = ((t >> 2u) & 0x3FFFFu) | ((t & 3u) << 18u);
    uint32_t out = 0u;
    #pragma unroll
    for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
        uint32_t x = (rotated >> (2u * i)) & 3u;
        out |= (crazyOp(x, x) << (2u * i));
    }
    return out & TRYTE_MASK;
}

// Lean: MalbolgeInstruction: Jmp=0, Rot=1, Out=2, In=3, Nop=4, End=5
__device__ __forceinline__ uint32_t decodeInstruction(const uint32_t* mem, uint32_t C) {
    uint32_t addr = tryteToNat(C);
    uint32_t dec  = decryptTryte(mem[addr], addr);
    uint32_t d0 = dec & 3u;
    uint32_t d1 = (dec >> 2u) & 3u;
    uint32_t d2 = (dec >> 4u) & 3u;

    if (d0 == 0u) return 0u; // Jmp
    if (d0 == 1u) return 1u; // Rot
    if (d1 == 0u) return 2u; // Out
    if (d1 == 1u) return 3u; // In
    if (d2 == 0u) return 4u; // Nop
    return 5u;               // End
}

// Elementwise Ternary Arithmetic Kernel (op: 0=tritAdd, 1=tritSub, 2=crazyOp, 3=permute)
extern "C" __global__ void ternary_arith_kernel(
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

    if (op == 3u) {
        res = permuteTryte(va);
    } else {
        #pragma unroll
        for (uint32_t i = 0u; i < TRYTE_SIZE; ++i) {
            uint32_t ta = (va >> (2u * i)) & 3u;
            uint32_t tb = (vb >> (2u * i)) & 3u;
            uint32_t tr = (op == 0u) ? tritAdd(ta, tb)
                        : (op == 1u) ? tritSub(ta, tb)
                                     : crazyOp(ta, tb);
            res |= (tr << (2u * i));
        }
    }
    C[idx] = res & TRYTE_MASK;
}

// Deterministic Malbolge Processor Step Kernel (one 59049-tryte VM per thread)
struct MalbolgeRegsDevice {
    uint32_t A, C, D, stepCount;
};

extern "C" __global__ void malbolge_run_kernel(
    MalbolgeRegsDevice* __restrict__ regs,
    uint32_t* __restrict__ memPool, // numVMs * 59049 trytes
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
        if (instr == 5u) break; // End

        uint32_t dAddr = tryteToNat(r.D);
        if (instr == 0u) { // Jmp
            r.C = mem[dAddr];
            r.D = incrementTryte(r.D);
        } else if (instr == 1u) { // Rot
            uint32_t mv = mem[dAddr];
            r.A = crazyTryte(r.A, mv);
            mem[dAddr] = permuteTryte(mv);
            r.D = incrementTryte(r.D);
        } else if (instr == 2u) { // Out
            lastOut[vm] = tryteToNat(r.A);
            r.D = incrementTryte(r.D);
        } else if (instr == 3u) { // In
            r.A = natToTryte(lastOut[vm]);
            r.D = incrementTryte(r.D);
        } else { // Nop
            r.D = incrementTryte(r.D);
        }
        r.stepCount += 1u;
    }
    regs[vm] = r;
}
