#!/bin/bash
# install-uv-macos.sh
# Robust uv installer for macOS - handles Homebrew, shell profiles, and auto-venv activation
# Run as: bash install-uv-macos.sh
# Or: chmod +x install-uv-macos.sh && ./install-uv-macos.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Parse arguments
FORCE=false
INSTALL_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
            shift
            ;;
        --install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--force] [--install-dir <path>]"
            exit 1
            ;;
    esac
done

print_header "UV INSTALLER FOR MACOS"
echo "  Modeling Macroeconomics - JHU"
echo ""

# --- Diagnostics ---
print_step "Running diagnostics..."

echo ""
echo -e "${MAGENTA}System Information:${NC}"
echo "  Username       : $USER"
echo "  Home Directory : $HOME"
echo "  Current Dir    : $PWD"
echo "  Shell          : $SHELL"
echo "  macOS Version  : $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
echo "  Architecture   : $(uname -m)"
echo "  Terminal       : ${TERM_PROGRAM:-Native}"

# Detect shell
CURRENT_SHELL=$(basename "$SHELL")
echo "  Current Shell  : $CURRENT_SHELL"

# Detect if running in VS Code
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    echo -e "  ${YELLOW}Running in VS Code terminal${NC}"
fi

# --- Determine Install Location ---
print_step "Determining install location..."

if [[ -n "$INSTALL_DIR" ]]; then
    UV_INSTALL_DIR="$INSTALL_DIR"
    print_info "Using custom install directory: $UV_INSTALL_DIR"
else
    UV_INSTALL_DIR="$HOME/.local/bin"
    print_info "Using default location: $UV_INSTALL_DIR"
fi

# --- Check Existing Installation ---
print_step "Checking for existing uv installation..."

EXISTING_UV=$(command -v uv 2>/dev/null || true)

if [[ -n "$EXISTING_UV" && "$FORCE" != "true" ]]; then
    print_success "uv is already installed at: $EXISTING_UV"
    echo ""
    echo -e "${MAGENTA}Current uv version:${NC}"
    uv --version
    echo ""
    echo -e "${YELLOW}To reinstall, run with --force flag${NC}"
    ACTUAL_UV_DIR=$(dirname "$EXISTING_UV")
else
    if [[ "$FORCE" == "true" && -n "$EXISTING_UV" ]]; then
        print_info "Force flag set, reinstalling..."
    fi

    # --- Create Install Directory ---
    print_step "Creating install directory..."

    if [[ ! -d "$UV_INSTALL_DIR" ]]; then
        mkdir -p "$UV_INSTALL_DIR"
        print_success "Created directory: $UV_INSTALL_DIR"
    else
        print_info "Directory exists: $UV_INSTALL_DIR"
    fi

    # --- Download and Install uv ---
    print_step "Downloading uv via official installer..."

    # Use official installer
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        print_success "uv installed via official installer"
    else
        print_fail "Official installer failed"
        print_info "Trying direct download..."

        # Direct download fallback
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64)
                ARCH_NAME="x86_64"
                ;;
            arm64|aarch64)
                ARCH_NAME="aarch64"
                ;;
            *)
                print_fail "Unsupported architecture: $ARCH"
                exit 1
                ;;
        esac

        print_info "Detected architecture: $ARCH_NAME"

        # Get latest release URL from GitHub API
        RELEASE_URL=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | \
            grep "browser_download_url.*uv-$ARCH_NAME-apple-darwin.tar.gz" | \
            cut -d '"' -f 4 | head -1)

        if [[ -z "$RELEASE_URL" ]]; then
            print_fail "Could not find download URL for architecture: $ARCH_NAME"
            exit 1
        fi

        print_info "Downloading from: $RELEASE_URL"
        TEMP_DIR=$(mktemp -d)
        curl -L "$RELEASE_URL" -o "$TEMP_DIR/uv.tar.gz"
        tar -xzf "$TEMP_DIR/uv.tar.gz" -C "$TEMP_DIR"

        # Find and move uv binary
        UV_BINARY=$(find "$TEMP_DIR" -name "uv" -type f | head -1)
        if [[ -n "$UV_BINARY" ]]; then
            mv "$UV_BINARY" "$UV_INSTALL_DIR/uv"
            chmod +x "$UV_INSTALL_DIR/uv"
            print_success "uv installed to $UV_INSTALL_DIR"
        else
            print_fail "Could not find uv binary in downloaded archive"
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        rm -rf "$TEMP_DIR"
    fi

    ACTUAL_UV_DIR="$UV_INSTALL_DIR"
fi

# --- Find actual uv location ---
if [[ -z "$ACTUAL_UV_DIR" ]]; then
    # Search common locations
    POSSIBLE_LOCATIONS=(
        "$HOME/.local/bin"
        "$HOME/.cargo/bin"
        "/usr/local/bin"
        "/opt/homebrew/bin"
        "$UV_INSTALL_DIR"
    )

    for loc in "${POSSIBLE_LOCATIONS[@]}"; do
        if [[ -x "$loc/uv" ]]; then
            ACTUAL_UV_DIR="$loc"
            print_info "Found uv at: $loc/uv"
            break
        fi
    done
fi

if [[ -z "$ACTUAL_UV_DIR" ]]; then
    print_fail "Could not locate uv after installation"
    exit 1
fi

# --- Update PATH in Shell Profile ---
print_step "Updating PATH in shell profile..."

