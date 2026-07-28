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
