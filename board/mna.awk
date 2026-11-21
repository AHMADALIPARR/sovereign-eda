#!/usr/bin/awk -f
# mna.awk — Zero-dependency POSIX awk MNA Circuit Solver (DC + Transient)
# Usage: awk -f mna.awk board.txt

function si(s,    low) {
    low = tolower(s)
    if (low ~ /^[0-9.eE+-]+meg$/) { sub(/meg$/, "e6", low);  return low + 0 }
    if (low ~ /^[0-9.eE+-]+t$/)   { sub(/t$/,   "e12", low); return low + 0 }
    if (low ~ /^[0-9.eE+-]+g$/)   { sub(/g$/,   "e9", low);  return low + 0 }
    if (low ~ /^[0-9.eE+-]+k$/)   { sub(/k$/,   "e3", low);  return low + 0 }
    if (low ~ /^[0-9.eE+-]+m$/)   { sub(/m$/,   "e-3", low); return low + 0 }
    if (low ~ /^[0-9.eE+-]+u$/)   { sub(/u$/,   "e-6", low); return low + 0 }
    if (low ~ /^[0-9.eE+-]+n$/)   { sub(/n$/,   "e-9", low); return low + 0 }
    if (low ~ /^[0-9.eE+-]+p$/)   { sub(/p$/,   "e-12", low);return low + 0 }
    if (low ~ /^[0-9.eE+-]+f$/)   { sub(/f$/,   "e-15", low);return low + 0 }
    return s + 0
}

function get_node(name,    low) {
    low = tolower(name)
    if (low == "0" || low == "gnd") return 0
    if (!(low in node_id)) {
        node_id[low] = ++num_nodes
        node_name[num_nodes] = low
    }
    return node_id[low]
}

function eval_src(idx, t,    vo, va, f) {
    if (c_src_type[idx] == "SIN") {
        vo = c_vo[idx]; va = c_va[idx]; f = c_freq[idx]
        return vo + va * sin(2 * 3.141592653589793 * f * t)
    }
    return c_val[idx]
}

function stamp_res(n1, n2, g) {
    if (n1 > 0) A[n1, n1] += g
    if (n2 > 0) A[n2, n2] += g
    if (n1 > 0 && n2 > 0) { A[n1, n2] -= g; A[n2, n1] -= g }
}

function solve_linear(N,    i, j, k, piv, maxv, tmp, factor, sum) {
    for (k = 1; k <= N; k++) {
        piv = k; maxv = (A[k, k] < 0 ? -A[k, k] : A[k, k])
        for (i = k + 1; i <= N; i++) {
            tmp = (A[i, k] < 0 ? -A[i, k] : A[i, k])
            if (tmp > maxv) { maxv = tmp; piv = i }
        }
        if (piv != k) {
            for (j = k; j <= N; j++) {
                tmp = A[k, j]; A[k, j] = A[piv, j]; A[piv, j] = tmp
            }
            tmp = b[k]; b[k] = b[piv]; b[piv] = tmp
        }
        if (A[k, k] == 0) {
            printf "MNA ERROR: singular matrix at row %d\n", k > "/dev/stderr"
            exit 1
        }
        for (i = k + 1; i <= N; i++) {
            factor = A[i, k] / A[k, k]
            if (factor != 0) {
                for (j = k; j <= N; j++) A[i, j] -= factor * A[k, j]
                b[i] -= factor * b[k]
            }
        }
    }
    for (i = N; i >= 1; i--) {
        sum = b[i]
        for (j = i + 1; j <= N; j++) sum -= A[i, j] * x[j]
        x[i] = sum / A[i, i]
    }
}

