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
