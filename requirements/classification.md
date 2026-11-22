# Classification

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## What this repository is

Sovereign EDA is a research and engineering-tool repository. It holds two
projects in one tree: a Malbolge ternary machine (reference interpreter,
hardware ALU, formal semantics, GPU kernels) and a plain-text board EDA
compiler with a dual-circuit controller and an SRAM write-cell.

## What it is not

This repository is not flight software. It does not fly, guide, or command
a spacecraft. It is not safety-critical software, it is not human-rated,
and no claim in this repository certifies it for a NASA mission, a flight
role, or a safety-critical role. No NASA certification has been granted,
and none is claimed.

## Classification applied here

Class: non-flight research / engineering tool, non-safety-critical.

Basis: the software runs on a workstation, interprets and synthesizes
designs, and produces no command that reaches flight hardware. A defect
here produces a wrong simulation, a wrong netlist, or a failed build. It
does not produce a hazardous spacecraft state.

## Consequence for the standards

NPR 7150.2D, NASA-STD-8739.8B, NASA-HDBK-2203, NPR 7123.1, and NPR 7120.5
are used here as the engineering model: requirements, traceability,
verification, safety analysis, configuration control, and release gates.
The flight-specific obligations in those documents (independent
verification and validation of flight software, human-rating evidence,
flight acceptance) do not apply to this class and are recorded as
not applicable in requirements/compliance-matrix.csv, not as passed.

If the classification changes (for example, if any part of this tree is
proposed for a flight or safety-critical role), the classification,
the compliance matrix, and the release gates change with it, and the
release gate fails until they do.

## Governing documents

- NPR 7150.2D, NASA Software Engineering Requirements
- NASA-STD-8739.8B, Software Assurance, Software Safety, and Independent
  Verification and Validation
- NASA-HDBK-2203, Software Engineering Handbook
- NPR 7123.1, NASA Systems Engineering Processes and Requirements
- NPR 7120.5, Space Flight Program and Project Management
- Project requirements in requirements/system/, requirements/software/,
  requirements/interfaces/, and requirements/safety/
