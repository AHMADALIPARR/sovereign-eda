* Thermal Corner & Derating Sweep for P4 Dual-Circuit
.include "../../analog/parasitic_model.sp"

.param temp_c = 25
.temp -40 25 85 125

Vdd  vdd  0  1.8
Vdrv drv_a 0 PULSE(0 1.8 0 40p 40p 2n 4n)
Vquiet drv_b 0 0

Xline drv_a drv_b rcv_a rcv_b 0 dual_interconnect

.tran 10p 10n
.end
