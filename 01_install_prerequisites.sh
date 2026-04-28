#!/bin/bash
umask 007

#R001: Run with bash and fail fast on unrecoverable errors.
set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZAP_APP_PATH="${ZAP_APP_PATH:-/Applications/ZAP.app}"
ZAP_CLI_PATH="${ZAP_CLI_PATH:-${ZAP_APP_PATH}/Contents/MacOS/ZAP.sh}"

print_header() {
    echo "============================================================"
    echo "Prerequisites Installer"
    echo "============================================================"
    echo ""
}

ensure_homebrew() {
    #R005: Verify Homebrew is present before package actions.
    #R035: Emit explicit status lines for this prerequisite phase.
    echo "[Homebrew] Checking..."
    if ! command -v brew >/dev/null 2>&1; then
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

ensure_brew_formula() {
    #R012 #R030: Ensure required brew formulas are available.
    #R035 #R040: Print status and skip install when already available.
    FORMULA="$1"
    COMMAND_NAME="${2:-$FORMULA}"

    if command -v "$COMMAND_NAME" >/dev/null 2>&1; then
        echo "✅ [$FORMULA] Available on PATH"
        return
    fi

    echo "⚠️  [$FORMULA] Missing on PATH"
    echo "[${FORMULA}] Installing via Homebrew..."
    brew install "$FORMULA"

    if command -v "$COMMAND_NAME" >/dev/null 2>&1; then
        echo "✅ [$FORMULA] Installed and available"
    else
        echo "❌ [$FORMULA] Install completed but command still unavailable"
        exit 1
    fi
}

ensure_zap_cli() {
    #R070: Ensure local OWASP ZAP CLI is installed via Homebrew cask when missing.
    #R075: Verify expected CLI wrapper path after install.
    #R035 #R040: Emit status lines and keep phase idempotent.
    echo ""
    echo "[ZAP] Checking..."

    if [ -x "$ZAP_CLI_PATH" ]; then
        echo "✅ [ZAP] CLI available at ${ZAP_CLI_PATH}"
        return
    fi

    echo "⚠️  [ZAP] CLI wrapper missing at ${ZAP_CLI_PATH}"
    echo "[ZAP] Installing Homebrew cask 'zap'..."
    brew install --cask zap

    if [ -x "$ZAP_CLI_PATH" ]; then
        echo "✅ [ZAP] Installed and CLI available at ${ZAP_CLI_PATH}"
    else
        echo "❌ [ZAP] Install completed but CLI wrapper is still missing at ${ZAP_CLI_PATH}"
        echo "Open ZAP.app once if macOS blocked first launch, then rerun this script."
        exit 1
    fi
}

ensure_xcode_ready() {
    #R060: Ensure xcodebuild exists and Xcode first-launch setup is complete.
    #R065: Use standard sudo authentication for privileged Xcode initialization.
    echo ""
    echo "[Xcode] Checking..."
    if ! command -v xcodebuild >/dev/null 2>&1; then
        echo "❌ [Xcode] xcodebuild not found."
        echo "Install Xcode (or Command Line Tools) and run this script again."
        echo "Tip: xcode-select --install"
        exit 1
    fi

    if xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
        echo "✅ [Xcode] First-launch status already configured"
        return
    fi

    echo "⚠️  [Xcode] First-launch setup required; running with sudo..."
    sudo -k
    sudo xcodebuild -runFirstLaunch

    # Some Xcode installations still require explicit license acceptance.
    if ! xcodebuild -license check >/dev/null 2>&1; then
        echo "⚠️  [Xcode] Accepting Xcode license..."
        sudo -k
        sudo xcodebuild -license accept
    fi

    if xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
        echo "✅ [Xcode] First-launch setup completed"
    else
        echo "❌ [Xcode] First-launch setup did not complete successfully"
        exit 1
    fi
}

print_final_guidance() {
    #R050: Print final readiness guidance and local repository path.
    echo ""
    echo "✅ All prerequisites are satisfied!"
    echo ""
    echo "Local prerequisite paths:"
    echo "- 1psa repository: ${SCRIPT_DIR}"
}

print_header

ensure_homebrew

echo ""
echo "[Tooling] Checking build dependencies..."
ensure_brew_formula "go"
ensure_brew_formula "git"
#R055: Ensure bats shell test runner dependency is installed via Homebrew.
ensure_brew_formula "bats-core" "bats"
#R095: Ensure ClamAV antivirus scanner is available for repository malware scans.
ensure_brew_formula "clamav" "clamscan"
ensure_zap_cli

ensure_xcode_ready
print_final_guidance
