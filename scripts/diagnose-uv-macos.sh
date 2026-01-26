#!/bin/bash
# diagnose-uv-macos.sh
# Diagnostic script to troubleshoot uv installation issues on macOS
# Run as: bash diagnose-uv-macos.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SEPARATOR="============================================================"
DASH_LINE="----------------------------------------"

echo ""
echo -e "${CYAN}${SEPARATOR}${NC}"
echo -e "${CYAN}  UV DIAGNOSTIC TOOL FOR MACOS${NC}"
echo -e "${CYAN}  JHU Modeling Macroeconomics${NC}"
echo -e "${CYAN}${SEPARATOR}${NC}"
echo ""

# --- System Information ---
echo -e "${MAGENTA}SYSTEM INFORMATION${NC}"
echo "$DASH_LINE"

echo "  Username       : $USER"
echo "  Home Directory : $HOME"
echo "  Current Dir    : $PWD"
echo "  Shell          : $SHELL"
echo "  macOS Version  : $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
echo "  Architecture   : $(uname -m)"
echo "  Kernel         : $(uname -r)"

# Check for Homebrew
if command -v brew &>/dev/null; then
    BREW_VERSION=$(brew --version | head -1)
    echo -e "  Homebrew       : ${GREEN}$BREW_VERSION${NC}"
else
    echo -e "  Homebrew       : ${YELLOW}Not installed${NC}"
fi

# Terminal info
echo "  Terminal       : ${TERM_PROGRAM:-Native}"
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    echo -e "  ${YELLOW}Running in VS Code terminal${NC}"
fi

# --- PATH Analysis ---
echo ""
echo -e "${MAGENTA}PATH ANALYSIS${NC}"
echo "$DASH_LINE"

echo ""
echo -e "  ${YELLOW}Current PATH entries:${NC}"
IFS=':' read -ra PATH_ENTRIES <<< "$PATH"
i=1
for entry in "${PATH_ENTRIES[@]}"; do
    if [[ -d "$entry" ]]; then
        status="${GREEN}[OK]${NC}"
    else
        status="${RED}[MISSING]${NC}"
    fi
    printf "    %3d. %b %s\n" $i "$status" "$entry"
    ((i++))
done

echo ""
echo -e "  ${YELLOW}PATH entries containing 'uv':${NC}"
UV_PATHS=()
for entry in "${PATH_ENTRIES[@]}"; do
    if [[ "$entry" == *"uv"* ]] || [[ -x "$entry/uv" ]]; then
        if [[ -d "$entry" ]]; then
            echo -e "    ${GREEN}$entry${NC}"
        else
            echo -e "    ${RED}$entry (missing)${NC}"
        fi
        UV_PATHS+=("$entry")
    fi