# Determine which profile to update
case "$CURRENT_SHELL" in
    zsh)
        PROFILE_FILE="$HOME/.zshrc"
        ;;
    bash)
        # On macOS, bash uses .bash_profile for login shells
        if [[ -f "$HOME/.bash_profile" ]]; then
            PROFILE_FILE="$HOME/.bash_profile"
        else
            PROFILE_FILE="$HOME/.bashrc"
        fi
        ;;
    *)
        PROFILE_FILE="$HOME/.profile"
        ;;
esac

print_info "Using profile: $PROFILE_FILE"

# Create profile file if it doesn't exist
if [[ ! -f "$PROFILE_FILE" ]]; then
    touch "$PROFILE_FILE"
    print_info "Created profile file: $PROFILE_FILE"
fi

# Check if PATH entry already exists
PATH_ENTRY="export PATH=\"$ACTUAL_UV_DIR:\$PATH\""
if grep -q "$ACTUAL_UV_DIR" "$PROFILE_FILE" 2>/dev/null; then
    print_info "$ACTUAL_UV_DIR already in PATH (in $PROFILE_FILE)"
else
    echo "" >> "$PROFILE_FILE"
    echo "# Added by uv installer" >> "$PROFILE_FILE"
    echo "$PATH_ENTRY" >> "$PROFILE_FILE"
    print_success "Added $ACTUAL_UV_DIR to PATH in $PROFILE_FILE"
fi

# Also add to current session
export PATH="$ACTUAL_UV_DIR:$PATH"

# --- Verification ---
print_header "VERIFICATION"

print_step "Verifying uv is accessible..."

# Test 1: Direct path execution
print_info "Test 1: Direct path execution"
if [[ -x "$ACTUAL_UV_DIR/uv" ]]; then
    VERSION=$("$ACTUAL_UV_DIR/uv" --version 2>&1)
    print_success "Direct execution: $VERSION"
else
    print_fail "uv not found at $ACTUAL_UV_DIR/uv"
fi

# Test 2: PATH execution
print_info "Test 2: PATH execution (using 'uv' command)"
if command -v uv &>/dev/null; then
    VERSION=$(uv --version 2>&1)
    UV_LOCATION=$(command -v uv)
    print_success "PATH execution: $VERSION"
    print_success "uv location: $UV_LOCATION"
else
    print_fail "uv not found in PATH"
    echo "  You may need to restart your terminal or run: source $PROFILE_FILE"
fi

# Test 3: Create test project
print_step "Testing uv sync functionality..."

TEST_DIR=$(mktemp -d)
print_info "Created test directory: $TEST_DIR"

cd "$TEST_DIR"
if "$ACTUAL_UV_DIR/uv" init &>/dev/null; then
    print_success "uv init succeeded"

    if "$ACTUAL_UV_DIR/uv" sync &>/dev/null; then
        print_success "uv sync succeeded"
    else
        print_fail "uv sync failed"
    fi
else
    print_fail "uv init failed"
fi

cd - &>/dev/null
rm -rf "$TEST_DIR"

# --- Setup Auto-Venv Activation ---
print_header "AUTO-VENV ACTIVATION SETUP"

print_step "Setting up automatic venv activation..."

# Auto-venv activation code
AUTO_VENV_CODE='
# --- Auto-activate .venv when entering directory (added by uv installer) ---
autoload -Uz add-zsh-hook 2>/dev/null || true

_auto_venv_chpwd() {
    if [[ -f ".venv/bin/activate" ]]; then
        if [[ -z "$VIRTUAL_ENV" ]] || [[ "$VIRTUAL_ENV" != "$PWD/.venv" ]]; then
            source .venv/bin/activate
            echo -e "\033[0;32m[venv]\033[0m Activated .venv"
        fi
    fi
}

# For zsh
if [[ -n "$ZSH_VERSION" ]]; then
    add-zsh-hook chpwd _auto_venv_chpwd 2>/dev/null || true
fi

# For bash
if [[ -n "$BASH_VERSION" ]]; then
    _auto_venv_prompt_command() {
        _auto_venv_chpwd
    }
    if [[ ! "$PROMPT_COMMAND" =~ "_auto_venv_prompt_command" ]]; then
        PROMPT_COMMAND="_auto_venv_prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    fi
fi

# Check on shell startup (for when terminal opens in a project directory)
_auto_venv_chpwd
# --- End auto-venv activation ---
'

# Check if already added
if grep -q "Auto-activate .venv when entering directory" "$PROFILE_FILE" 2>/dev/null; then
    print_info "Auto-venv activation already configured in $PROFILE_FILE"
else
    echo "$AUTO_VENV_CODE" >> "$PROFILE_FILE"
    print_success "Added auto-venv activation to $PROFILE_FILE"
    echo ""
    echo "  Auto-venv activation is now enabled!"
    echo "  When you 'cd' into a directory with a .venv folder,"
    echo "  the virtual environment will be activated automatically."
fi

# --- Summary ---
print_header "SUMMARY"

echo -e "uv install directory: ${GREEN}$ACTUAL_UV_DIR${NC}"
echo -e "uv executable: ${GREEN}$ACTUAL_UV_DIR/uv${NC}"
echo -e "Shell profile: ${GREEN}$PROFILE_FILE${NC}"
echo ""
echo -e "${MAGENTA}To use uv from any location:${NC}"
echo "  1. Open a NEW terminal window (or run: source $PROFILE_FILE)"
echo "  2. Run: uv --version"
echo "  3. In your project folder, run: uv sync"
echo ""
echo -e "${MAGENTA}Auto-venv activation:${NC}"
echo "  When you cd into a directory with .venv, it activates automatically!"
echo ""
