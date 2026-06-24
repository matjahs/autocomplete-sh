# autocomplete.sh dispatcher — design

## Problem

`autocomplete.sh` is a POSIX sh wrapper installed as `autocomplete` in `~/.local/bin/`. It detects the running shell and sets `SCRIPT_NAME` to `autocomplete_bash.sh` or `autocomplete_zsh.sh`, but the `# Run` section that should source the sibling script is empty.

## Solution

Complete the `# Run` section using the following logic (Option C — defensive PATH + $0 fallback):

1. Resolve the dispatcher's own path via `command -v autocomplete` (reliable when the script is sourced, since `$0` is unreliable in bash when sourced via `source autocomplete enable`).
2. Fall back to `$0` when `command -v` returns nothing (direct execution edge case).
3. Derive the directory with `cd … && pwd` to canonicalize it.
4. Source the shell-specific sibling script, forwarding `"$@"` so CLI subcommands (`enable`, `install`, `model`, etc.) reach the implementation.
5. `unset` the two temporary variables to avoid leaking them into the caller's environment.
6. Exit with an actionable error if the sibling script is not found.

## Constraints

- Both `autocomplete_bash.sh` and `autocomplete_zsh.sh` are always installed alongside `autocomplete` in the same directory (`~/.local/bin/`).
- The script must remain POSIX sh — no bash-isms or zsh-isms.
- No other part of the file changes.

## Implementation

```sh
# Run
_ACSH_SELF=$(command -v autocomplete 2>/dev/null)
_ACSH_DIR=$(cd "$(dirname "${_ACSH_SELF:-$0}")" && pwd)
if [ -f "$_ACSH_DIR/$SCRIPT_NAME" ]; then
    . "$_ACSH_DIR/$SCRIPT_NAME" "$@"
else
    echo "ERROR: Could not find $SCRIPT_NAME. Please reinstall autocomplete.sh."
    exit 1
fi
unset _ACSH_SELF _ACSH_DIR
```