done
if [[ ${#UV_PATHS[@]} -eq 0 ]]; then
    echo -e "    ${RED}None found - uv may not be in PATH${NC}"
fi

# --- Search for uv installations ---
echo ""
echo -e "${MAGENTA}SEARCHING FOR UV INSTALLATIONS${NC}"
echo "$DASH_LINE"

SEARCH_LOCATIONS=(
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "/usr/local/bin"
    "/opt/homebrew/bin"
    "$HOME/bin"
    "/usr/bin"
)

FOUND_LOCATIONS=()

for loc in "${SEARCH_LOCATIONS[@]}"; do
    if [[ -x "$loc/uv" ]]; then
        FOUND_LOCATIONS+=("$loc/uv")
        echo -e "  ${GREEN}FOUND:${NC} $loc/uv"

        # Try to get version
        VERSION=$("$loc/uv" --version 2>&1 || echo "Could not get version")
        echo "         Version: $VERSION"
    fi
done

if [[ ${#FOUND_LOCATIONS[@]} -eq 0 ]]; then
    echo -e "  ${RED}No uv found in common locations${NC}"
fi

# Also search via which command
echo ""
echo -e "  ${YELLOW}Searching via 'which' command:${NC}"
WHICH_RESULT=$(which uv 2>/dev/null || true)
if [[ -n "$WHICH_RESULT" ]]; then
    echo -e "  ${GREEN}FOUND:${NC} $WHICH_RESULT"
else
    echo -e "  ${RED}'which uv' returned no results${NC}"
fi

# --- Test uv command ---
echo ""
echo -e "${MAGENTA}TESTING UV COMMAND${NC}"
echo "$DASH_LINE"

echo ""
echo -e "  ${YELLOW}Test 1: command -v uv${NC}"
UV_COMMAND=$(command -v uv 2>/dev/null || true)
if [[ -n "$UV_COMMAND" ]]; then
    echo -e "    ${GREEN}SUCCESS${NC} - Found at: $UV_COMMAND"
else
    echo -e "    ${RED}FAILED${NC} - 'uv' not found as a command"
fi

echo ""
echo -e "  ${YELLOW}Test 2: uv --version${NC}"
if command -v uv &>/dev/null; then
    VERSION=$(uv --version 2>&1)
    if [[ $? -eq 0 ]]; then
        echo -e "    ${GREEN}SUCCESS${NC} - $VERSION"
    else
        echo -e "    ${RED}FAILED${NC} - Exit code: $?"
        echo "    Output: $VERSION"
    fi
else
    echo -e "    ${RED}FAILED${NC} - uv command not available"
fi

# --- Environment Variables ---
echo ""
echo -e "${MAGENTA}RELEVANT ENVIRONMENT VARIABLES${NC}"
echo "$DASH_LINE"

ENV_VARS=(
    "UV_INSTALL_DIR"
    "UV_CACHE_DIR"
    "UV_PYTHON_INSTALL_DIR"
    "CARGO_HOME"
    "RUSTUP_HOME"
    "VIRTUAL_ENV"
    "CONDA_PREFIX"
    "PYENV_ROOT"
)

for var in "${ENV_VARS[@]}"; do
    value="${!var}"
    printf "  %-25s: " "$var"
    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo -e "${YELLOW}(not set)${NC}"
    fi
done

# --- Shell Profile Analysis ---
echo ""
echo -e "${MAGENTA}SHELL PROFILE ANALYSIS${NC}"
echo "$DASH_LINE"

CURRENT_SHELL=$(basename "$SHELL")
echo "  Current shell: $CURRENT_SHELL"

PROFILE_FILES=()
case "$CURRENT_SHELL" in
    zsh)
        PROFILE_FILES=("$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zshenv")
        ;;
    bash)
        PROFILE_FILES=("$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile")
        ;;
    *)
        PROFILE_FILES=("$HOME/.profile")
        ;;
esac

echo ""
echo -e "  ${YELLOW}Checking profile files for uv/PATH entries:${NC}"
for profile in "${PROFILE_FILES[@]}"; do
    if [[ -f "$profile" ]]; then
        echo -e "    ${GREEN}[EXISTS]${NC} $profile"
        # Check for uv-related entries
        if grep -q "\.local/bin\|\.cargo/bin\|/uv" "$profile" 2>/dev/null; then
            echo "             Contains PATH entries for uv locations"
        fi
        if grep -q "auto.*venv\|VIRTUAL_ENV" "$profile" 2>/dev/null; then
            echo "             Contains auto-venv activation"
        fi
    else
        echo -e "    ${YELLOW}[MISSING]${NC} $profile"
    fi
done

# --- Recommendations ---
echo ""
echo -e "${MAGENTA}RECOMMENDATIONS${NC}"
echo "$DASH_LINE"

RECOMMENDATIONS=()

if [[ ${#FOUND_LOCATIONS[@]} -eq 0 ]]; then
    RECOMMENDATIONS+=("uv is not installed. Run: curl -LsSf https://astral.sh/uv/install.sh | sh")
fi

if [[ ${#FOUND_LOCATIONS[@]} -gt 0 && -z "$UV_COMMAND" ]]; then
    RECOMMENDATIONS+=("uv is installed but not in PATH. Add this to your PATH: $(dirname "${FOUND_LOCATIONS[0]}")")
fi

if [[ "$TERM_PROGRAM" == "vscode" && -z "$UV_COMMAND" && ${#FOUND_LOCATIONS[@]} -gt 0 ]]; then
    RECOMMENDATIONS+=("VS Code may have cached an old PATH. Restart VS Code completely.")
fi

if [[ ${#RECOMMENDATIONS[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}Everything looks good! uv should be working.${NC}"
else
    i=1
    for rec in "${RECOMMENDATIONS[@]}"; do
        echo -e "  ${YELLOW}$i. $rec${NC}"
        ((i++))
    done
fi

# --- Quick Fix Commands ---
echo ""
echo -e "${MAGENTA}QUICK FIX COMMANDS${NC}"
echo "$DASH_LINE"

if [[ ${#FOUND_LOCATIONS[@]} -gt 0 ]]; then
    UV_DIR=$(dirname "${FOUND_LOCATIONS[0]}")

    echo ""
    echo "  To add uv to your current session's PATH, run:"
    echo ""
    echo -e "    ${CYAN}export PATH=\"$UV_DIR:\$PATH\"${NC}"
    echo ""
    echo "  To permanently add uv to your shell profile, run:"
    echo ""

    case "$CURRENT_SHELL" in
        zsh)
            PROFILE="$HOME/.zshrc"
            ;;
        bash)
            PROFILE="$HOME/.bash_profile"
            ;;
        *)
            PROFILE="$HOME/.profile"
            ;;
    esac

    echo -e "    ${CYAN}echo 'export PATH=\"$UV_DIR:\$PATH\"' >> $PROFILE${NC}"
    echo ""
    echo "  Then restart your terminal (or run: source $PROFILE)"
fi

echo ""
echo -e "${CYAN}${SEPARATOR}${NC}"
echo -e "${CYAN}  DIAGNOSTIC COMPLETE${NC}"
echo -e "${CYAN}${SEPARATOR}${NC}"
echo ""
