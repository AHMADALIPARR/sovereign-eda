/-=======================================================================
 SOVEREIGN LEVIATHAN NODE LICENSE
 License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
 Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
 ========================================================================

 This file is a covered work under the GNU Affero General Public License,
 version 3, together with the Sovereign Leviathan additional terms.

 Hark, though this node be but a spark,
 Its covenant endureth through the dark.

 Ignorantia juris non excusat.
 ========================================================================
-/

-- Copyright (c) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
-- SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ SOVEREIGN DEED: MALBOLGE_PROCESSOR_ROOT                                   │
-- │ "The Abyss Computes. Entropy Is Extracted. The Chain Holds."             │
-- │ DEED_ID: DEED-MALBOLGE_PROCESSOR_ROOT-073                                │
-- └───────────────────────────────────────────────────────────────────────────┘

namespace Sovereign.Deeds.MalbolgeProcessorRoot

open Nat

inductive Trit : Type where
  | Zero : Trit
  | One  : Trit
  | Two  : Trit
  deriving Repr, DecidableEq, Inhabited

def tritAdd (a b : Trit) : Trit :=
  match a, b with
  | .Zero, x   => x
  | x, .Zero   => x
  | .One, .One => .Two
  | .One, .Two => .Zero
  | .Two, .One => .Zero
  | .Two, .Two => .One

def tritSub (a b : Trit) : Trit :=
  match a, b with
  | x, .Zero   => x
  | .Zero, .One => .Two
  | .Zero, .Two => .One
  | .One, .One  => .Zero
  | .One, .Two  => .Two
  | .Two, .One  => .One
  | .Two, .Two  => .Zero

def crazyOp (a b : Trit) : Trit :=
  match a, b with
  | .Zero, .Zero => .One
  | .Zero, .One  => .Zero
  | .Zero, .Two  => .Zero
  | .One, .Zero  => .Two
  | .One, .One   => .Two
  | .One, .Two   => .One
  | .Two, .Zero  => .Zero
  | .Two, .One   => .Two
  | .Two, .Two   => .Two

def tryteSize : Nat := 10
def memorySize : Nat := 59049

structure Tryte where
  trits : Array Trit
  deriving Repr, Inhabited

def tritToNat (t : Trit) : Nat :=
  match t with
  | .Zero => 0
  | .One  => 1
  | .Two  => 2

def tryteToNat (t : Tryte) : Nat :=
  t.trits.foldl (fun acc trit => acc * 3 + tritToNat trit) 0

def natToTryte (n : Nat) : Tryte :=
  let digits := (List.range tryteSize).map (fun i => (n / 3 ^ i) % 3)
  { trits := (digits.map (fun d => match d with | 0 => .Zero | 1 => .One | _ => .Two)).toArray }

structure MalbolgeRegisters where
  A : Tryte
  C : Tryte
  D : Tryte
  deriving Repr, Inhabited

abbrev MalbolgeMemory := Array Tryte

structure MalbolgeProcessor where
  regs      : MalbolgeRegisters
  mem       : MalbolgeMemory
  entropy   : List Nat
  stepCount : Nat
  deriving Repr

/-! ## Width & Bounds Lemmas -/

theorem natToTryte_size (n : Nat) : (natToTryte n).trits.size = tryteSize := by
  simp [natToTryte, tryteSize]

theorem foldl_trit_bound (ls : List Trit) (acc : Nat) :
    ls.foldl (fun a t => a * 3 + tritToNat t) acc < (acc + 1) * 3 ^ ls.length := by
  induction ls generalizing acc with
  | nil => simp
  | cons hd tl ih =>
    simp only [List.foldl_cons, List.length_cons]
    have hlt : tritToNat hd < 3 := by cases hd <;> decide
    have hstep : acc * 3 + tritToNat hd + 1 ≤ (acc + 1) * 3 := by omega
    have h1 := ih (acc * 3 + tritToNat hd)
    calc
      tl.foldl (fun a t => a * 3 + tritToNat t) (acc * 3 + tritToNat hd)
          < (acc * 3 + tritToNat hd + 1) * 3 ^ tl.length := h1
      _ ≤ ((acc + 1) * 3) * 3 ^ tl.length := Nat.mul_le_mul_right _ hstep
      _ = (acc + 1) * 3 ^ (tl.length + 1) := by
          rw [Nat.pow_succ, Nat.mul_assoc, Nat.mul_comm 3 (3 ^ tl.length)]

