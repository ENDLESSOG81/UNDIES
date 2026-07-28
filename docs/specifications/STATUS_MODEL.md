# Status Model

`NOT_STARTED`: the item is defined but has not begun.

`PREFLIGHT`: pre-execution checks are running.

`IN_PROGRESS`: implementation is active.

`VALIDATING`: validation checks are active.

`GREEN`: all mandatory acceptance criteria passed, no blocking defect exists, and the queue may advance automatically.

`YELLOW`: the module completed with a warning, limitation, manual production action, or non-blocking dependency. It may advance only when `blocks_next_module` is false and the reason is recorded.

`RED`: the module failed, violated a boundary, lacks required evidence, or cannot safely continue. RED always stops execution.

`BLOCKED`: the module cannot begin because a required foundational input is unavailable or invalid.

`WAITING_FOR_EXTERNAL_DEPENDENCY`: execution is waiting for an exact identified external dependency with manual action and validation instructions.

`STOPPED`: the queue has stopped because a status decision prevented continuation.

`COMPLETE`: the governed item is closed and must not be silently reopened as active.
