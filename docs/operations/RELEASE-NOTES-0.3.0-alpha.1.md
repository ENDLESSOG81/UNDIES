# UNDIES v0.3.0-alpha.1 Release Notes

UNDIES v0.3.0-alpha.1 is an alpha prerelease.

This release introduces the immutable-core and project-isolation architecture from UND-022. A host project receives UNDIES as a one-way deployment from validated release artifacts. The host project does not gain a writable relationship back to the UNDIES development repository.

## Highlights

- Immutable versioned core under `.undies/core/0.3.0-alpha.1/`
- Thin root launcher dispatching through `.undies/active-version.json`
- Ownership manifest for UNDIES-managed files
- Fail-closed BLUE behavior for unknown collisions
- Project configuration under `.undies/project/`
- Project extensions under `.undies/extensions/`
- Runtime state outside immutable core
- Side-by-side upgrade behavior
- Atomic active-version switching
- Rollback through active-version pointer
- Host Git protection: no automatic stage, commit, push, branch, remote, submodule, or subtree changes
- Reverse synchronization: `DISABLED`

## Installation

Copy these three release assets into a host project:

```powershell
UNDIES.ps1
UNDIES.ps1.sha256
RELEASE-MANIFEST.json
```

Rename `RELEASE-MANIFEST.json` to `UNDIES-RELEASE-MANIFEST.json` when placing it beside `UNDIES.ps1`.

Verify checksum:

```powershell
$Hash = (Get-FileHash .\UNDIES.ps1 -Algorithm SHA256).Hash
$Expected = (Get-Content .\UNDIES.ps1.sha256 -Raw).Trim()
if ($Hash -ne $Expected) { throw "UNDIES.ps1 checksum mismatch" }
```

Initialize an empty project:

```powershell
.\UNDIES.ps1 initialize
.\UNDIES.ps1 doctor -detailed
.\UNDIES.ps1 integrity
.\UNDIES.ps1 ownership -validate
.\UNDIES.ps1 core-status
```

Import into an existing project:

```powershell
.\UNDIES.ps1 import -preview
.\UNDIES.ps1 import -dry-run
.\UNDIES.ps1 import
git status --short
```

## Validation

- UND-022 module tests: passed=36 failed=0 skipped=0
- UND-023 module tests: required before publication
- Full regression suite: required before publication

## Known Limitations

- Alpha prerelease, not production/stable.
- Project-specific tests require operator authorization.
- GitHub release publication requires authenticated release tooling.
- Extensions are isolated but remain an alpha capability.
