# Operating Principles

- Local-first: UNDIES must run without internet access.
- Portable: UNDIES must work in ordinary Windows folders.
- Recoverable: interruption must leave readable evidence and a safe resume point.
- Deterministic where practical: status decisions must be based on recorded checks.
- Idempotent where practical: re-running initialization must preserve existing content.
- Human-readable: documents, JSON, reports, and JSON Lines evidence must be inspectable.
- Credential-protective: secrets must not appear in logs, reports, evidence, examples, or command history.
- Sequential: only one governed module may be active at a time.
- Repository-ready: the foundation may live in a future repository but must not require one.

## BLUE Gate Restoration

BLUE is the canonical UNDIES safe-pause gate. BLUE means execution reached a safe checkpoint and cannot continue until an exact dependency, authorization, decision, resource, credential, configuration value, external service action, or operator input is provided and validated. BLUE is not RED and is not BLOCKED: RED is a failure after execution, while BLOCKED prevents implementation from beginning.

`WAITING_FOR_EXTERNAL_DEPENDENCY` is a deprecated legacy alias. Historical records using it remain readable and normalize internally to BLUE. New records must write BLUE.