function stamp_and_solve(t, dt,    N, nr, max_nr, i, j, ty, n1, n2, br, val, g, vp, ieq, vd, e, gd, id, diff, maxd) {
    N = num_nodes + num_branches
    max_nr = (has_diode ? 20 : 1)

    for (i = 1; i <= N; i++) x_nr[i] = x_prev[i]

    for (nr = 1; nr <= max_nr; nr++) {
        for (i = 1; i <= N; i++) {
            b[i] = 0
            for (j = 1; j <= N; j++) A[i, j] = 0
        }

        for (i = 1; i <= comp_count; i++) {
            ty = c_type[i]; n1 = c_n1[i]; n2 = c_n2[i]

            if (ty == "R") {
                stamp_res(n1, n2, 1.0 / c_val[i])
            } else if (ty == "C" && dt > 0) {
                g = c_val[i] / dt
                vp = (n1 > 0 ? x_prev[n1] : 0) - (n2 > 0 ? x_prev[n2] : 0)
                ieq = g * vp
                stamp_res(n1, n2, g)
                if (n1 > 0) b[n1] += ieq
                if (n2 > 0) b[n2] -= ieq
            } else if (ty == "L") {
                br = num_nodes + c_br[i]
                if (n1 > 0) { A[n1, br] += 1; A[br, n1] += 1 }
                if (n2 > 0) { A[n2, br] -= 1; A[br, n2] -= 1 }
                if (dt > 0) {
                    val = c_val[i] / dt
                    A[br, br] -= val
                    b[br] -= val * x_prev[br]
                }
            } else if (ty == "V") {
                br = num_nodes + c_br[i]
                if (n1 > 0) { A[n1, br] += 1; A[br, n1] += 1 }
                if (n2 > 0) { A[n2, br] -= 1; A[br, n2] -= 1 }
                b[br] += eval_src(i, t)
            } else if (ty == "I") {
                val = eval_src(i, t)
                if (n1 > 0) b[n1] -= val
                if (n2 > 0) b[n2] += val
            } else if (ty == "D") {
                vd = (n1 > 0 ? x_nr[n1] : 0) - (n2 > 0 ? x_nr[n2] : 0)
                # Shockley diode (Is=1e-14, Vt=0.02585), linearized above 0.8V
                if (vd > 0.8) {
                    e = exp(0.8 / 0.02585)
                    gd = (1e-14 / 0.02585) * e
                    id = 1e-14 * (e - 1.0) + gd * (vd - 0.8)
                } else if (vd < -5.0) {
                    gd = 1e-12
                    id = -1e-14 + gd * vd
                } else {
                    e = exp(vd / 0.02585)
                    gd = (1e-14 / 0.02585) * e + 1e-12
                    id = 1e-14 * (e - 1.0)
                }
                ieq = id - gd * vd
                stamp_res(n1, n2, gd)
                if (n1 > 0) b[n1] -= ieq
                if (n2 > 0) b[n2] += ieq
            }
        }

        solve_linear(N)

        maxd = 0
        for (i = 1; i <= N; i++) {
            diff = x[i] - x_nr[i]
            if (diff < 0) diff = -diff
            if (diff > maxd) maxd = diff
            x_nr[i] = x[i]
        }
        if (maxd < 1e-9) break
    }
    for (i = 1; i <= N; i++) x_prev[i] = x[i]
}

BEGIN {
    num_nodes = 0; num_branches = 0; comp_count = 0
    tstep = 0; tstop = 0; has_diode = 0
}

{
    sub(/#.*/, "")
    gsub(/^[ \t]+|[ \t]+$/, "")
    if ($0 == "" || $0 ~ /^\*/) next
}

tolower($1) == ".tran" {
    tstep = si($2); tstop = si($3)
    next
}

/^\./ { next }

{
    ref = $1
    ty = toupper(substr(ref, 1, 1))
    if (ty !~ /^[RCLVID]$/) next

    c = ++comp_count
    c_type[c] = ty
    c_n1[c] = get_node($2)
    c_n2[c] = get_node($3)

    if (ty == "V" || ty == "L") c_br[c] = ++num_branches
    if (ty == "D") has_diode = 1

    # Join fields 4..NF to handle SIN(vo va freq)
    rest = $4
    for (i = 5; i <= NF; i++) rest = rest " " $i

    if (toupper(rest) ~ /^SIN\(/) {
        sub(/^[^\(]*\(/, "", rest)
        sub(/\).*/, "", rest)
        split(rest, sp, /[ \t]+/)
        c_src_type[c] = "SIN"
        c_vo[c]   = si(sp[1])
        c_va[c]   = si(sp[2])
        c_freq[c] = si(sp[3])
    } else {
        c_src_type[c] = "DC"
        c_val[c] = (ty == "D" ? 0 : si($4))
    }
}

END {
    if (num_nodes == 0) exit 0

    # Header
    printf "time"
    for (i = 1; i <= num_nodes; i++) printf "\tv(%s)", node_name[i]
    printf "\n"

    # DC operating point at t = 0
    stamp_and_solve(0, 0)
    printf "%.6e", 0
    for (i = 1; i <= num_nodes; i++) printf "\t%.6e", x[i]
    printf "\n"

    # Transient loop
    if (tstep > 0 && tstop > 0) {
        for (t = tstep; t <= tstop + 1e-15; t += tstep) {
            stamp_and_solve(t, tstep)
            printf "%.6e", t
            for (i = 1; i <= num_nodes; i++) printf "\t%.6e", x[i]
            printf "\n"
        }
    }
}

