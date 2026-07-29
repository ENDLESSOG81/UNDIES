# Import

`.\UNDIES.ps1 import` installs a validated UNDIES release artifact into the current host project.

Direction is fixed:

- Source: validated UNDIES release artifact.
- Destination: current host project.
- Reverse synchronization: disabled.

Import must not copy host files into the UNDIES source repository, add the UNDIES repository as a remote, stage files, commit files, push files, change branches, create submodules, or write outside the host project root.

Use preview first:

```powershell
.\UNDIES.ps1 import -preview
.\UNDIES.ps1 import -dry-run
.\UNDIES.ps1 import
```

Any unknown file collision at an UNDIES-managed path pauses BLUE.
