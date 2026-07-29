# UNDIES Adoption

Use adoption for an existing project folder:

```powershell
.\UNDIES.ps1 adopt -preview -project-name "Project Name" -project-code CODE
.\UNDIES.ps1 adopt -dry-run -project-name "Project Name" -project-code CODE
.\UNDIES.ps1 adopt -confirm -project-name "Project Name" -project-code CODE
```

Preview and dry-run must make no changes. Confirmed adoption creates UNDIES-managed runtime and governance records only. It must not modify application source files or perform Git add, commit, push, pull, merge, reset, checkout, restore, clean, stash, or branch operations.

Git tracking of UNDIES-generated files requires separate explicit authorization.
