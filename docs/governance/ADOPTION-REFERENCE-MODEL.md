# Adoption Reference Model

UNDIES adoption creates a thin reference layer inside a project.

## Files

`UNDIES.md` explains the project-local governance agreement in human
readable form.

`.undies/project.yaml` records the machine-readable project identity,
UNDIES version pin, source commit pin, gate policy, runtime path policy,
and reverse-synchronization setting.

Optional runtime directories are local to the project:

```text
.undies/reports/
.undies/sessions/
.undies/backups/
.undies/evidence/
```

## Required Configuration Fields

The project YAML must include:

- `project.name`
- `project.code`
- `undies.version`
- `undies.source_commit`
- `undies.protocol_status`
- `governance.gates`
- `runtime.untracked_paths`
- `isolation.source_dependency`
- `isolation.reverse_synchronization`

`isolation.source_dependency` must be `NONE` for ordinary adopted
projects.

`isolation.reverse_synchronization` must be `DISABLED`.

## Ownership

The adopted project owns its source files, project configuration,
runtime records, credentials, services, modules, and release decisions.

UNDIES owns only the protocol definition in the UNDIES repository.

The project may replace its UNDIES pin only through an explicit
governance update. A normal session command must not rewrite the pin,
normalize project files, or repair governance references silently.

## Migration Compatibility

Existing embedded-core adoptions remain historical records. They should
be migrated by adding the reference layer, validating equivalent
governance state, preserving previous evidence, and removing copied core
files only through a reviewed project-local migration.