theorem tryteToNat_lt_memorySize (t : Tryte) (h : t.trits.size = tryteSize) :
    tryteToNat t < memorySize := by
  have hlen : t.trits.toList.length = 10 := by
    simpa [tryteSize] using h
  have hb := foldl_trit_bound t.trits.toList 0
  rw [hlen] at hb
  simpa [tryteToNat, Array.foldl_eq_foldl_toList, memorySize] using hb

/-! ## Tryte Permutations & Entropy -/

def rotateLeft1 (a : Array Trit) : Array Trit :=
  if _h : a.size ≤ 1 then a
  else (a.extract 1 a.size).push a[0]!

theorem rotateLeft1_size (a : Array Trit) : (rotateLeft1 a).size = a.size := by
  unfold rotateLeft1
  split
  · rfl
  · rename_i h
    simp [Array.size_push, Array.size_extract]
    omega

def permuteTryte (t : Tryte) : Tryte :=
  let rotated := rotateLeft1 t.trits
  { trits := rotated.map (fun trit => crazyOp trit trit) }

theorem permuteTryte_size (t : Tryte) : (permuteTryte t).trits.size = t.trits.size := by
  simp [permuteTryte, Array.size_map, rotateLeft1_size]

def dedupNat : List Nat → List Nat
  | []      => []
  | x :: xs => x :: dedupNat (xs.filter (· != x))

def shannonEntropy (samples : List Nat) : Float :=
  if samples.length = 0 then 0.0
  else
    let total : Float := samples.length.toFloat
    let unique := dedupNat samples
    let probs := unique.map (fun x => (samples.count x).toFloat / total)
    -probs.foldl (fun acc p => acc + p * Float.log p) 0.0

/-! ## Instruction Decode & Execution -/

inductive MalbolgeInstruction where
  | Jmp | Rot | Out | In | Nop | End
  deriving Repr, DecidableEq

def decryptTryte (t : Tryte) (addr : Nat) : Tryte :=
  let addrTryte := natToTryte addr
  { trits := Array.zipWith tritSub t.trits addrTryte.trits }

def decodeInstruction (mem : MalbolgeMemory) (c : Tryte) : MalbolgeInstruction :=
  let addr := tryteToNat c
  let encrypted := mem[addr]!
  let decrypted := decryptTryte encrypted addr
  match decrypted.trits[0]! with
  | .Zero => .Jmp
  | .One  => .Rot
  | .Two  =>
    match decrypted.trits[1]! with
    | .Zero => .Out
    | .One  => .In
    | .Two  =>
      match decrypted.trits[2]! with
      | .Zero => .Nop
      | _     => .End

def incrementTryte (t : Tryte) : Tryte :=
  natToTryte ((tryteToNat t + 1) % memorySize)

theorem incrementTryte_size (t : Tryte) : (incrementTryte t).trits.size = tryteSize :=
  natToTryte_size _

def crazyTryte (a b : Tryte) : Tryte :=
  { trits := Array.zipWith crazyOp a.trits b.trits }

theorem crazyTryte_size (a b : Tryte)
    (ha : a.trits.size = tryteSize) (hb : b.trits.size = tryteSize) :
    (crazyTryte a b).trits.size = tryteSize := by
  simp [crazyTryte, Array.size_zipWith, ha, hb]

