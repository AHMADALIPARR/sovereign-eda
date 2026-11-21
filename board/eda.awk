#!/usr/bin/awk -f
# eda.awk — Zero-dependency POSIX Virtual EDA
# Modes: -v mode=spice | veriloga | netlist | kicad

function si_to_real(s,    low) {
    low = tolower(s)
    if (low ~ /^[0-9.eE+-]+meg$/) { sub(/meg$/, "e6", low);  return low }
    if (low ~ /^[0-9.eE+-]+t$/)   { sub(/t$/,   "e12", low); return low }
    if (low ~ /^[0-9.eE+-]+g$/)   { sub(/g$/,   "e9", low);  return low }
    if (low ~ /^[0-9.eE+-]+k$/)   { sub(/k$/,   "e3", low);  return low }
    if (low ~ /^[0-9.eE+-]+m$/)   { sub(/m$/,   "e-3", low); return low }
    if (low ~ /^[0-9.eE+-]+u$/)   { sub(/u$/,   "e-6", low); return low }
    if (low ~ /^[0-9.eE+-]+n$/)   { sub(/n$/,   "e-9", low); return low }
    if (low ~ /^[0-9.eE+-]+p$/)   { sub(/p$/,   "e-12", low); return low }
    if (low ~ /^[0-9.eE+-]+f$/)   { sub(/f$/,   "e-15", low); return low }
    return s
}

function norm_net(n,    low) {
    low = tolower(n)
    return (low == "gnd" || low == "0") ? "0" : low
}

function add_net(n, ref, pin_idx) {
    if (!(n in net_seen)) {
        net_seen[n] = 1
        net_list[++net_count] = n
    }
    net_deg[n]++
    net_pins[n] = (net_pins[n] == "" ? ref "." pin_idx : net_pins[n] " " ref "." pin_idx)
}

BEGIN {
    if (mode == "") mode = "spice"
    if (mode == "va") mode = "veriloga"
}

# Capture raw lines inside .va ... .endva blocks
in_va {
    if (tolower($1) == ".endva") {
        in_va = 0
        next
    }
    va_body[va_cur, ++va_lines[va_cur]] = $0
    next
}

