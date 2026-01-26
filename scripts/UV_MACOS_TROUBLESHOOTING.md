# UV macOS Installation Troubleshooting Guide

This guide helps resolve uv installation issues on macOS, including:
- Apple Silicon (M1/M2/M3) and Intel Macs
- VS Code terminal not recognizing uv
- Shell profile configuration (zsh/bash)
- Auto-venv activation setup

## Quick Start

### Option 1: Run the Automated Installer

```bash
# Download and run the installer script
bash install-uv-macos.sh
```

This installer will:
- Install uv using the official installer
- Add uv to your PATH
- Set up auto-venv activation (activates .venv when you cd into a project)

### Option 2: Run Diagnostics First

If uv seems installed but doesn't work:
```bash
bash diagnose-uv-macos.sh
```

## Common Issues and Solutions

### Issue 1: "uv: command not found"

**Step 1:** Check if uv is installed somewhere:
```bash
# Check common locations
ls -la ~/.local/bin/uv
ls -la ~/.cargo/bin/uv
ls -la /usr/local/bin/uv
ls -la /opt/homebrew/bin/uv
```

**Step 2:** If found, add to PATH:
```bash
# For zsh (default on modern macOS)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# For bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

**Step 3:** If not found, install:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Issue 2: VS Code Terminal Doesn't See uv

**Why:** VS Code may cache the PATH when it starts, or use a different shell configuration.

**Solutions:**

1. **Restart VS Code completely** (close all windows, reopen)

2. **Add to VS Code settings** (`Cmd+,` → search "terminal.integrated.env.osx"):
   ```json
   {
     "terminal.integrated.env.osx": {
       "PATH": "${env:HOME}/.local/bin:${env:PATH}"
     }
   }
   ```

3. **Quick fix in current terminal:**
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

4. **Ensure your shell profile is being sourced:**
   ```bash
   # For zsh (check which files exist)
   ls -la ~/.zshrc ~/.zprofile ~/.zshenv

   # The file should contain PATH export
   grep -l "\.local/bin" ~/.zshrc ~/.zprofile 2>/dev/null
   ```

### Issue 3: Apple Silicon vs Intel Architecture

**Auto-detect your architecture:**
```bash
uname -m
# arm64 = Apple Silicon (M1/M2/M3)
# x86_64 = Intel
```

**Manual download for specific architecture:**
```bash
# Auto-detect and download
ARCH=$(uname -m)
case "$ARCH" in
    arm64|aarch64) ARCH_NAME="aarch64" ;;
    x86_64) ARCH_NAME="x86_64" ;;
esac

RELEASE_URL=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | \
    grep "browser_download_url.*uv-$ARCH_NAME-apple-darwin.tar.gz" | \
    cut -d '"' -f 4 | head -1)

echo "Downloading: $RELEASE_URL"
curl -L "$RELEASE_URL" -o /tmp/uv.tar.gz
mkdir -p ~/.local/bin
tar -xzf /tmp/uv.tar.gz -C /tmp
find /tmp -name "uv" -type f -exec mv {} ~/.local/bin/uv \;
chmod +x ~/.local/bin/uv
rm /tmp/uv.tar.gz
```

### Issue 4: Homebrew-Installed Python Conflicts

If you have Python installed via Homebrew and experience conflicts:

```bash
# Check which python is being used
which python3
which pip3

# Ensure uv uses its own Python management
uv python list
uv python install 3.12
```

### Issue 5: Permission Denied Errors

```bash
# If ~/.local/bin doesn't exist or has wrong permissions
mkdir -p ~/.local/bin
chmod 755 ~/.local/bin

# If uv binary isn't executable
chmod +x ~/.local/bin/uv
```

## Manual Installation (Clean Install)

If all else fails, do a completely manual installation:

```bash
# 1. Remove any existing uv installations
rm -f ~/.local/bin/uv
rm -f ~/.cargo/bin/uv
rm -rf ~/.cache/uv

# 2. Create install directory
mkdir -p ~/.local/bin

# 3. Download latest release (auto-detect architecture)
ARCH=$(uname -m)
case "$ARCH" in
    arm64|aarch64) ARCH_NAME="aarch64" ;;
    x86_64) ARCH_NAME="x86_64" ;;
esac

RELEASE_URL=$(curl -s https://api.github.com/repos/astral-sh/uv/releases/latest | \
    grep "browser_download_url.*uv-$ARCH_NAME-apple-darwin.tar.gz" | \
    cut -d '"' -f 4 | head -1)

echo "Downloading from: $RELEASE_URL"
curl -L "$RELEASE_URL" -o /tmp/uv.tar.gz

# 4. Extract
tar -xzf /tmp/uv.tar.gz -C /tmp

# 5. Move binary
find /tmp -name "uv" -type f -exec mv {} ~/.local/bin/uv \;
chmod +x ~/.local/bin/uv
rm /tmp/uv.tar.gz

# 6. Add to PATH (for zsh)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

# 7. Reload shell
source ~/.zshrc

# 8. Verify
uv --version
```

## Setting Up Auto-Venv Activation

The installer script automatically sets this up, but you can add it manually:

### For Zsh (~/.zshrc)

```bash
# Auto-activate .venv when entering directory
autoload -Uz add-zsh-hook

_auto_venv_chpwd() {
    if [[ -f ".venv/bin/activate" ]]; then
        if [[ -z "$VIRTUAL_ENV" ]] || [[ "$VIRTUAL_ENV" != "$PWD/.venv" ]]; then
            source .venv/bin/activate
            echo -e "\033[0;32m[venv]\033[0m Activated .venv"
        fi
    fi
}

add-zsh-hook chpwd _auto_venv_chpwd

# Also check on shell startup
_auto_venv_chpwd
```

### For Bash (~/.bash_profile or ~/.bashrc)

```bash
# Auto-activate .venv when entering directory
_auto_venv_prompt_command() {
    if [[ -f ".venv/bin/activate" ]]; then
        if [[ -z "$VIRTUAL_ENV" ]] || [[ "$VIRTUAL_ENV" != "$PWD/.venv" ]]; then
            source .venv/bin/activate
            echo -e "\033[0;32m[venv]\033[0m Activated .venv"
        fi
    fi
}

PROMPT_COMMAND="_auto_venv_prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

# Also check on shell startup
_auto_venv_prompt_command
```

## Verifying Installation

After installation, verify everything works:

```bash
# Check uv is accessible
uv --version

# Check which uv is being used
which uv

# Test in a project directory
cd <your-project-folder>
uv sync

# Check if venv was created
ls -la .venv/
```

## For Instructors: Helping Students

When a student has issues:

1. Have them run the diagnostic script first:
   ```bash
   bash diagnose-uv-macos.sh
   ```

2. Look for:
   - Missing PATH entries
   - Wrong shell profile being edited
   - Architecture mismatches (Intel binary on Apple Silicon)

3. The safest solution is usually:
   ```bash
   bash install-uv-macos.sh --force
   ```

4. Have them **close and reopen Terminal** (or VS Code) to refresh the PATH

## Additional Resources

- [uv Documentation](https://docs.astral.sh/uv/)
- [uv GitHub Issues](https://github.com/astral-sh/uv/issues) - Search for macOS-specific problems
