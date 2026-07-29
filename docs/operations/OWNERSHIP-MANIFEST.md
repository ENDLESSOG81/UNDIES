# Ownership Manifest

`.undies/ownership-manifest.json` records UNDIES-managed files and their ownership classes.

Supported classes:

- `CORE_IMMUTABLE`
- `CORE_LAUNCHER`
- `PROJECT_CONFIGURATION`
- `PROJECT_EXTENSION`
- `RUNTIME_STATE`
- `EVIDENCE_RECORD`
- `RECOVERY_RECORD`
- `HOST_PROJECT_UNMANAGED`

UNDIES may modify or remove only files listed in the ownership manifest and only according to class permissions. Unknown files are host-owned and must not be deleted or overwritten silently.

Validate ownership with:

```powershell
.\UNDIES.ps1 ownership -validate
```
