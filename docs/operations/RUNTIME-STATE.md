# UNDIES Runtime State

UNDIES runtime commands must not rewrite tracked deployment or governance metadata.

Runtime-owned paths are:

- `.undies/runtime/`
- `.undies/sessions/`
- `.undies/evidence/`
- `.undies/reports/`
- `.undies/recovery/`

Ordinary session operations may create or update files only in those locations. `session-start`, `session-close`, `resume`, `status`, `doctor`, `integrity`, `ownership -validate`, and `core-status` must not rewrite:

- `UNDIES.ps1`
- `UNDIES.ps1.sha256`
- `UNDIES-RELEASE-MANIFEST.json`
- `.undies/active-version.json`
- `.undies/ownership-manifest.json`
- `.undies/core/`
- `.undies/project/`
- `.undies/extensions/`
- host project files
- Git metadata

Read-only commands validate the current installation and report problems. They do not repair, normalize, refresh timestamps, update hashes, or rewrite JSON formatting.

If deployment metadata needs correction, the operator must use an explicit operation such as `repair -preview`, `repair -apply`, `configure`, `upgrade`, `rollback`, or `remove`. Session commands must not silently perform those operations.

Runtime cleanliness must come from correct write boundaries. UNDIES must not use Git cleanup commands to hide session-generated changes.
