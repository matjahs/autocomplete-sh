#!/bin/sh

# AutoComplete - brings LLMs into the Terminal
# This install script downloads the latest version of the LLMs

# The URL of the latest version of the LLMs
ACSH_VERSION="v0.5.0"
BRANCH_OR_VERSION=${1:-$ACSH_VERSION}

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

# Determine install directory
INSTALL_DIR="$HOME/.local/bin"
if [ ! -d "$INSTALL_DIR" ]; then
    INSTALL_DIR="/usr/local/bin"
fi

# Install from local file or download from GitHub
if [ "$BRANCH_OR_VERSION" = "dev" ]; then
    # Use local autocomplete files
    if [ -f "./$SCRIPT_NAME" ]; then
        cp "./$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
        echo "Installed local development version to $INSTALL_DIR/$SCRIPT_NAME"
    else
        echo "ERROR: Local $SCRIPT_NAME file not found."
        exit 1
    fi
    if [ -f "./autocomplete.sh" ]; then
        cp "./autocomplete.sh" "$INSTALL_DIR/autocomplete"
        echo "Installed local development dispatcher to $INSTALL_DIR/autocomplete"
    else
        echo "ERROR: Local autocomplete.sh dispatcher file not found."
        exit 1
    fi
else
    # Download shell-specific script from GitHub
    URL="https://raw.githubusercontent.com/closedloop-technologies/autocomplete-sh/${BRANCH_OR_VERSION}/$SCRIPT_NAME"
    wget -nv -O "$INSTALL_DIR/$SCRIPT_NAME" "$URL"
    # Download dispatcher from GitHub
    DISPATCHER_URL="https://raw.githubusercontent.com/closedloop-technologies/autocomplete-sh/${BRANCH_OR_VERSION}/autocomplete.sh"
    wget -nv -O "$INSTALL_DIR/autocomplete" "$DISPATCHER_URL"
fi

# Make both scripts executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/autocomplete"

# Check if jq is installed
if ! command -v jq > /dev/null 2>&1; then
    echo "ERROR: jq is not installed. Please install jq to continue."
    echo "For Ubuntu/Debian: sudo apt-get install jq"
    echo "For CentOS/RHEL: sudo yum install jq"
    echo "For macOS (using Homebrew): brew install jq"
fi

# Source bash-completion if _init_completion function does not exist
if ! command -v _init_completion > /dev/null 2>&1; then
    # shellcheck disable=SC1091
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    else
        echo "ERROR: Please ensure you have bash-completion installed and sourced."
        exit 1
    fi
fi

# Proceed with installation
"$INSTALL_DIR/autocomplete" install
