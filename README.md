# UNDIES

UNDIES is a standalone, portable project governance and execution system.

UNDIES is the first governance package placed into a project workspace. It establishes local project authority, module sequencing, validation gates, evidence capture, reporting, and recovery before any remote repository or cloud service is required.

This foundation build is version `0.1.0-alpha.1`.

## Mission

UNDIES provides a portable, offline-capable governance and execution layer for projects. A project operator places `UNDIES.ps1` in a project folder before module construction begins, runs initialization, and then executes governed modules one at a time.

## Boundaries

UNDIES does not create GitHub repositories, add remotes, push code, deploy software, install packages, or request credentials unless a future governed module explicitly receives human authorization. This foundation build performs no GitHub operations and requires no internet access.

## Quick Start

```powershell
.\UNDIES.ps1 help
.\UNDIES.ps1 doctor
.\UNDIES.ps1 initialize
.\UNDIES.ps1 validate
```

PowerShell 7 is preferred. Windows PowerShell 5.1 is supported for the foundation features that use standard cmdlets and .NET APIs.

