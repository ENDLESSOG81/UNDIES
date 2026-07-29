# UNDIES Installation

UNDIES alpha deployment is portable. Copy `dist/UNDIES.ps1` into the target project folder and run:

```powershell
.\UNDIES.ps1 initialize
.\UNDIES.ps1 doctor
```

The portable bootstrap creates UNDIES governance and runtime folders inside the host project. It does not require Git, internet access, credentials, package managers, or repository source files.

Do not install directly into an authoritative project until preview, dry-run, backup, and rollback expectations are clear.
