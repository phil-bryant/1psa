#!/bin/bash
umask 007
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_XCODE_SETUP="${SKIP_XCODE_SETUP:-false}"
if [ -d "$HOME/.local/bin" ]; then PATH="$HOME/.local/bin:$PATH"; fi

print_header() {
    echo "============================================================"
    echo "Prerequisites Installer"
    echo "============================================================"
    echo ""
}

ensure_homebrew() {
    echo "[Homebrew] Checking..."
    if ! command -v brew; then
        echo "❌ [Homebrew] Not installed."
        echo ""
        echo "Please install Homebrew first by running:"
        echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo ""
        echo "After installation, add Homebrew to your PATH and run this script again."
        echo "For more information, visit: https://brew.sh/"
        exit 1
    fi
    echo "✅ [Homebrew] Installed"
}

ensure_brew_writable() {
    echo "[Homebrew] Verifying writable paths..."
    BREW_PREFIX="$(brew --prefix)"
    LOG_DIR="$HOME/Library/Logs/Homebrew"
    for path in "$BREW_PREFIX" "$BREW_PREFIX/Cellar" "$BREW_PREFIX/bin" "$LOG_DIR"; do
        if [ ! -e "$path" ]; then continue; fi
        if [ -w "$path" ]; then continue; fi
        echo "❌ [Homebrew] Path is not writable: $path"
        echo "Run:"
        echo "  sudo chown -R $(id -un) \"$path\""
        echo "  chmod u+w \"$path\""
        exit 1
    done
    echo "✅ [Homebrew] Writable paths verified"
}

ensure_brew_formula() {
    FORMULA="$1"
    COMMAND_NAME="${2:-$FORMULA}"
    if command -v "$COMMAND_NAME"; then
        echo "✅ [$FORMULA] Available on PATH"
        return
    fi
    echo "⚠️  [$FORMULA] Missing on PATH"
    echo "[${FORMULA}] Installing via Homebrew..."
    brew install "$FORMULA"
    if command -v "$COMMAND_NAME"; then
        echo "✅ [$FORMULA] Installed and available"
    else
        echo "❌ [$FORMULA] Install completed but command still unavailable"
        exit 1
    fi
}

ensure_pipx_tool() {
    PACKAGE="$1"
    COMMAND_NAME="${2:-$PACKAGE}"
    if command -v "$COMMAND_NAME"; then
        echo "✅ [${PACKAGE}] Available on PATH"
        return
    fi
    echo "⚠️  [${PACKAGE}] Missing on PATH"
    echo "[${PACKAGE}] Installing via pipx..."
    pipx install --include-deps "$PACKAGE"
    if [ -d "$HOME/.local/bin" ]; then PATH="$HOME/.local/bin:$PATH"; fi
    if command -v "$COMMAND_NAME"; then
        echo "✅ [${PACKAGE}] Installed and available"
    elif [ -x "$HOME/.local/bin/$COMMAND_NAME" ]; then
        echo "✅ [${PACKAGE}] Installed at $HOME/.local/bin/${COMMAND_NAME}"
        echo "Add ~/.local/bin to PATH for future shells."
    else
        echo "❌ [${PACKAGE}] Installed but command is still unavailable"
        echo "Try: pipx ensurepath"
        exit 1
    fi
}

ensure_go_tool() {
    COMMAND_NAME="$1"
    MODULE_PATH="$2"
    if command -v "$COMMAND_NAME"; then
        echo "✅ [${COMMAND_NAME}] Available on PATH"
        return
    fi
    echo "⚠️  [${COMMAND_NAME}] Missing on PATH"
    echo "[${COMMAND_NAME}] Installing via go install ${MODULE_PATH}@latest ..."
    go install "${MODULE_PATH}@latest"
    GOPATH_BIN="$(go env GOPATH)/bin/${COMMAND_NAME}"
    if command -v "$COMMAND_NAME"; then
        echo "✅ [${COMMAND_NAME}] Installed and available"
    elif [ -x "$GOPATH_BIN" ]; then
        echo "✅ [${COMMAND_NAME}] Installed at ${GOPATH_BIN}"
        echo "Add $(go env GOPATH)/bin to PATH for future shells."
    else
        echo "❌ [${COMMAND_NAME}] Install completed but command is still unavailable"
        exit 1
    fi
}

ensure_xcode_ready() {
    if [ "$SKIP_XCODE_SETUP" = "true" ]; then
        echo ""
        echo "[Xcode] Skipped (SKIP_XCODE_SETUP=true)"
        return
    fi
    echo ""
    echo "[Xcode] Checking..."
    if ! command -v xcodebuild; then
        echo "❌ [Xcode] xcodebuild not found."
        echo "Install Xcode (or Command Line Tools) and run this script again."
        echo "Tip: xcode-select --install"
        exit 1
    fi

    if xcodebuild -checkFirstLaunchStatus; then
        echo "✅ [Xcode] First-launch status already configured"
        return
    fi

    echo "⚠️  [Xcode] First-launch setup required; running with sudo..."
    sudo -k
    sudo xcodebuild -runFirstLaunch

    # Some Xcode installations still require explicit license acceptance.
    if ! xcodebuild -license check; then
        echo "⚠️  [Xcode] Accepting Xcode license..."
        sudo -k
        sudo xcodebuild -license accept
    fi

    if xcodebuild -checkFirstLaunchStatus; then
        echo "✅ [Xcode] First-launch setup completed"
    else
        echo "❌ [Xcode] First-launch setup did not complete successfully"
        exit 1
    fi
}

print_final_guidance() {
    echo ""
    echo "✅ All prerequisites are satisfied!"
    echo ""
    echo "Local prerequisite paths:"
    echo "- 1psa repository: ${SCRIPT_DIR}"
}

print_header

ensure_homebrew
ensure_brew_writable

echo ""
echo "[Tooling] Checking build dependencies..."
ensure_brew_formula "go"
ensure_brew_formula "git"
ensure_brew_formula "bats-core" "bats"
ensure_brew_formula "clamav" "clamscan"
ensure_brew_formula "semgrep"
ensure_brew_formula "pipx"
ensure_pipx_tool "bandit"
ensure_pipx_tool "pip-audit" "pip-audit"
ensure_pipx_tool "detect-secrets" "detect-secrets"
ensure_go_tool "gosec" "github.com/securego/gosec/v2/cmd/gosec"
ensure_go_tool "govulncheck" "golang.org/x/vuln/cmd/govulncheck"

ensure_xcode_ready
print_final_guidance
