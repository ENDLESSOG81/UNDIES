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
