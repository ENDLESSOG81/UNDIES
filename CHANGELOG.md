# Changelog

## Unreleased

- Added the sterile governance adoption model for neutral project references.
- Defined `UNDIES.md` and `.undies/project.yaml` as the current project-facing adoption layer.
- Documented transition away from copied embedded-core adoption for new projects.
- Added migration guidance for historical embedded-core adoptions.
- Added sterility coverage to prevent project-specific contamination in normative adoption files.

## 0.3.0-alpha.2

- Fixed runtime session metadata isolation for immutable-core installations.
- Changed ordinary session and BLUE report operations to validate existing core state instead of reinstalling or refreshing deployment metadata.
- Ensured `session-start` and `session-close` write only runtime-owned session records after installation.
- Added no-op JSON write protection to avoid disk writes when managed metadata bytes are unchanged.
- Documented runtime-state boundaries and the requirement that read-only commands never repair or rewrite metadata silently.
- Added UND-024 regression coverage for tracked-file stability, host Git safety, and DIRA-style adoption fixtures.

## 0.3.0-alpha.1

- Added UND-022 immutable core and project isolation architecture.
- Added one-way import semantics from validated release artifact to host project only.
- Added versioned `.undies/core/<VERSION>/` installation with active-version dispatch.
- Added ownership manifest generation and validation.
- Added collision fail-closed BLUE behavior for unknown or modified managed files.
- Added side-by-side core upgrade behavior and active-version rollback protection.
- Added project extension and runtime separation from immutable core.
- Added path containment and host Git safety validation tests.
## 0.2.0-alpha.2

- Added UND-021 release integrity recovery.
- Preserved `.gitattributes` line-ending protection for release artifacts.
- Regenerated `dist/UNDIES.ps1`, checksum, and release manifest together.
- Added fresh-checkout and release-download checksum verification coverage.
- Supersedes `0.2.0-alpha.1` because its public release material carried the original checksum integrity issue.
## 0.2.0-alpha.1

- Added clean-folder portable deployment validation.
- Added existing non-Git project adoption with preview and dry-run.
- Added Git-aware adoption safeguards for repositories with history and uncommitted work.
- Added guided project configuration commands.
- Added upgrade and compatibility checks, including legacy BLUE alias handling.
- Added doctor, repair, and integrity verification behavior.
- Added rollback, disable, and safe removal behavior.
- Validated a controlled real-project pilot against a disposable DRIA clone.
- Corrected portable adoption so supplied project identity is persisted before session creation.
- Added release packaging with `dist/UNDIES.ps1`, SHA-256 checksum, release manifest, and alpha operation documentation.
- Known alpha limitation: GitHub prerelease publication may require authenticated external tooling.
## 0.1.0-alpha.1

- Established UNDIES constitutional foundation.
- Added portable workspace scaffold.
- Added JSON configuration and contract templates.
- Added session, module queue, gate, dependency, evidence, reporting, and recovery engines.
- Added local `UNDIES.ps1` bootstrap and native PowerShell test runner.
## 0.1.0-alpha.2

- Restored BLUE as the canonical safe-pause gate for exact external input, authorization, decisions, resources, credentials, configuration, or operator action.
- Preserved `WAITING_FOR_EXTERNAL_DEPENDENCY` as a deprecated legacy alias that normalizes to BLUE when loaded.
- Added BLUE reporting totals and source/canonical status display for historical records.
- Added BLUE resume behavior requiring dependency validation before continuation.
- Added BLUE gate, dependency, reporting, queue, and portable artifact tests.
- Regenerated `dist/UNDIES.ps1`.




