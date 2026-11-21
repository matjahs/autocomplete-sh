#!/bin/sh

# autocomplete.sh installer
# Usage:
#   ./install.sh              — auto-detects local files; downloads latest if not found
#   ./install.sh local|dev    — force install from local files
#   ./install.sh <version>    — download a specific version (e.g. v0.5.0)

ACSH_VERSION="v0.5.0"

detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        parent_shell=$(ps -p $PPID -o comm=)
        case "$parent_shell" in
            *zsh*)  echo "zsh" ;;
            *bash*) echo "bash" ;;
            *)      echo "unknown" ;;
        esac
    fi
}

SHELL_TYPE=$(detect_shell)
case "$SHELL_TYPE" in
    zsh)  SCRIPT_NAME="autocomplete_zsh.sh" ;;
    bash) SCRIPT_NAME="autocomplete_bash.sh" ;;
    *)
        echo "ERROR: Unsupported shell. Currently only bash and zsh are supported."
        exit 1
        ;;
esac

INSTALL_DIR="$HOME/.local/bin"
if [ ! -d "$INSTALL_DIR" ]; then
    INSTALL_DIR="/usr/local/bin"
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)

ARG=${1:-}
if [ "$ARG" = "dev" ] || [ "$ARG" = "local" ]; then
    LOCAL=true
    BRANCH_OR_VERSION=""
elif [ -n "$ARG" ]; then
    LOCAL=false
    BRANCH_OR_VERSION="$ARG"
elif [ -f "$SCRIPT_DIR/autocomplete.sh" ] && [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
    LOCAL=true
    BRANCH_OR_VERSION=""
else
    LOCAL=false
    BRANCH_OR_VERSION="$ACSH_VERSION"
fi

if [ "$LOCAL" = true ]; then
    echo "Installing from local files..."
    if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        echo "ERROR: $SCRIPT_NAME not found in $SCRIPT_DIR"
        exit 1
    fi
    if [ ! -f "$SCRIPT_DIR/autocomplete.sh" ]; then
        echo "ERROR: autocomplete.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
    cp "$SCRIPT_DIR/autocomplete.sh" "$INSTALL_DIR/autocomplete"
    echo "Installed to $INSTALL_DIR"
else
    echo "Downloading autocomplete.sh ${BRANCH_OR_VERSION}..."
    URL="https://raw.githubusercontent.com/matjahs/autocomplete-sh/${BRANCH_OR_VERSION}/$SCRIPT_NAME"
    wget -nv -O "$INSTALL_DIR/$SCRIPT_NAME" "$URL"
    DISPATCHER_URL="https://raw.githubusercontent.com/matjahs/autocomplete-sh/${BRANCH_OR_VERSION}/autocomplete.sh"
    wget -nv -O "$INSTALL_DIR/autocomplete" "$DISPATCHER_URL"
fi

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/autocomplete"

if ! command -v jq > /dev/null 2>&1; then
    echo "ERROR: jq is not installed. Please install jq to continue."
    echo "  Ubuntu/Debian:  sudo apt-get install jq"
    echo "  CentOS/RHEL:    sudo yum install jq"
    echo "  macOS:          brew install jq"
fi

if [ "$SHELL_TYPE" = "bash" ] && ! command -v _init_completion > /dev/null 2>&1; then
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

"$INSTALL_DIR/autocomplete" install
