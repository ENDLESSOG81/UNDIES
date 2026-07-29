# Changelog

## Unreleased

- Validated UND-019 controlled real-project pilot against a disposable DRIA clone.
- Corrected portable adoption so supplied project identity is persisted before session creation.
- Added UND-019 pilot coverage for preview, dry-run, adoption, BLUE resume validation, rollback, removal, and Git isolation.
- Regenerated `dist/UNDIES.ps1`.

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

