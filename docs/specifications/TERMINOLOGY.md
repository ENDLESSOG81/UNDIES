# Terminology

- Workspace root: the authoritative project folder where `UNDIES.ps1` is located.
- Source files: reusable UNDIES files under `src/`, `schemas/`, `templates/`, `docs/`, `tests/`, and root metadata.
- Runtime files: generated state under `.undies/`.
- Module: a governed unit of work with an objective, inputs, dependencies, actions, tests, acceptance criteria, evidence requirements, and status.
- Session: a governed execution record containing module queue state, evidence locations, warnings, failures, and final status.
- Gate: a status decision that controls continuation.
- Evidence: append-oriented audit events and related generated records.
- Recovery checkpoint: a saved state used to resume safely after interruption or stop.