def executeInstruction (p : MalbolgeProcessor) : MalbolgeProcessor :=
  let instr := decodeInstruction p.mem p.regs.C
  match instr with
  | .Jmp =>
    let newC := p.mem[tryteToNat p.regs.D]!
    let newD := incrementTryte p.regs.D
    { p with regs := { p.regs with C := newC, D := newD }, stepCount := p.stepCount + 1 }
  | .Rot =>
    let memVal := p.mem[tryteToNat p.regs.D]!
    let newA := crazyTryte p.regs.A memVal
    let newMemVal := permuteTryte memVal
    let newD := incrementTryte p.regs.D
    let newMem := p.mem.set! (tryteToNat p.regs.D) newMemVal
    { p with regs := { p.regs with A := newA, D := newD }, mem := newMem, stepCount := p.stepCount + 1 }
  | .Out =>
    let newD := incrementTryte p.regs.D
    { p with regs := { p.regs with D := newD }, entropy := p.entropy ++ [tryteToNat p.regs.A], stepCount := p.stepCount + 1 }
  | .In =>
    let newD := incrementTryte p.regs.D
    let inputVal := if p.entropy.length > 0 then p.entropy.getLast! else 0
    { p with regs := { p.regs with A := natToTryte inputVal, D := newD }, stepCount := p.stepCount + 1 }
  | .Nop =>
    let newD := incrementTryte p.regs.D
    { p with regs := { p.regs with D := newD }, stepCount := p.stepCount + 1 }
  | .End => p

def malbolgeStep (p : MalbolgeProcessor) : MalbolgeProcessor :=
  executeInstruction p

def malbolgeRun (p : MalbolgeProcessor) (steps : Nat) : MalbolgeProcessor :=
  if steps = 0 then p else malbolgeRun (malbolgeStep p) (steps - 1)

def malbolgeGenesis : MalbolgeProcessor :=
  { regs := { A := natToTryte 0, C := natToTryte 0, D := natToTryte 0 }
  , mem := ((List.range memorySize).map (fun i => natToTryte (i % memorySize))).toArray
  , entropy := []
  , stepCount := 0 }

/-! ## Closed Invariants & Determinism (Zero `sorry`) -/

structure WellFormed (p : MalbolgeProcessor) : Prop where
  mem_size    : p.mem.size = memorySize
  tryte_width : ∀ t ∈ p.mem.toList, t.trits.size = tryteSize
  regs_valid  : p.regs.A.trits.size = tryteSize ∧
                p.regs.C.trits.size = tryteSize ∧
                p.regs.D.trits.size = tryteSize

theorem memory_size_invariant (p : MalbolgeProcessor) (hwf : WellFormed p) :
    p.mem.size = memorySize :=
  hwf.mem_size

theorem tryte_width_invariant (p : MalbolgeProcessor) (hwf : WellFormed p) :
    ∀ t ∈ p.mem.toList, t.trits.size = tryteSize :=
  hwf.tryte_width

theorem register_valid_invariant (p : MalbolgeProcessor) (hwf : WellFormed p) :
    p.regs.A.trits.size = tryteSize ∧
    p.regs.C.trits.size = tryteSize ∧
    p.regs.D.trits.size = tryteSize :=
  hwf.regs_valid

theorem code_pointer_valid (p : MalbolgeProcessor) (hwf : WellFormed p) :
    tryteToNat p.regs.C < memorySize :=
  tryteToNat_lt_memorySize p.regs.C hwf.regs_valid.2.1

theorem data_pointer_valid (p : MalbolgeProcessor) (hwf : WellFormed p) :
    tryteToNat p.regs.D < memorySize :=
  tryteToNat_lt_memorySize p.regs.D hwf.regs_valid.2.2

theorem mem_get!_size (p : MalbolgeProcessor) (hwf : WellFormed p) (idx : Nat)
    (hidx : idx < memorySize) :
    (p.mem[idx]!).trits.size = tryteSize := by
  have hbound : idx < p.mem.size := by rw [hwf.mem_size]; exact hidx
  have hmem : p.mem[idx]! = p.mem[idx]'hbound := getElem!_pos p.mem idx hbound
  rw [hmem]
  exact hwf.tryte_width p.mem[idx] (Array.getElem_mem_toList hbound)

