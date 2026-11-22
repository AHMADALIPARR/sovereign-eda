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
-- │ SOVEREIGN DEED: MALBOLGE_TRYTE_V2                                         │
-- │ V2 tryte layer. Benchmark variant. V1 is untouched.                       │
-- │                                                                           │
-- │ The one change: tryteToNat reads slot i as the 3^i digit, so it is the   │
-- │ inverse of natToTryte. V1 folded the stored array big-endian, which     │
-- │ treated slot 0 (the least significant digit) as the 3^9 digit.           │
-- │ The crazy table, the trit operations, and natToTryte are identical to    │
-- │ MalbolgeProcessorRoot.                                                    │
-- │                                                                           │
-- │ Verification status. The roundtrip tryteToNat (natToTryte n) = n is     │
-- │ verified by execution over all 59,049 values in                         │
-- │ gpu/tests/verify_v2_host.c, and its mathematical content is the proven   │
-- │ sum_digits_mod lemma below (base-3 digit reconstruction). The general    │
-- │ Lean proof of the roundtrip is open work: it needs array-index          │
-- │ plumbing (List.range / Array.getElem lemmas) that core Lean 4.9.0 does   │
-- │ not ship, and it is not faked here with a sorry.                         │
-- └───────────────────────────────────────────────────────────────────────────┘

namespace Sovereign.Deeds.MalbolgeTryteV2

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

/-- Fixed tryteToNat: slot i is the 3^i digit. This is the little-endian
    reading that inverts natToTryte. It is the same value as the high-to-low
    Horner iteration in the v2 CUDA kernel. -/
def tryteToNat (t : Tryte) : Nat :=
  (List.range tryteSize).foldl (fun acc i => acc + tritToNat (t.trits[i]!) * 3 ^ i) 0

def natToTryte (n : Nat) : Tryte :=
  let digits := (List.range tryteSize).map (fun i => (n / 3 ^ i) % 3)
  { trits := (digits.map (fun d => match d with | 0 => .Zero | 1 => .One | _ => .Two)).toArray }

/-! ## Digit reconstruction -/

/-- `List.range` grows by appending the new top element. Core Lean 4.9.0
    does not ship this, so it is proven here from the `range.loop`
    definition. -/
theorem range_loop (n : Nat) (ns : List Nat) :
    List.range.loop n ns = List.range n ++ ns := by
  induction n generalizing ns with
  | zero => rfl
  | succ n ih =>
    show List.range.loop n (n :: ns) = List.range (n + 1) ++ ns
    rw [ih]
    have h1 : List.range (n + 1) = List.range n ++ [n] := by
      show List.range.loop n [n] = List.range n ++ [n]
      rw [ih]
    rw [h1, List.append_assoc]
    rfl

theorem range_succ (k : Nat) : List.range (k + 1) = List.range k ++ [k] := by
  have h2 := range_loop k [k]
  exact h2

/-- The base-3 digit reconstruction: the digits of n, weighted by 3^i,
    add back up to n modulo 3^k. This is the mathematical content of the
    roundtrip. -/
theorem sum_digits_mod (k n : Nat) :
    (List.range k).foldl (fun acc i => acc + (n / 3 ^ i % 3) * 3 ^ i) 0 = n % 3 ^ k := by
  induction k generalizing n with
  | zero =>
    rw [Nat.pow_zero, Nat.mod_one]
    rfl
  | succ k ih =>
    rw [range_succ, List.foldl_append, List.foldl_cons, List.foldl_nil, ih, Nat.pow_succ]
    have hdiv : n = 3 ^ k * (n / 3 ^ k) + n % 3 ^ k := (Nat.div_add_mod n (3 ^ k)).symm
    have hq : n / 3 ^ k = 3 * (n / 3 ^ k / 3) + n / 3 ^ k % 3 :=
      (Nat.div_add_mod (n / 3 ^ k) 3).symm
    have hlt : n % 3 ^ k + (n / 3 ^ k % 3) * 3 ^ k < 3 ^ k * 3 := by
      have h3 : (n / 3 ^ k % 3) * 3 ^ k ≤ 2 * 3 ^ k := by
        apply Nat.mul_le_mul_right
        omega
      calc n % 3 ^ k + (n / 3 ^ k % 3) * 3 ^ k < 3 ^ k + 2 * 3 ^ k := by omega
        _ = 3 ^ k * 3 := by omega
    have hdecomp : n = (n % 3 ^ k + (n / 3 ^ k % 3) * 3 ^ k) + (n / 3 ^ k / 3) * (3 ^ k * 3) := by
      calc n = 3 ^ k * (n / 3 ^ k) + n % 3 ^ k := hdiv
        _ = 3 ^ k * (3 * (n / 3 ^ k / 3) + n / 3 ^ k % 3) + n % 3 ^ k := by
            have h : 3 ^ k * (n / 3 ^ k) = 3 ^ k * (3 * (n / 3 ^ k / 3) + n / 3 ^ k % 3) :=
              congrArg (fun x => 3 ^ k * x) hq
            rw [h]
        _ = (n % 3 ^ k + (n / 3 ^ k % 3) * 3 ^ k) + (n / 3 ^ k / 3) * (3 ^ k * 3) := by
            rw [Nat.mul_add, ← Nat.mul_assoc,
              Nat.mul_comm ((3 ^ k) * 3) (n / 3 ^ k / 3), Nat.mul_comm (3 ^ k) (n / 3 ^ k % 3)]
            omega
    conv => rhs; rw [hdecomp]
    rw [Nat.add_mul_mod_self_right, Nat.mod_eq_of_lt hlt]

/-! ## Spot checks (by evaluation) -/

example : tryteToNat (natToTryte 0) = 0 := by decide
example : tryteToNat (natToTryte 1) = 1 := by decide
example : tryteToNat (natToTryte 2) = 2 := by decide
example : tryteToNat (natToTryte 3) = 3 := by decide
example : tryteToNat (natToTryte 59048) = 59048 := by decide
example : tryteToNat (natToTryte 19683) = 19683 := by decide

end Sovereign.Deeds.MalbolgeTryteV2
