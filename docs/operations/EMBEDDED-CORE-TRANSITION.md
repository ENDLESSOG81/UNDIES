# Embedded Core Transition

Earlier alpha releases used a copied immutable-core installation model.
That model is now deprecated for new project adoption.

The sterile model replaces copied core files with a tracked project
reference layer:

```text
UNDIES.md
.undies/project.yaml
```

## What Remains Supported

Historical records from embedded-core alpha releases remain readable.
Release artifacts, reports, and tests that document the old model may
stay in history for audit and migration purposes.

The old tooling must not be treated as the default adoption path for new
projects unless an explicit compatibility operation authorizes it.

## What New Projects Should Do

New projects should:

1. Add the neutral `UNDIES.md` reference.
2. Add `.undies/project.yaml`.
3. Pin the approved UNDIES version and source commit.
4. Ignore local runtime folders.
5. Run the applicable validation checks.
6. Commit only the reference layer and approved governance docs.

New projects should not copy UNDIES source code, build scripts, tests,
release manifests, or immutable-core implementation files.

## Why The Model Changed

The sterile model prevents project-specific state from contaminating the
UNDIES source repository and prevents UNDIES implementation files from
becoming project-owned. It also makes adoption reviewable: the entire
project-facing governance contract is visible in two neutral files.
