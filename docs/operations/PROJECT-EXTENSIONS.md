# Project Extensions

Project extensions live under `.undies/extensions/`.

Extensions must remain outside immutable core, declare supported UNDIES versions, declare permissions, and be disabled by default unless authorized. Extensions must not replace core functions silently, modify the UNDIES source repository, or write outside the host project.

Removing an extension must not alter immutable core.
