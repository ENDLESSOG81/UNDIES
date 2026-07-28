# Workspace Rules

- The repository root containing `UNDIES.ps1` is the authoritative project root for development.
- UNDIES must not write outside the project root.
- UNDIES must not silently overwrite existing user files.
- OneDrive workspaces are prohibited without explicit authorization because sync conflicts can corrupt runtime evidence.
- UNDIES must not create nested duplicate project roots such as `UNDIES/UNDIES`.
- Secrets must not be stored in reports, evidence, templates, examples, or commits.
- Evidence must not be deleted without explicit authorization.
- Runtime state belongs under `.undies/`; reusable source belongs outside `.undies/`.
- Git operations are limited to normal fetch, fast-forward pull, branch creation, commits, normal pushes, and final fast-forward integration when all gates are GREEN.
