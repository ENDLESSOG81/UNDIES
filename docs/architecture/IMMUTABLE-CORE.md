# Immutable Core

UNDIES uses one-way deployment. The authoritative source repository packages release artifacts; host projects install those artifacts locally and do not write back to the source repository.

Installed core files live under `.undies/core/<VERSION>/` and are treated as immutable. The root `UNDIES.ps1` becomes a launcher that reads `.undies/active-version.json` and dispatches only to the active local core. Project configuration, extensions, runtime state, evidence, reports, recovery data, and backups remain outside core.

Core integrity is enforced with SHA-256 hashes, a core manifest, ownership records, read-only attributes where supported, and fail-closed doctor/integrity checks. If a core file changes, ordinary execution must stop until repair restores the file from a validated UNDIES artifact or backup.

Upgrades install side-by-side into a new versioned core directory and atomically switch the active-version pointer. Previous core versions are preserved by default.
