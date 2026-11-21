# autocomplete.sh Dispatcher — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fill in the empty `# Run` section of `autocomplete.sh` so it sources the correct shell-specific script (`autocomplete_bash.sh` or `autocomplete_zsh.sh`) from the same directory.

**Architecture:** `autocomplete.sh` is installed as `autocomplete` in `~/.local/bin/` alongside `autocomplete_bash.sh` and `autocomplete_zsh.sh`. The `# Run` section resolves the dispatcher's own directory via `command -v autocomplete` (reliable when sourced) with a `$0` fallback (for direct execution), then sources the shell-specific sibling, forwarding all arguments.

**Tech Stack:** POSIX sh, bats (test framework)

## Global Constraints

- Must be valid POSIX sh — no bash-isms or zsh-isms (shebang is `#!/usr/bin/sh`)
- Do not modify any other part of `autocomplete.sh`
- `autocomplete_bash.sh` and `autocomplete_zsh.sh` are always in the same directory as `autocomplete`
- Temporary variables must be `unset` after use to avoid polluting the caller's environment

---

### Task 1: Implement and test the dispatcher `# Run` section

**Files:**
- Modify: `autocomplete.sh` (after the `# Run` comment, line 36)

**Interfaces:**
- Consumes: `SCRIPT_NAME` (already set above in the file to `autocomplete_bash.sh` or `autocomplete_zsh.sh`)
- Produces: Sources the shell-specific script with all CLI arguments forwarded via `"$@"`

- [ ] **Step 1: Write a minimal bats smoke test**

Create `tests/test_dispatcher.bats`:

```bash
#!/usr/bin/env bats

# These tests run against the local dev copies, not the installed version.
# They require autocomplete_bash.sh and autocomplete_zsh.sh to exist alongside autocomplete.sh.

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    # Symlink autocomplete.sh as 'autocomplete' in a temp bin dir on PATH
    export _ACSH_TEST_BIN="$(mktemp -d)"
    ln -sf "$SCRIPT_DIR/autocomplete.sh" "$_ACSH_TEST_BIN/autocomplete"
    ln -sf "$SCRIPT_DIR/autocomplete_bash.sh" "$_ACSH_TEST_BIN/autocomplete_bash.sh"
    ln -sf "$SCRIPT_DIR/autocomplete_zsh.sh" "$_ACSH_TEST_BIN/autocomplete_zsh.sh"
    export PATH="$_ACSH_TEST_BIN:$PATH"
}

teardown() {
    rm -rf "$_ACSH_TEST_BIN"
}

@test "autocomplete (dispatcher) prints version string when called with no args" {
    run bash -c 'source autocomplete'
    [ "$status" -eq 0 ]
    [[ "$output" =~ [Aa]utocomplete ]]
}

@test "autocomplete dispatcher exits 1 when sibling script is missing" {
    rm "$_ACSH_TEST_BIN/autocomplete_bash.sh"
    run bash -c 'source autocomplete'
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Could not find" ]]
}
```

- [ ] **Step 2: Run the tests to confirm they fail (# Run is empty)**

```bash
bats tests/test_dispatcher.bats
```

Expected: both tests FAIL — first because `source autocomplete` does nothing (no output), second because there's no error yet.

- [ ] **Step 3: Implement the `# Run` section in `autocomplete.sh`**

Replace the trailing blank lines after `# Run` (line 36 onward) with:

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

The full file should look like:

```sh
#!/usr/bin/sh

# Detect the current shell
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        # Check the parent process's shell
        parent_shell=$(ps -p $PPID -o comm=)
        case "$parent_shell" in
            *zsh*) echo "zsh" ;;
            *bash*) echo "bash" ;;
            *) echo "unknown" ;;
        esac
    fi
}

SHELL_TYPE=$(detect_shell)
case "$SHELL_TYPE" in
    zsh)
        SCRIPT_NAME="autocomplete_zsh.sh"
        ;;
    bash)
        SCRIPT_NAME="autocomplete_bash.sh"
        ;;
    *)
        echo "ERROR: Unsupported shell. Currently only bash and zsh are supported."
        exit 1
        ;;
esac

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

- [ ] **Step 4: Run the tests to confirm they pass**

```bash
bats tests/test_dispatcher.bats
```

Expected:
```
 ✓ autocomplete (dispatcher) prints version string when called with no args
 ✓ autocomplete dispatcher exits 1 when sibling script is missing

2 tests, 0 failures
```

- [ ] **Step 5: Commit**

```bash
git add autocomplete.sh tests/test_dispatcher.bats
git commit -m "feat(autocomplete.sh): complete dispatcher run section"
```
