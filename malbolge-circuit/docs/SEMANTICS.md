# Reference-interpreter semantics (design contract)

Machine: 59,049 ten-trit words, mutable unified instruction/data memory,
registers A, C, D initialized to 0. This project adopts the *reference interpreter*
I/O decoding (5 outputs; 23 inputs), rather than the reversed prose specification.

For a non-halting step with printable memory[C]:

1. Decode `(C + memory[C]) mod 94`.
2. Handle 4: C := memory[D]; 5: output A mod 256; 23: input to A
   (EOF => 59048); 39: A := memory[D] := rotate(memory[D]);
   40: D := memory[D]; 62: A := memory[D] := crazy(A,memory[D]);
   68/default: NOP; 81: HALT before encryption/increments.
3. Encrypt **memory[current C]** using the 94-character permutation indexed
   by memory[C]-33. Note a jump affects the address being encrypted.
4. Increment C and D modulo 59049.

Important: instruction memory value and encryption must be sampled in the correct
order if the operation overwrites memory[C] (possible when C=D).

Out-of-range/nonprintable instruction handling differs in reference vs prose
specification; choose a precise policy before implementing the full memory engine.

The supplied RTL/WhyML/Cryptol only implements the algebraic ALU core, not the
complete state machine, encryption permutation, loader, or SRAM dual circuit.

Sources:
- https://esolangs.org/wiki/Malbolge
- https://galoisinc.github.io/saw-script/master/saw-user-manual/verifying-hardware.html
