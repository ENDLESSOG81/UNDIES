# Migrating Embedded Adoptions

This procedure migrates a project that already contains embedded UNDIES
core files to the sterile reference model.

## Safety Rules

- Preserve project history.
- Preserve UNDIES historical records.
- Do not delete runtime evidence silently.
- Do not rewrite project history.
- Do not modify project source files except the authorized governance
  references.
- Do not run cleanup commands to hide tracked changes.

## Procedure

1. Record the project branch, commit, remote, and working-tree status.
2. Confirm there is no active governed session that requires operator
   decision.
3. Record the currently installed UNDIES version and source commit.
4. Add or update `UNDIES.md` from the sterile template.
5. Add or update `.undies/project.yaml` from the sterile template.
6. Mark reverse synchronization as `DISABLED`.
7. Mark source dependency as `NONE`.
8. Preserve old embedded-core files in history.
9. Remove old copied core files only in a reviewed migration commit.
10. Keep runtime folders untracked according to project policy.
11. Run validation and commit the migration.

If a collision, active session, unsupported version, or unclear
ownership record is found, pause BLUE with the exact required operator
decision and validation command.

## Validation

The migrated project is acceptable when:

- the project reference layer parses
- gates remain available
- runtime paths are untracked
- source dependency is `NONE`
- reverse synchronization is `DISABLED`
- project source files are unchanged
- previous evidence remains readable
