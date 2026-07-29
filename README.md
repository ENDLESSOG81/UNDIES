# UNDIES

UNDIES is a standalone, portable project governance and execution system.

UNDIES is the first governance package placed into a project workspace. It establishes local project authority, module sequencing, validation gates, evidence capture, reporting, and recovery before any remote repository or cloud service is required.

The current alpha build is version `0.3.0-alpha.1`.

## Mission

UNDIES provides a portable, offline-capable governance and execution layer for projects. A project operator places `UNDIES.ps1` in a project folder before module construction begins, runs initialization, and then executes governed modules one at a time.

## Boundaries

UNDIES does not create GitHub repositories, add remotes, push code, deploy software, install packages, or request credentials unless a governed module explicitly receives human authorization. Portable operation requires no internet access after the release artifact is available.

## Immutable Core And Isolation

UNDIES uses one-way deployment:

```text
AUTHORITATIVE UNDIES SOURCE
        -> package and release
IMMUTABLE RELEASE ARTIFACT
        -> controlled installation
HOST PROJECT UNDIES INSTALLATION
```

Host projects do not write back to the UNDIES source repository. Installed core files live under `.undies/core/<VERSION>/`; the root `UNDIES.ps1` launcher dispatches only to the active local core recorded in `.undies/active-version.json`. Project configuration lives under `.undies/project/`, extensions under `.undies/extensions/`, and runtime state under runtime-owned directories.

Unknown files are host-owned. Filename collisions fail closed with BLUE instead of being overwritten silently.

## Quick Start

```powershell
.\UNDIES.ps1 help
.\UNDIES.ps1 doctor
.\UNDIES.ps1 initialize
.\UNDIES.ps1 import -preview
.\UNDIES.ps1 ownership -validate
.\UNDIES.ps1 core-status
.\UNDIES.ps1 validate
```

PowerShell 7 is preferred. Windows PowerShell 5.1 is supported for the foundation features that use standard cmdlets and .NET APIs.


## BLUE Gate Restoration

BLUE is the canonical UNDIES safe-pause gate. BLUE means execution reached a safe checkpoint and cannot continue until an exact dependency, authorization, decision, resource, credential, configuration value, external service action, or operator input is provided and validated. BLUE is not RED and is not BLOCKED: RED is a failure after execution, while BLOCKED prevents implementation from beginning.

`WAITING_FOR_EXTERNAL_DEPENDENCY` is a deprecated legacy alias. Historical records using it remain readable and normalize internally to BLUE. New records must write BLUE.
