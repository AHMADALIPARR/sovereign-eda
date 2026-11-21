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
  Leviathan license header). One finding, not a fix: the verbatim
  `rtx3080Config := ⟨⟩` does not elaborate under Lean 4.9.0, 4.12.0,
  or 4.21.0 core — `⟨⟩` passes zero arguments to a six-field
  constructor and does not use the field defaults; `{}` does. The
  file was committed verbatim as sent (8c4b205); the `⟨⟩` vs `{}`
  question is the owner's to answer. Everything else in the file
  checks clean (the earlier photo reproduction with `{}` passed
  exit 0).
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
