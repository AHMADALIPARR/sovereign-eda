# STATUS — Sovereign EDA

## Verification (run 2026-11-21, this VM)

- `make test` (Python test oracle `tests/test_core.py`): PASS.
  9 trit pairs, 59049 rotations and range checks, 10000 crazy-word
  samples.
- Reference interpreter build (`cc -std=c11 -O2 -Wall -Wextra
  reference/malbolge.c`): compiles with one unused-variable warning
  for `j` in `main`, as noted in `malbolge-circuit/README.md`.
- `tests/test_reference.sh` (NOP/HALT smoke test): PASS. Exit code 0,
  empty stdout.
- Cat program (from the Malbolge specification page, run against the
  reference interpreter): echoes input exactly, then emits byte 0xA8
  (168 = 59048 mod 256, the EOF marker) repeatedly, because that
  program does not stop on EOF. This matches the specification note.
- GHDL analyze (`ghdl -a --std=08 rtl/malbolge_alu.vhd`): exit 0,
  no errors.

## Toolchain installed on this VM for the markdown's commands

- Why3 1.6.0, Yosys 0.33, yosys-plugin-ghdl, ghdl-gcc 4.1.0
  (all via apt), SAW 1.5 with bundled solvers
  (`~/workspace/.tools/saw-1.5-ubuntu-24.04-X64-with-solvers/`).

## `make whyml`: PASSES