# Strip comments and whitespace
{
    sub(/#.*/, "")
    gsub(/^[ \t]+|[ \t]+$/, "")
    if ($0 == "" || $0 ~ /^\*/) next
}

# Capture .subckt ... .ends verbatim for SPICE
tolower($1) == ".subckt" {
    in_subckt = 1
    subckt_lines[++subckt_count] = $0
    next
}
in_subckt {
    subckt_lines[++subckt_count] = $0
    if (tolower($1) == ".ends") in_subckt = 0
    next
}

# Parse .va <name> <ports...> [param=val...]
tolower($1) == ".va" {
    in_va = 1
    va_cur = ++va_count
    va_name[va_cur] = $2
    for (i = 3; i <= NF; i++) {
        if ($i ~ /=/) {
            split($i, kv, "=")
            va_pcount[va_cur]++
            va_pname[va_cur, va_pcount[va_cur]] = kv[1]
            va_pval[va_cur, va_pcount[va_cur]]  = si_to_real(kv[2])
        } else {
            va_portcount[va_cur]++
            va_port[va_cur, va_portcount[va_cur]] = norm_net($i)
        }
    }
    next
}

# Pass other SPICE dot-directives
/^\./ {
    directives[++dir_count] = $0
    next
}

# Parse component: <REF> <NET1> <NET2> [NET3...] <VAL_OR_MODEL> [PARAM=VAL...]
{
    ref = $1
    if (seen_ref[ref]++) {
        printf "ERC WARNING: duplicate reference '%s'\n", ref > "/dev/stderr"
    }

    c_idx = ++comp_count
    c_ref[c_idx]  = ref
    c_type[c_idx] = toupper(substr(ref, 1, 1))
    c_raw[c_idx]  = $0

    # Separate trailing key=val parameters from positional tokens
    last_pos = NF
    p_str = ""
    while (last_pos > 2 && $last_pos ~ /=/) {
        p_str = ($last_pos) (p_str == "" ? "" : " " p_str)
        last_pos--
    }
    c_params[c_idx] = p_str
    c_val[c_idx]    = $last_pos

    nets_str = ""
    c_nports[c_idx] = 0
    for (i = 2; i < last_pos; i++) {
        n = norm_net($i)
        c_nports[c_idx]++
        c_port[c_idx, c_nports[c_idx]] = n
        nets_str = (nets_str == "" ? n : nets_str " " n)
        add_net(n, ref, i - 1)
    }
    c_nets[c_idx] = nets_str

    bom_key = c_type[c_idx] "|" c_val[c_idx]
    if (!(bom_key in bom_seen)) {
        bom_seen[bom_key] = 1
        bom_keys[++bom_count] = bom_key
    }
    bom_qty[bom_key]++
    bom_refs[bom_key] = (bom_refs[bom_key] == "" ? ref : bom_refs[bom_key] ", " ref)
}

END {
    # ERC Checks
    if (!("0" in net_seen)) {
        print "ERC WARNING: no ground reference ('0' or 'gnd') found" > "/dev/stderr"
    }
    for (i = 1; i <= net_count; i++) {
        n = net_list[i]
        if (n != "0" && net_deg[n] < 2) {
            printf "ERC WARNING: floating net '%s' (%s)\n", n, net_pins[n] > "/dev/stderr"
        }
    }

    if (mode == "spice") {
        print "* Virtual EDA SPICE Netlist (eda.awk)"
        if (va_count > 0) {
            print "* Note: compile Verilog-A modules with OpenVAF/ADMS or .hdl"
            for (v = 1; v <= va_count; v++) {
                printf "* .hdl \"%s.va\"\n", va_name[v]
            }
        }
        for (s = 1; s <= subckt_count; s++) print subckt_lines[s]
        for (i = 1; i <= comp_count; i++) {
            printf "%-6s %-18s %s%s\n", c_ref[i], c_nets[i], c_val[i], (c_params[i] != "" ? " " c_params[i] : "")
        }
        for (d = 1; d <= dir_count; d++) print directives[d]
        print ".end"
    }
    else if (mode == "veriloga") {
        print "`include \"constants.vams\""
        print "`include \"disciplines.vams\""
        print ""

        # 1. Emit user-defined .va behavioral modules
        for (v = 1; v <= va_count; v++) {
            printf "module %s(", va_name[v]
            for (p = 1; p <= va_portcount[v]; p++) {
                printf "%s%s", va_port[v, p], (p < va_portcount[v] ? ", " : "")
            }
            print ");"
            for (p = 1; p <= va_portcount[v]; p++) {
                printf "    inout %s;\n    electrical %s;\n", va_port[v, p], va_port[v, p]
            }
            for (k = 1; k <= va_pcount[v]; k++) {
                printf "    parameter real %s = %s;\n", va_pname[v, k], va_pval[v, k]
            }
            print "    analog begin"
            for (l = 1; l <= va_lines[v]; l++) {
                print "        " va_body[v, l]
            }
            print "    end"
            print "endmodule\n"
        }

        # 2. Synthesize top-level board module
        print "module board_top();"
        print "    ground gnd;"
        for (i = 1; i <= net_count; i++) {
            n = net_list[i]
            va_n = (n == "0" ? "gnd" : "n_" n)
            if (n != "0") printf "    electrical %s;\n", va_n
        }

        # Instantiate X/Y subblocks outside analog block
        for (i = 1; i <= comp_count; i++) {
            if (c_type[i] == "X") {
                p_list = ""
                for (p = 1; p <= c_nports[i]; p++) {
                    pn = c_port[i, p]
                    vn = (pn == "0" ? "gnd" : "n_" pn)
                    p_list = (p_list == "" ? vn : p_list ", " vn)
                }
                param_ov = ""
                if (c_params[i] != "") {
                    np = split(c_params[i], pa, " ")
                    for (j = 1; j <= np; j++) {
                        split(pa[j], kv, "=")
                        param_ov = param_ov (param_ov == "" ? "" : ", ") "." kv[1] "(" si_to_real(kv[2]) ")"
                    }
                    param_ov = " #(" param_ov ")"
                }
                printf "    %s%s %s(%s);\n", c_val[i], param_ov, c_ref[i], p_list
            }
        }

        print "    analog begin"
        for (i = 1; i <= comp_count; i++) {
            t = c_type[i]
            if (t == "X") continue
            n1 = (c_port[i, 1] == "0" ? "gnd" : "n_" c_port[i, 1])
            n2 = (c_port[i, 2] == "0" ? "gnd" : "n_" c_port[i, 2])
            val = si_to_real(c_val[i])

            if (t == "R") {
                printf "        I(%s, %s) <+ V(%s, %s) / (%s); // %s\n", n1, n2, n1, n2, val, c_ref[i]
            } else if (t == "C") {
                printf "        I(%s, %s) <+ (%s) * ddt(V(%s, %s)); // %s\n", n1, n2, val, n1, n2, c_ref[i]
            } else if (t == "L") {
                printf "        V(%s, %s) <+ (%s) * ddt(I(%s, %s)); // %s\n", n1, n2, val, n1, n2, c_ref[i]
            } else if (t == "V") {
                printf "        V(%s, %s) <+ %s; // %s\n", n1, n2, val, c_ref[i]
            } else if (t == "I") {
                printf "        I(%s, %s) <+ %s; // %s\n", n1, n2, val, c_ref[i]
            } else {
                printf "        // %s (%s): instantiate via .subckt or .va\n", c_ref[i], c_val[i]
            }
        }
        print "    end"
        print "endmodule"
    }
    else if (mode == "netlist") {
        print "=== COMPONENTS ==="
        for (i = 1; i <= comp_count; i++) {
            printf "%-6s %-4s %-12s %s\n", c_ref[i], c_type[i], c_val[i], c_nets[i]
        }
        print "\n=== NETS (DEGREE : PINS) ==="
        for (i = 1; i <= net_count; i++) {
            n = net_list[i]
            printf "%-10s [%d] : %s\n", n, net_deg[n], net_pins[n]
        }
        print "\n=== BOM ==="
        for (b = 1; b <= bom_count; b++) {
            k = bom_keys[b]
            split(k, kv, "|")
            printf "%-4s %-12s qty=%-3d (%s)\n", kv[1], kv[2], bom_qty[k], bom_refs[k]
        }
    }
    else if (mode == "kicad") {
        print "(export (version \"E\")"
        print "  (components"
        for (i = 1; i <= comp_count; i++) {
            printf "    (comp (ref \"%s\") (value \"%s\"))\n", c_ref[i], c_val[i]
        }
        print "  )"
        print "  (nets"
        for (i = 1; i <= net_count; i++) {
            n = net_list[i]
            printf "    (net (code \"%d\") (name \"%s\")\n", i, n
            np = split(net_pins[n], pa, " ")
            for (j = 1; j <= np; j++) {
                split(pa[j], rp, ".")
                printf "      (node (ref \"%s\") (pin \"%s\"))\n", rp[1], rp[2]
            }
            print "    )"
        }
        print "  )"
        print ")"
    }
}
