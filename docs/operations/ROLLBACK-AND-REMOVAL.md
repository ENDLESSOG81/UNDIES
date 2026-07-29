# UNDIES Rollback And Removal

UNDIES alpha distinguishes disable, rollback, and removal.

Disable:

```powershell
.\UNDIES.ps1 disable
```

Rollback:

```powershell
.\UNDIES.ps1 rollback -preview
.\UNDIES.ps1 rollback -apply
```

Removal:

```powershell
.\UNDIES.ps1 remove -preview
.\UNDIES.ps1 remove -apply
```

Removal deletes only UNDIES-managed deployment files selected by policy. It preserves host project files, Git metadata, reports, evidence, and the portable script unless explicit removal of those preserved items is separately authorized.