theorem mem_set!_width (mem : MalbolgeMemory) (idx : Nat) (v : Tryte)
    (hmem : ∀ t ∈ mem.toList, t.trits.size = tryteSize)
    (hv : v.trits.size = tryteSize) :
    ∀ t ∈ (mem.set! idx v).toList, t.trits.size = tryteSize := by
  intro t ht
  by_cases hbound : idx < mem.size
  · have hlist := Array.mem_toList_setIfInBounds (a := mem) (i := idx) (v := v) hbound
    simp only [Array.set!_eq_setIfInBounds] at ht
    rcases Array.mem_toList_iff.mp ht with ⟨j, hj, rfl⟩
    by_cases hij : idx = j
    · subst hij
      simpa [Array.getElem_setIfInBounds] using hv
    · have hj' : j < mem.size := by simpa [Array.size_setIfInBounds] using hj
      have heq : (mem.setIfInBounds idx v)[j] = mem[j] :=
        Array.getElem_setIfInBounds_ne mem idx v j hj (Ne.symm hij)
      rw [heq]
      exact hmem mem[j] (Array.getElem_mem_toList hj')
  · simp [Array.set!, hbound] at ht
    exact hmem t ht

theorem malbolgeGenesis_wellFormed : WellFormed malbolgeGenesis where
  mem_size := by simp [malbolgeGenesis]
  tryte_width := by
    intro t ht
    simp only [malbolgeGenesis, Array.toList_toArray, List.mem_map, List.mem_range] at ht
    rcases ht with ⟨i, _, rfl⟩
    exact natToTryte_size _
  regs_valid := by
    simp [malbolgeGenesis, natToTryte_size]

theorem malbolgeStep_preserves_wellFormed (p : MalbolgeProcessor) (hwf : WellFormed p) :
    WellFormed (malbolgeStep p) := by
  have hD : tryteToNat p.regs.D < memorySize := data_pointer_valid p hwf
  have hmD : (p.mem[tryteToNat p.regs.D]!).trits.size = tryteSize := mem_get!_size p hwf _ hD
  unfold malbolgeStep executeInstruction
  cases decodeInstruction p.mem p.regs.C with
  | Jmp =>
    exact {
      mem_size := hwf.mem_size
      tryte_width := hwf.tryte_width
      regs_valid := ⟨hwf.regs_valid.1, hmD, incrementTryte_size p.regs.D⟩
    }
  | Rot =>
    exact {
      mem_size := by simp [Array.size_set!, hwf.mem_size]
      tryte_width := mem_set!_width p.mem _ _ hwf.tryte_width (by rw [permuteTryte_size]; exact hmD)
      regs_valid := ⟨crazyTryte_size _ _ hwf.regs_valid.1 hmD, hwf.regs_valid.2.1, incrementTryte_size p.regs.D⟩
    }
  | Out =>
    exact {
      mem_size := hwf.mem_size
      tryte_width := hwf.tryte_width
      regs_valid := ⟨hwf.regs_valid.1, hwf.regs_valid.2.1, incrementTryte_size p.regs.D⟩
    }
  | In =>
    exact {
      mem_size := hwf.mem_size
      tryte_width := hwf.tryte_width
      regs_valid := ⟨natToTryte_size _, hwf.regs_valid.2.1, incrementTryte_size p.regs.D⟩
    }
  | Nop =>
    exact {
      mem_size := hwf.mem_size
      tryte_width := hwf.tryte_width
      regs_valid := ⟨hwf.regs_valid.1, hwf.regs_valid.2.1, incrementTryte_size p.regs.D⟩
    }
  | End => exact hwf

theorem malbolgeRun_preserves_wellFormed (p : MalbolgeProcessor) (steps : Nat)
    (hwf : WellFormed p) : WellFormed (malbolgeRun p steps) := by
  induction steps generalizing p with
  | zero => simpa [malbolgeRun] using hwf
  | succ n ih =>
    simp only [malbolgeRun, Nat.succ_ne_zero, ↓reduceIte, Nat.add_sub_cancel]
    exact ih (malbolgeStep p) (malbolgeStep_preserves_wellFormed p hwf)

theorem malbolgeStep_deterministic (p1 p2 : MalbolgeProcessor)
    (hregs : p1.regs = p2.regs)
    (hmem : p1.mem = p2.mem)
    (hent : p1.entropy = p2.entropy) :
    (malbolgeStep p1).regs = (malbolgeStep p2).regs ∧
    (malbolgeStep p1).mem = (malbolgeStep p2).mem ∧
    (malbolgeStep p1).entropy = (malbolgeStep p2).entropy := by
  simp only [malbolgeStep, executeInstruction, hregs, hmem, hent]
  cases decodeInstruction p2.mem p2.regs.C <;> simp

theorem deterministic_execution (p1 p2 : MalbolgeProcessor) (steps : Nat)
    (hregs : p1.regs = p2.regs)
    (hmem : p1.mem = p2.mem)
    (hent : p1.entropy = p2.entropy) :
    (malbolgeRun p1 steps).regs = (malbolgeRun p2 steps).regs ∧
    (malbolgeRun p1 steps).mem = (malbolgeRun p2 steps).mem := by
  induction steps generalizing p1 p2 with
  | zero =>
    simp [malbolgeRun, hregs, hmem]
  | succ n ih =>
    simp only [malbolgeRun, Nat.succ_ne_zero, ↓reduceIte, Nat.add_sub_cancel]
    have hstep := malbolgeStep_deterministic p1 p2 hregs hmem hent
    exact ih (malbolgeStep p1) (malbolgeStep p2) hstep.1 hstep.2.1 hstep.2.2

/-! ## Verified Sovereign Kernel (Zero `sorry`) -/

def entropyThreshold : Float := 0.20

structure MalbolgeKernel where
  state      : MalbolgeProcessor
  wf         : WellFormed state
  entropy_ok : shannonEntropy state.entropy ≤ entropyThreshold

def MalbolgeKernel.genesis : MalbolgeKernel where
  state := malbolgeGenesis
  wf := malbolgeGenesis_wellFormed
  entropy_ok := by
    simp [malbolgeGenesis, shannonEntropy, entropyThreshold]
    decide

def MalbolgeKernel.step (k : MalbolgeKernel) : MalbolgeKernel :=
  let next := malbolgeStep k.state
  if h : shannonEntropy next.entropy ≤ entropyThreshold then
    { state := next
      wf := malbolgeStep_preserves_wellFormed k.state k.wf
      entropy_ok := h }
  else
    k

def MalbolgeKernel.run (k : MalbolgeKernel) (steps : Nat) : MalbolgeKernel :=
  if steps = 0 then k else (k.step).run (steps - 1)

theorem kernel_entropy_invariant (k : MalbolgeKernel) :
    shannonEntropy k.state.entropy ≤ entropyThreshold :=
  k.entropy_ok

theorem kernel_step_deterministic (k1 k2 : MalbolgeKernel)
    (hregs : k1.state.regs = k2.state.regs)
    (hmem : k1.state.mem = k2.state.mem)
    (hent : k1.state.entropy = k2.state.entropy) :
    k1.step.state.regs = k2.step.state.regs ∧
    k1.step.state.mem = k2.step.state.mem ∧
    k1.step.state.entropy = k2.step.state.entropy := by
  have hs := malbolgeStep_deterministic k1.state k2.state hregs hmem hent
  unfold MalbolgeKernel.step
  by_cases h1 : shannonEntropy (malbolgeStep k1.state).entropy ≤ entropyThreshold
  · have h2 : shannonEntropy (malbolgeStep k2.state).entropy ≤ entropyThreshold := by
      simpa [hs.2.2] using h1
    simp [h1, h2, hs.1, hs.2.1, hs.2.2]
  · have h2 : ¬ shannonEntropy (malbolgeStep k2.state).entropy ≤ entropyThreshold := by
      simpa [hs.2.2] using h1
    simp [h1, h2, hregs, hmem, hent]

theorem kernel_run_deterministic (k1 k2 : MalbolgeKernel) (steps : Nat)
    (hregs : k1.state.regs = k2.state.regs)
    (hmem : k1.state.mem = k2.state.mem)
    (hent : k1.state.entropy = k2.state.entropy) :
    (k1.run steps).state.regs = (k2.run steps).state.regs ∧
    (k1.run steps).state.mem = (k2.run steps).state.mem := by
  induction steps generalizing k1 k2 with
  | zero =>
    simp [MalbolgeKernel.run, hregs, hmem]
  | succ n ih =>
    simp only [MalbolgeKernel.run, Nat.succ_ne_zero, ↓reduceIte, Nat.add_sub_cancel]
    have hs := kernel_step_deterministic k1 k2 hregs hmem hent
    exact ih k1.step k2.step hs.1 hs.2.1 hs.2.2

end Sovereign.Deeds.MalbolgeProcessorRoot
