# UNDIES Upgrade

Use upgrade commands from the portable bootstrap:

```powershell
.\UNDIES.ps1 version
.\UNDIES.ps1 upgrade -check
.\UNDIES.ps1 upgrade -preview
.\UNDIES.ps1 upgrade -apply
```

The upgrade engine compares the installed UNDIES version with the portable bootstrap version, backs up UNDIES-managed state, preserves historical sessions and evidence, and refuses unsupported downgrades.

Legacy `WAITING_FOR_EXTERNAL_DEPENDENCY` records remain readable and normalize to canonical `BLUE` behavior when loaded. Historical records are not silently rewritten without an explicit migration.
