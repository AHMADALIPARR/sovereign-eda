* P4 Dual-Circuit Parasitic RC + Bitline Coupling Model
.subckt dual_interconnect drv_a drv_b rcv_a rcv_b vss
R_a1  drv_a  mid_a  12.5
R_a2  mid_a  rcv_a  12.5
C_a1  mid_a  vss    45f
C_a2  rcv_a  vss    30f

R_b1  drv_b  mid_b  12.5
R_b2  mid_b  rcv_b  12.5
C_b1  mid_b  vss    45f
C_b2  rcv_b  vss    30f

* Inter-line coupling capacitance
C_cc  mid_a  mid_b  18f
.ends dual_interconnect

.subckt sram_bitline bl bl_b sa_in sa_in_b vss
R_bl1  bl    sa_in    28.0
C_bl1  bl    vss      110f
R_bl2  bl_b  sa_in_b  28.0
C_bl2  bl_b  vss      110f
C_diff bl    bl_b     22f
.ends sram_bitline