- Fixed 2026-11-21 on the owner's order ("fix the slash"): all 20
  `/` division operators in `semantics/MalbolgeCore.mlw` replaced
  with prefix `div` (Why3 1.6.0 has no `/` infix in scope for
  integers). The same run exposed a second, identical issue: infix
  `mod` is also not in scope in Why3 1.6.0, so all 23 `mod` uses
  were converted to prefix form (`mod x 3`). The `/\` logical-AND
  operators were left untouched. No other change to the file:
  same functions, same requires/ensures, same bodies.
- `why3 prove` typechecks the file, and with Z3 4.8.12 all five
  verification conditions discharge Valid: crazy_trit, rotate,
  decode, inc, crazy10.

## `make analyze`: PASSES

- After the toolchain install above, the full target runs:
  GHDL analyzes the VHDL, Yosys (with the ghdl plugin) synthesizes
  the ALU, CHECK pass reports 0 problems, and it writes
  `build/malbolge_alu.json` (155,906 bytes, 156 cells:
  23 mux, 20 logic_not, 20 eq, 20 pmux, 20 modfloor, 18 div,
  11 mul, 11 add, 10 reduce_or, 2 le, 1 and).

## `make prove`: BLOCKERS FIXED, PROOF RUNS BUT SLOW

- Fixed 2026-11-21 on the owner's order ("fix those"):
  - Blocker 1, paths: the SAW script's relative paths are now
    `../cryptol/MalbolgeCore.cry` and
    `../build/malbolge_alu.json`, because SAW resolves paths
    relative to the script's own directory (`saw/`).
  - Blocker 2, `$modfloor` cells: a Yosys techmap file
    `yosys/modfloor_map.v` expands each `$modfloor` cell into
    `$div` / `$mul` / `$sub` (identity `a mod b =
    a - (a div b) * b`, valid for floor div/mod; the design's
    values are naturals, so it holds). The Makefile `analyze`
    target now runs `techmap -map yosys/modfloor_map.v` before
    `write_json`. The VHDL and Cryptol files were not changed.
- `make analyze` verified with the fix: the JSON now has zero
  `$modfloor` cells (30 mul, 23 mux, 22 div, 20 logic_not,
  20 eq, 20 pmux, 20 sub, 10 reduce_or, 10 add, 2 le, 1 and).
- The proof itself: SAW 1.5 loads the script and the JSON and
  starts the `w4` equivalence check, but it did not finish
  within a 10-minute run on this VM (1.5 CPUs) — the 16-bit
  div/mul circuits make the SMT problem heavy. It was stopped
  by the 10-minute timeout, not by an error. A bigger machine
  (or a longer run) may complete it.

## Lean reproduction (2026-11-21, from the owner's screen photos)

The owner's Lean 4 Malbolge formalization lives deep in a 300,000-line
repo that cannot be read into this workspace, so he sent screen photos
and ordered the files reproduced from them (`lean/`). The reproduction
is labeled in-file: what was clearly readable is his code, what was
cut off or unreadable is marked RECONSTRUCTED or CUT OFF, and it is
not presented as his verbatim original.

- `lean/MalbolgePTXKernel.lean`: REPLACED 2026-11-21 with the owner's
  verbatim pasted file (DEED-MALBOLGE_PTX_KERNEL-074, Sovereign
  Leviathan license header). The verbatim `rtx3080Config := ⟨⟩`
  does not elaborate under Lean 4.9.0, 4.12.0, or 4.21.0 core —
  `⟨⟩` passes zero arguments to a six-field constructor and does
  not use the field defaults; `{}` does. On the owner's order
  ("whatever compiles, fix it if it needs a fix") the file now
  uses `{}` (f589e2d) and checks clean under Lean 4.9.0, exit 0.
- `lean/MalbolgeProcessor.lean`: the core definitions (Trit, tritAdd,
  tritSub, crazyOp, Tryte, conversions) elaborate under Lean 4.9.0
  core and all five #eval checks pass (mod-3 add/sub, standard crazy
  table, natToTryte/tryteToNat roundtrip, wrap at 59049). The file as
  a whole cannot be fully checked on this VM: it needs Batteries
  (Array.ofList, Array.length, Array.rotateLeft, Std.HashSet) and
  Mathlib (Real.log), neither built here. Two open questions for the
  owner: (1) the photos were ambiguous on five crazyOp entries — the
  standard table from his own repo oracle was used; (2) `deriving
  Repr` on MalbolgeProcessor failed here because MalbolgeMemory is a
  plain def — it may need @[reducible] or may elaborate fine in his
  full environment. The invariant proof scripts are cut off in the
  photos and are reproduced as far as visible, with `sorry` marking
  the missing tails.

## GPU kernels (2026-11-21, owner's pasted code)

- `gpu/malbolge_ternary.cu` and `gpu/malbolge_ternary.ptx` are the
  owner's verbatim pasted kernels. Both encode each Tryte as a
  20-bit packed `uint32_t` (10 trits x 2 bits, 00 = Zero, 01 = One,
  10 = Two), with tryteSize = 10 and memorySize = 59049, and both
  implement the exact Lean truth tables for tritAdd, tritSub,
  crazyOp (the owner's variant table, LUT 0x00281A01), permuteTryte,
  and malbolgeStep. The CUDA file holds the device functions plus
  two kernels: `ternary_arith_kernel` (elementwise tritAdd /
  tritSub / crazyOp / permuteTryte) and `malbolge_run_kernel`
  (one 59049-tryte VM per thread). The PTX file holds `trit_add`,
  `trit_sub`, `crazy_op`, and the `ternary_tryte_kernel` entry.
- Verification on this VM: there is no CUDA toolchain and no GPU
  here, so neither file was compiled or assembled. The CUDA device
  functions were verified by execution instead: `gpu/tests/
  verify_cuda_host.c` copies them verbatim (CUDA qualifiers
  stripped) and checks them against an independent C implementation
  of the Lean definitions. Result: ALL CHECKS PASS — tritAdd /
  tritSub / crazyOp all 9 pairs each; natToTryte all 59049 values;
  tryteToNat, crazyTryte, decryptTryte, permuteTryte,
  incrementTryte over valid packed trytes; decodeInstruction all
  seven branches (Jmp, Rot, Out, In, Nop, End x2). The first run
  of that harness failed on 96 checks; the failures were the
  harness's own faults (it fed the functions trytes containing the
  out-of-domain trit value 3, and it stored the decode test program
  at the raw number instead of at tryteToNat(C)), not the CUDA
  code — fixed in the harness, and the rerun passes clean. The
  PTX was verified by reading it against the CUDA source: the three
  functions and the kernel loop match the CUDA operations
  instruction for instruction, including the rotate-left-1 before
  the permute loop. It was not assembled (no ptxas on this VM).
- The CUDA and PTX code reproduce the Lean definitions exactly,
  including the endianness behavior flagged above: natToTryte
  writes the least-significant base-3 digit at position 0 while
  tryteToNat reads position 0 as the most significant digit, so
  the two are not inverses. That is the Lean file's own behavior,
  carried into the kernels as written, not a discrepancy
  introduced by the kernels.

## Scope

Phase 1 is the combinational ALU only. The reference interpreter is
the full machine executable. There is no complete CPU or dual-SRAM
circuit in this tree. Phase 2 (sequential machine with dual SRAM banks
and self-encrypting instruction fetch) and Phase 3 (Verilog-A/PEX
timing contracts) are the stated next phases in
`malbolge-circuit/README.md` and are not built here.

The reference interpreter has the known reference-specific ambiguity
for nonprintable instructions and for initialization with under two
source instructions; these are specified in
`malbolge-circuit/docs/SEMANTICS.md`, not silently assumed.

## Lean ProcessorRoot (verbatim, 2026-11-21)

- `lean/MalbolgeProcessorRoot.lean` is the owner's verbatim pasted file
  (DEED-MALBOLGE_PROCESSOR_ROOT-073, 443 lines, zero `sorry` in the
  text). It replaces the earlier photo reproduction
  `lean/MalbolgeProcessor.lean`, which is removed: the verbatim file
  corrects it in three places — the crazy table is the owner's own
  variant (not the standard Malbolge table), `natToTryte` uses plain
  `(n / 3 ^ i) % 3` with `.toArray`, and `MalbolgeMemory` is an
  `abbrev` (which is why `deriving Repr` and `.size` elaborate).
- Check on this VM: this box cannot determine whether the file
  compiles. It has core Lean only, no Batteries/Mathlib, and the
  file uses identifiers from those libraries. The local errors say
  the toolchain here is incomplete, not anything about the file in
  the owner's environment. The file was committed verbatim as sent;
  no fix was decided from this box's limits.
- Note: `natToTryte` (little-endian, `(n / 3 ^ i) % 3`) and
  `tryteToNat` (big-endian fold) are not inverses of each other as
  written; no theorem in the file asserts the roundtrip. Flagged to
  the owner, not changed.

## Board (2026-11-21 ~10:33 PST)
The actual board is in `board/`. The document arrived as an iOS binary-plist paste; the clean text was extracted from it (42,087 characters, 1,350 lines) and the code was taken apart into separate files: `board/eda.awk` (full compiler, SPICE / Verilog-A / netlist / KiCad modes), `board/eda-basic.awk` (the first version, SPICE / netlist), `board/mna.awk` (pure-awk MNA solver, DC + transient, nonlinear diodes by Newton-Raphson), `board/p4-dual-circuit/verification/pex/pex_rc_check.awk` (RC delay and coupling budget checker), `board/examples/board.txt` (RC low-pass + diode clipper), `board/examples/board-hybrid.txt` (RC filter + behavioral memristive load with inline Verilog-A). The flat `board/BOARD.md` copy of the whole document was removed 2026-11-21: it duplicated every extracted file in one 1,349-line markdown dump and did not belong in the repo. The source .bin paste is kept in the workspace, so the document is recoverable. Note: the awk files and the WhyML / Cryptol / SAW specs are verbatim from the document. The VHDL RTL in `board/p4-dual-circuit/rtl/` and `board/sram-write-cell/` was written from the specs in the original .bin document, which named those files by path but did not contain the VHDL source; the clean document the owner sent 2026-11-21 (`zero-dependency_POSIX_pipeline.md`) does contain the VHDL, and all 29 board files in the repo were reconciled against it by execution that day and match it verbatim, including the VHDL. Verified by execution on this VM: eda-basic compiles board.txt to a SPICE deck; eda.awk emits SPICE, netlist, and Verilog-A (board_top with the soft_clipper module) from the examples; mna.awk runs the RC transient and the output lags the sine as a low-pass should. One note: the V1 SIN source value has spaces in it, so the ERC flags `sin(0` and `5` as floating nets; that is the board as written, not an extraction error.

## MalbolgeProcessor restored (2026-11-21 ~10:32 PST)
`lean/MalbolgeProcessor.lean` was removed from the repo in error when ProcessorRoot was added. It is a separate file from ProcessorRoot (different namespace, different implementations: plain `def` MalbolgeMemory, `Std.HashSet` + `Real.log` entropy, `.rotateLeft`, `.length`), and the owner was right that half the Lean code was missing. Restored from the git history (commit cd0d623) with two corrections from his verbatim ProcessorRoot file applied: the crazy table is his own variant, and natToTryte uses plain i. The core definitions (Trit, tritAdd, tritSub, crazyOp, conversions) were re-checked by execution under Lean 4.9.0: all seven crazy-table checks pass. The file remains a photo reproduction, labeled as such in its header; the owner can paste the verbatim text to replace it.

## V2 kernels — benchmark variant (2026-11-21, new files, v1 untouched)

The owner ordered a NEW kernel to benchmark against v1, not a fix to
v1: "We don't touch ours because it's what's works. We can try the
other way on new ones." So v1 (`gpu/malbolge_ternary.cu`,
`gpu/malbolge_ternary.ptx`, `lean/MalbolgeProcessorRoot.lean`) is
unchanged. V2 is three new files that try the other way:

- `lean/MalbolgeTryteV2.lean` — namespace
  Sovereign.Deeds.MalbolgeTryteV2. Trit, tritAdd, tritSub, crazyOp
  (owner's variant table), tryteSize, memorySize, Tryte, tritToNat
  are identical to ProcessorRoot. `tryteToNat` is FIXED, in the
  power-sum form: slot i is the 3^i digit, so
  tryteToNat (natToTryte n) = n. `natToTryte` is unchanged.
  Checks clean under Lean 4.9.0 core, exit 0. The mathematical
  content of the roundtrip is proven: `sum_digits_mod` —
  (List.range k).foldl (fun acc i => acc + (n / 3^i % 3) * 3^i) 0
  = n % 3^k — plus the helper lemmas `range_loop` and
  `range_succ`. The general roundtrip theorem
  tryteToNat (natToTryte n) = n is NOT in the file: it was left out
  deliberately rather than stated with a sorry. The remaining gap
  is array-index plumbing, not math, and the roundtrip is verified
  by execution over all 59,049 values in the host harness below.
- `gpu/malbolge_ternary_v2.cu` — dual-purpose: under nvcc it is
  CUDA; under a host C compiler it is plain C (the device
  qualifiers are defined away), so the host harness includes it
  directly instead of copying functions. Fixed tryteToNat (Horner,
  high to low). SWAR packed ops: tryteAdd_swar, tryteSub_swar,
  crazyTryte_swar evaluate all 10 trits in parallel from the
  0x55555 / 0xAAAAA bitplanes — no 10-iteration loop, no calls.
  Kernels: ternary_arith_kernel_v2 (SWAR) and
  malbolge_run_kernel_v2 (same VM structure as v1, v2 step
  functions).
- `gpu/malbolge_ternary_v2.ptx` — three entries: a scalar
  `crazy_op_bfe` .func using `bfe.u32` (the user's optimization:
  shr + and collapses to one bfe.u32 res, lut, sh, 2);
  `ternary_tryte_kernel_v2_scalar` (the 10-iteration loop with the
  op bodies INLINED — zero call instructions, the middle benchmark
  point); `ternary_tryte_kernel_v2` (SWAR, straight-line bitplane
  ops, no loop, no calls).

Verification by execution (`gpu/tests/verify_v2_host.c`):
ALL V2 CHECKS PASS. Roundtrip tryteToNat(natToTryte(n)) == n:
v2 0 failures / 59,049; v1 measured alongside at 58,806 / 59,049,
the known count. SWAR add/sub/crazy match the v1 scalar loop ops
bit for bit and match the Lean reference, over every valid tryte
against the spread plus 20,000 random pairs. v2 crazyTryte,
decryptTryte, permuteTryte match v1 exactly. v2 incrementTryte
and decodeInstruction follow the fixed tryteToNat and match the
Lean v2 reference on all branches. The v1 harness was re-run after
the v2 work and still passes (ALL CHECKS PASS) — v1 untouched.

A real bug the harness caught: the first v2 run failed 2,081,442
checks, all in crazyTryte_swar (and permuteTryte through it).
The crazy r0 term (~a1 & ~a0 & ~b1 & ~b0) is made only of
complements, so a bare ~x is all ones in the odd slots and the
upper bits and the term leaks there — the add/sub formulas never
hit this because every one of their terms has a positive bitplane
factor. Fixed by masking r1 and r0 to PLANE_LO before combining,
in the .cu (all three SWAR functions) and in the PTX COMBINE
block. Rerun: ALL V2 CHECKS PASS.

Benchmark (`gpu/tests/bench_v1_v2.c`, host CPU proxy — there is no
GPU, nvcc, or ptxas on this VM, so no GPU timing is claimed):
cache-resident 20M random valid-tryte calls per op. SWAR vs the v1
loop: tryteAdd 3.5–4.5x, tryteSub 4.5–4.6x, crazyTryte 3.9–4.0x
faster on the host CPU; tryteToNat 1.0x (same loop, direction only).
Static PTX: the v1 kernel executes 10 `call` instructions per
tryte (one per lane, inside the loop); both v2 kernels execute
zero. The v1 crazy_op .func is 9 instructions (shr + and); the v2
bfe version is 8. Hand-counted dynamic instructions per tryte
(op=add): v1 about 224, v2 SWAR about 62 — roughly 3.6x fewer,
consistent with the measured CPU proxy. Real GPU timing is a
Jetson measurement, not this number.

## Board, full extraction (2026-11-21 ~10:36 PST)
The first board commit (807b497) only extracted the awk scripts and the board examples. The owner was right: the document holds a lot more code. The full document was re-extracted by file path. `board/p4-dual-circuit/` now holds the complete project tree: semantics/ (state, sram, oscillator, refinement — WhyML), cryptol/ (state, sram, circuit_contract), saw/ (digital_equivalence, sram_refinement, proof_gate), rtl/ (p4_controller, dual_circuit, sram_bank, phase_calibrator — VHDL), analog/ (oscillator.va, relaxation.va, parasitic_model.sp), verification/ (psl/dual_circuit.psl, pex/pex_rc_check.awk, thermal/thermal_sweep.sp). `board/sram-write-cell/` holds the standalone SRAM write-cell: SRAMSemantics.mlw, sram.cry, write_cell_equivalence.saw, sram_write_cell.vhd. The duplicate top-level `board/pex_rc_check.awk` was removed; the p4 version is canonical. Verified by execution: all four awk scripts parse and run (exit 0); eda.awk and mna.awk were run against the examples. The VHDL was not compiled here — GHDL is not installed on this VM anymore, so no compile claim is made for it.
