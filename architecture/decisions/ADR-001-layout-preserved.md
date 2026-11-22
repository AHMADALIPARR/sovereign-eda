# ADR-001: Existing layout is preserved

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Status: accepted.

Context: the owner ordered both boards into one monorepo and judged the
earlier fragmentation a failure. He ordered the layout not to be touched
again without his direction.

Decision: the NASA evidence layer is added beside the existing tree. No
existing file is moved, renamed, or split to fit the NASA folder
template. requirements/, architecture/, verification/, tests/,
assurance/, configuration/, operations/, and reports/ reference the
existing paths (malbolge-circuit/, board/, lean/, gpu/). The NASA
template is a discipline model, not a move order.

Consequence: traceability points at the real paths. A reviewer reads
the evidence layer to find the code, instead of finding the code
rearranged to match the template.
