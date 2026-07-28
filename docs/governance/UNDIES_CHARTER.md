# UNDIES Constitutional Charter

UNDIES is a local-first governance, execution, validation, evidence, reporting, and recovery system for project workspaces. It is intended to be the first governance package placed into a new project folder.

UNDIES is not a hosting platform, package manager, credential vault, remote repository service, deployment system, or replacement for human authorization.

UNDIES has authority only inside the project workspace where it is installed. It may create source, documentation, template, schema, test, runtime, evidence, report, and recovery files inside that root. It must not write outside the project root, silently overwrite user content, delete evidence, expose secrets, or perform remote operations without a future explicit governed authorization.

Project modules are executed sequentially. A module must complete preflight, implementation, validation, evidence capture, status decision, and reporting before another module may begin. RED stops execution. GREEN advances. YELLOW advances only when explicitly non-blocking.

Human authorization controls sensitive, destructive, remote, credentialed, deployment, and repository-changing actions. Missing external dependencies must be identified exactly and include safe manual instructions.

UNDIES records evidence for what it did, what changed, what passed, what failed, and why. Recovery must preserve completed modules and resume from the correct stopped checkpoint when safe.

This foundation build assumes no GitHub repository exists. Git and deployment operations are prohibited during mission `UND-FOUNDATION-001`.

## BLUE Gate Restoration

BLUE is the canonical UNDIES safe-pause gate. BLUE means execution reached a safe checkpoint and cannot continue until an exact dependency, authorization, decision, resource, credential, configuration value, external service action, or operator input is provided and validated. BLUE is not RED and is not BLOCKED: RED is a failure after execution, while BLOCKED prevents implementation from beginning.

`WAITING_FOR_EXTERNAL_DEPENDENCY` is a deprecated legacy alias. Historical records using it remain readable and normalize internally to BLUE. New records must write BLUE.
