# UNDIES Alpha Limitations

Version `0.2.0-alpha.2` is a prerelease portable alpha.

Known limitations:

- Release publication may require authenticated GitHub CLI or manual GitHub web actions.
- Project-specific tests are never run unless the operator explicitly authorizes them.
- The portable bootstrap provides local governance, adoption, upgrade, repair, rollback, removal, BLUE pause/resume, and reporting behavior; production hardening remains future work.
- Historical records using `WAITING_FOR_EXTERNAL_DEPENDENCY` are supported as a deprecated alias for `BLUE`.
- Windows PowerShell 5.1 compatibility depends on standard .NET behavior available on the host.

