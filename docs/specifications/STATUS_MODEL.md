# Status Model

`NOT_STARTED`: the item is defined but has not begun.

`PREFLIGHT`: pre-execution checks are running.

`IN_PROGRESS`: implementation is active.

`VALIDATING`: validation checks are active.

`GREEN`: all mandatory acceptance criteria passed. Record completion and advance automatically when authorized.

`YELLOW`: the module completed with a warning, limitation, deferred non-critical action, or degraded but usable result. YELLOW requires `blocks_next_module` true or false. It is not a failure.

`BLUE`: the module or session reached a safe pause because progress requires an exact input, authorization, decision, resource, credential, configuration value, external service action, or dependency that UNDIES cannot independently provide. BLUE requires full dependency details, preserves completed and pending work, keeps the paused module active, blocks later modules, and resumes only after validation succeeds. BLUE is not a failure.

`RED`: the module failed, violated a safety boundary, produced invalid results, or cannot safely continue. RED stops immediately and preserves evidence.

`BLOCKED`: execution cannot begin because foundational preflight requirements are missing, invalid, unsafe, or contradictory. BLUE and BLOCKED are not interchangeable.

`STOPPED`: the queue has stopped because a status decision prevented continuation.

`COMPLETE`: the governed item is closed and must not be silently reopened as active.

`WAITING_FOR_EXTERNAL_DEPENDENCY`: deprecated legacy alias for BLUE. Existing records remain readable and normalize internally to BLUE; new records must write BLUE.
