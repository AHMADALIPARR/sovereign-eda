#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
cc -std=c11 -O2 -Wall -Wextra reference/malbolge.c -o reference/malbolge-original
reference/malbolge-original examples/nop_halt.mal > examples/nop_halt.stdout
test ! -s examples/nop_halt.stdout
printf 'PASS: original C interpreter compiles and NOP/HALT smoke test passes\n'
