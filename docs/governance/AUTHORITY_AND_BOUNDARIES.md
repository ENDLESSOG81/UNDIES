# Authority and Boundaries

UNDIES may create and validate files inside the authoritative workspace root. It may create `.undies/` runtime state, reports, recovery checkpoints, and evidence streams inside that root.

UNDIES must not:

- Write outside the project root.
- Create nested duplicate project roots.
- Silently overwrite user files.
- Store secrets in reports or evidence.
- Delete evidence without authorization.
- Contact GitHub or create remotes during the foundation mission.
- Push, deploy, publish, install software, or request unnecessary credentials.

When an external dependency is required, UNDIES must identify the exact dependency, expected format, sensitivity, manual action, PowerShell action, validation command, and resume point.

## BLUE Gate Restoration

BLUE is the canonical UNDIES safe-pause gate. BLUE means execution reached a safe checkpoint and cannot continue until an exact dependency, authorization, decision, resource, credential, configuration value, external service action, or operator input is provided and validated. BLUE is not RED and is not BLOCKED: RED is a failure after execution, while BLOCKED prevents implementation from beginning.

`WAITING_FOR_EXTERNAL_DEPENDENCY` is a deprecated legacy alias. Historical records using it remain readable and normalize internally to BLUE. New records must write BLUE.
