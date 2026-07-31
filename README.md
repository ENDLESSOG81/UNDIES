# UNDIES

UNDIES is a sterile, reusable governance standard for project work.

The authoritative UNDIES repository defines the protocol, gate model,
session rules, evidence expectations, validation policy, and adoption
templates. Adopted projects do not receive a copied UNDIES core. They
receive a neutral reference layer that points back to an approved UNDIES
version and source commit.

Current repository version: `0.3.0-alpha.2`.

## Sterile Adoption Model

A governed project should contain only the project-local reference files
needed to declare that it follows UNDIES. The required machine-readable
project file is `.undies/project.yaml`.

```text
<PROJECT>/
├── UNDIES.md
└── .undies/
    └── project.yaml
```

The following runtime folders may exist locally and should normally
remain untracked:

```text
.undies/reports/
.undies/sessions/
.undies/backups/
.undies/evidence/
```

The UNDIES core, tests, build scripts, and release machinery remain in
this source repository. A project pins the protocol by version and
source commit; it does not become a writable copy of UNDIES.

## Authority Boundary

UNDIES defines governance. A project keeps ownership of its own source,
architecture, runtime, credentials, services, and release decisions.

UNDIES must not:

- overwrite project files silently
- copy project runtime records back into this repository
- require the UNDIES development workspace for normal project operation
- add reverse synchronization
- install project-specific systems by default
- expose secrets in reports or evidence

Unknown project files are project-owned. Collisions, missing authority,
or required operator choices pause with BLUE rather than being resolved
destructively.

## Gate Model

UNDIES uses five canonical gates:

- `GREEN`: mandatory acceptance criteria passed.
- `YELLOW`: completed with a warning or limitation.
- `BLUE`: safe pause for exact external input, authorization, resource,
  credential, configuration value, service action, or operator decision.
- `RED`: failure or unsafe continuation.
- `BLOCKED`: foundational preflight prevents work from beginning.

`WAITING_FOR_EXTERNAL_DEPENDENCY` remains a deprecated historical alias
for `BLUE`. New records should use `BLUE`.

## Normative Documents

- [Sterile Governance](docs/governance/STERILE-GOVERNANCE.md)
- [Adoption Reference Model](docs/governance/ADOPTION-REFERENCE-MODEL.md)
- [Embedded Core Transition](docs/operations/EMBEDDED-CORE-TRANSITION.md)
- [Migrating Embedded Adoptions](docs/operations/MIGRATING-EMBEDDED-ADOPTIONS.md)
- [Validation Policy](docs/operations/VALIDATION-POLICY.md)

## Adoption Templates

- [Project UNDIES.md Template](templates/adoption/UNDIES.md)
- [Project YAML Template](templates/adoption/project.yaml)
- [Project YAML Schema](schemas/adoption-project.schema.json)

Historical release notes, reports, and compatibility documents may
mention earlier project pilots or older embedded-core behavior. Those
records are evidence, not the current normative adoption model.

## Validation

Run the current repository tests from PowerShell:

```powershell
.\tests\foundation\UND-SG-sterility.Tests.ps1
.\tests\run-tests.ps1 -Quiet
```

The sterility test verifies that the normative adoption layer does not
contain project-specific names, local machine paths, provider bindings,
or instructions that would couple adopted projects back to this source
repository.
