# Terminology

- Workspace root: the authoritative project folder where `UNDIES.ps1` is located.
- Source files: reusable UNDIES files under `src/`, `schemas/`, `templates/`, `docs/`, `tests/`, and root metadata.
- Runtime files: generated state under `.undies/`.
- Module: a governed unit of work with an objective, inputs, dependencies, actions, tests, acceptance criteria, evidence requirements, and status.
- Session: a governed execution record containing module queue state, evidence locations, warnings, failures, and final status.
- Gate: a status decision that controls continuation.
- Evidence: append-oriented audit events and related generated records.
- Recovery checkpoint: a saved state used to resume safely after interruption or stop.

## BLUE Gate Restoration

BLUE is the canonical UNDIES safe-pause gate. BLUE means execution reached a safe checkpoint and cannot continue until an exact dependency, authorization, decision, resource, credential, configuration value, external service action, or operator input is provided and validated. BLUE is not RED and is not BLOCKED: RED is a failure after execution, while BLOCKED prevents implementation from beginning.

`WAITING_FOR_EXTERNAL_DEPENDENCY` is a deprecated legacy alias. Historical records using it remain readable and normalize internally to BLUE. New records must write BLUE.
