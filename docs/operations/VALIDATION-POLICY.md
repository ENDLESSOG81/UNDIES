# Validation Policy

UNDIES validation separates protocol health from project runtime state.

## Repository Validation

The UNDIES repository validates:

- gate definitions
- dependency and BLUE behavior
- evidence redaction
- session and report contracts
- sterile adoption templates
- migration documentation
- absence of project-specific content in normative adoption files

## Project Validation

An adopted project validates:

- `UNDIES.md` exists
- `.undies/project.yaml` exists
- project identity is explicit
- UNDIES version and source commit are pinned
- source dependency is `NONE`
- reverse synchronization is `DISABLED`
- runtime paths are untracked by policy
- no credentials are exposed
- any BLUE condition has exact resume guidance

## Read-Only Rule

Read-only validation must not rewrite project metadata. If a managed
reference file needs correction, validation reports the issue and directs
the operator to an explicit configure, repair, or migration operation.

## Fail-Closed Rule

Malformed records, unsupported status values, unknown protocol versions,
missing pins, and ambiguous ownership must not be treated as GREEN.
