# UNDIES v0.3.0-alpha.2 Release Notes

UNDIES v0.3.0-alpha.2 is an alpha prerelease.

## Purpose

This release publishes the UND-024 runtime metadata isolation correction.

Before this correction, `session-start` invoked the immutable-core installation path and re-touched three tracked deployment metadata files:

- `.undies/active-version.json`
- `.undies/core/0.3.0-alpha.1/CORE-MANIFEST.json`
- `.undies/ownership-manifest.json`

The corrected behavior validates the existing installation without reinstalling core metadata. Ordinary runtime and read-only commands do not rewrite tracked deployment, ownership, core, project-governance, launcher, checksum, release-manifest, host-project, or Git metadata.

## Runtime-Owned Paths

Runtime commands may write only under:

- `.undies/runtime/`
- `.undies/sessions/`
- `.undies/evidence/`
- `.undies/reports/`
- `.undies/recovery/`

## Validated Behavior

- `session-start` creates runtime session records and changes zero tracked files.
- `session-close` changes zero tracked files.
- `status`, `doctor`, `doctor -detailed`, `integrity`, `ownership -validate`, and `core-status` change zero tracked files.
- Immutable-core metadata remains stable.
- Project configuration remains stable during reads.
- Host Git HEAD, branch, remotes, and index remain unchanged.
- Reverse synchronization remains `DISABLED`.

## Upgrade

Copy the three release files into the project:

- `UNDIES.ps1`
- `UNDIES.ps1.sha256`
- `UNDIES-RELEASE-MANIFEST.json`

Then run:

```powershell
.\UNDIES.ps1 upgrade -check
.\UNDIES.ps1 upgrade -preview
.\UNDIES.ps1 upgrade -apply
.\UNDIES.ps1 doctor -detailed
.\UNDIES.ps1 integrity
.\UNDIES.ps1 ownership -validate
.\UNDIES.ps1 core-status
```

After validation, ordinary session operations should leave the tracked working tree clean:

```powershell
.\UNDIES.ps1 session-start
git status --short
.\UNDIES.ps1 session-close
git status --short
```

## Validation

- UND-024 module tests: 48 passed, 0 failed, 0 skipped.
- Full regression suite: 55 passed, 0 failed, 0 skipped.
- UND-025 release tests validate source metadata, release assets, runtime isolation, stale-manifest detection, and credential/runtime exclusion.

## Known Alpha Limitations

- This is not a production-stable release.
- GitHub publication and asset download verification require GitHub access.
- Project-specific tests require separate operator authorization.
- Existing active governed sessions require an operator decision before authoritative project upgrade.
