#!/usr/bin/awk -f
# pex_rc_check.awk — Zero-dependency RC delay & coupling budget checker
# Usage: awk -f pex_rc_check.awk ../../analog/parasitic_model.sp

function si(s,    low) {
    low = tolower(s)
    if (low ~ /f$/) { sub(/f$/, "e-15", low); return low + 0 }
    if (low ~ /p$/) { sub(/p$/, "e-12", low); return low + 0 }
    if (low ~ /n$/) { sub(/n$/, "e-9",  low); return low + 0 }
    return s + 0
}

BEGIN { max_tau = 5.0e-12 }

/^[Rr]/ { r_sum[subckt] += si($4) }
/^[Cc]/ { c_sum[subckt] += si($4) }
/^\.subckt/ { subckt = $2 }
/^\.ends/   {
    tau = r_sum[subckt] * c_sum[subckt]
    status = (tau <= max_tau) ? "PASS" : "WARN"
    printf "PEX %-20s R=%.2f Ohm  C=%.3e F  tau=%.3e s [%s]\n", subckt, r_sum[subckt], c_sum[subckt], tau, status
}
