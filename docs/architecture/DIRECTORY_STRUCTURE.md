# Directory Structure

UNDIES source files are separated from runtime-generated state.

- `UNDIES.ps1`: development repository entry point.
- `build/`: packaging scripts for producing portable artifacts.
- `dist/`: generated portable distribution artifacts, including `dist/UNDIES.ps1`.
- `config/`: default source configuration.
- `docs/`: architecture, governance, operations, and specification documents.
- `schemas/`: JSON contracts validated by native PowerShell.
- `src/`: modular PowerShell engines.
- `templates/`: reusable project, module, and report templates.
- `tests/`: native PowerShell foundation tests and controlled fixtures.
- `examples/`: controlled examples and demos.
- `.undies/`: local generated runtime state, sessions, evidence, reports, and recovery checkpoints.

Runtime state is ignored by Git. Source files, schemas, templates, tests, examples, and packaging scripts are repository content.

## BLUE Gate Restoration

BLUE is the canonical UNDIES safe-pause gate. BLUE means execution reached a safe checkpoint and cannot continue until an exact dependency, authorization, decision, resource, credential, configuration value, external service action, or operator input is provided and validated. BLUE is not RED and is not BLOCKED: RED is a failure after execution, while BLOCKED prevents implementation from beginning.

`WAITING_FOR_EXTERNAL_DEPENDENCY` is a deprecated legacy alias. Historical records using it remain readable and normalize internally to BLUE. New records must write BLUE.
