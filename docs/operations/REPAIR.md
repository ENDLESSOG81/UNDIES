# UNDIES Repair

Use doctor and integrity checks before repair:

```powershell
.\UNDIES.ps1 doctor -detailed
.\UNDIES.ps1 integrity
.\UNDIES.ps1 repair -preview
.\UNDIES.ps1 repair -apply
```

Repair is limited to UNDIES-managed files and directories. It must not modify application source, delete unknown files, alter Git history, or require network access.

Repair operations back up managed configuration where practical, validate the repaired state, and write a repair report under UNDIES-managed reports.

Immutable core repair may use only checksum-verified UNDIES artifacts, checksum-verified release packages, or validated local UNDIES backups. Host project source files, extensions, runtime evidence, unverified project installations, and shared writable development repository paths are not valid core repair sources.
