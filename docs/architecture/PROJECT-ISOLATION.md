# Project Isolation

UNDIES installations are isolated from the authoritative UNDIES repository and from other project installations.

Runtime rules:

- Host projects cannot write back to `D:\GITHUB\undies`.
- The source repository is never a runtime dependency after deployment.
- No shared writable files, symbolic links, junctions, or reverse synchronization paths are used.
- Unknown files are host-owned.
- Collisions fail closed with BLUE unless ownership and matching hashes prove the operation is safe.
- Git operations remain scoped to the host repository and are never automatic during import or adoption.

Project-specific behavior belongs in `.undies/project/` and `.undies/extensions/`, never in immutable core.
