# Sterile Governance

UNDIES is a governance protocol, not a project template and not a
project payload.

The UNDIES repository is the only authoritative home for UNDIES core
definitions, tests, build logic, compatibility notes, and release
history. A governed project receives a neutral reference layer that
declares which UNDIES version and source commit it follows.

## Required Project Files

A newly adopted project uses this minimal tracked structure:

```text
UNDIES.md
.undies/project.yaml
```

Runtime records may be created by governed work, but they are local
project runtime data:

```text
.undies/reports/
.undies/sessions/
.undies/backups/
.undies/evidence/
```

These runtime paths are not UNDIES source files and must not be copied
back into the UNDIES repository as protocol changes.

## Sterility Rules

Normative UNDIES adoption material must be project-neutral.

It must not contain:

- project-specific names
- local operator workspace paths
- credentials or environment values
- provider-specific deployment assumptions
- imported archive names
- repository names other than UNDIES itself
- instructions to synchronize project files back into UNDIES

Project-specific records belong in the governed project. Historical
UNDIES evidence may mention real projects when preserving prior work,
but those records are not templates for new adoption.

## Core Location

The current sterile model keeps the core in this repository. Adopted
projects pin:

- UNDIES version
- UNDIES source commit
- protocol status
- runtime policy

They do not receive copied core implementation files.

## Gate Behavior

All adoption uncertainty fails closed:

- missing required identity pauses BLUE
- conflicting local files pause BLUE
- malformed project configuration is BLOCKED before implementation
- unsafe runtime behavior is RED
- unknown status values fail closed

BLUE is a safe pause, not a failure. It must state the exact required
item, manual action, validation command, success condition, and resume
checkpoint.
