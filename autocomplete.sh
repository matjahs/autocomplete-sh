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
        return 1
        ;;
esac

# Run
_ACSH_SELF=$(command -v autocomplete 2>/dev/null)
_ACSH_DIR=$(cd "$(dirname "${_ACSH_SELF:-$0}")" && pwd)
if [ -f "$_ACSH_DIR/$SCRIPT_NAME" ]; then
    # shellcheck source=/dev/null
    . "$_ACSH_DIR/$SCRIPT_NAME"
else
    echo "ERROR: Could not find $SCRIPT_NAME. Please reinstall autocomplete.sh."
    return 1
fi
unset _ACSH_SELF _ACSH_DIR SHELL_TYPE SCRIPT_NAME
unset -f detect_shell

