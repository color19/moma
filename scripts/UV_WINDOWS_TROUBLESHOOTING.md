# UV Windows Installation Troubleshooting Guide

This guide helps resolve uv installation issues on Windows, especially for systems with:
- Non-ASCII characters in usernames (e.g., Chinese characters)
- Multiple drives
- VS Code terminal not recognizing uv

## Quick Start

### Option 1: Run the Automated Installer

```powershell
# Download and run the installer script
powershell -ExecutionPolicy Bypass -File install-uv-windows.ps1
```

For system-wide installation (recommended for problematic systems):
```powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File install-uv-windows.ps1 -SystemWide
```

### Option 2: Run Diagnostics First

If uv seems installed but doesn't work:
```powershell
powershell -ExecutionPolicy Bypass -File diagnose-uv-windows.ps1
```

## Common Issues and Solutions

### Issue 1: Non-ASCII Username Path

**Symptom:** uv installs but fails to run, especially with Chinese/Japanese/Korean usernames.

**Solution:** Install to a safe path without special characters using direct download:

```powershell
# 1. Create a directory at C:\uv
New-Item -ItemType Directory -Path "C:\uv" -Force

# 2. Download latest uv directly (auto-detect architecture)
$arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture) {
    "Arm64" { "aarch64" }
    "X64"   { "x86_64" }
    "X86"   { "i686" }
    default { if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i686" } }
}
Write-Host "Detected architecture: $arch"
$releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/astral-sh/uv/releases/latest"
$asset = $releaseInfo.assets | Where-Object { $_.name -like "uv-$arch-pc-windows-msvc.zip" } | Select-Object -First 1
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile "$env:TEMP\uv.zip"

# 3. Extract and cleanup
Expand-Archive -Path "$env:TEMP\uv.zip" -DestinationPath "C:\uv" -Force
Remove-Item "$env:TEMP\uv.zip"

# 4. Add to PATH permanently
[Environment]::SetEnvironmentVariable("Path", "C:\uv;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")

# 5. Refresh current session
$env:Path = "C:\uv;" + $env:Path
```

### Issue 2: VS Code Terminal Doesn't See uv

**Symptom:** uv works in regular PowerShell but not in VS Code's integrated terminal.

**Why:** VS Code caches the PATH when it starts. If you installed uv after opening VS Code, it won't see it.

**Solutions:**

1. **Restart VS Code completely** (close all windows, reopen)

2. **Add to VS Code settings** (`Ctrl+,` → search "terminal.integrated.env.windows"):
   ```json
   {
     "terminal.integrated.env.windows": {
       "Path": "C:\\uv;${env:Path}"
     }
   }
   ```

3. **Quick fix in current terminal:**
   ```powershell
   $env:Path = "C:\uv;" + $env:Path
   ```

### Issue 3: Different Behavior on Different Drives

**Symptom:** uv works on C: drive but not D: or E: drives.

**Solution:** Ensure uv is in the **System PATH** (not just User PATH):

```powershell
# Run as Administrator
[Environment]::SetEnvironmentVariable("Path", "C:\uv;" + [Environment]::GetEnvironmentVariable("Path", "Machine"), "Machine")
```

### Issue 4: "uv: command not found" or "not recognized"

**Step 1:** Find where uv is installed:
```powershell
# Check common locations
Test-Path "$env:LOCALAPPDATA\uv\uv.exe"
Test-Path "$env:USERPROFILE\.local\bin\uv.exe"
Test-Path "C:\uv\uv.exe"

# Or search for it (WARNING: This can be very slow on large drives)
# Consider searching specific directories first
Get-ChildItem -Path $env:LOCALAPPDATA, $env:USERPROFILE, "C:\uv" -Recurse -Filter "uv.exe" -ErrorAction SilentlyContinue | Select-Object FullName
```

**Step 2:** Add the found location to PATH:
```powershell
# Replace <UV_PATH> with the directory containing uv.exe
[Environment]::SetEnvironmentVariable("Path", "<UV_PATH>;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")
```

**Step 3:** Open a **new** terminal window.

## Manual Installation (Nuclear Option)

If all else fails, do a completely manual installation:

```powershell
# 1. Remove any existing uv installations
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\uv" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.local\bin\uv.exe" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "C:\uv" -ErrorAction SilentlyContinue

# 2. Create clean directory
New-Item -ItemType Directory -Path "C:\uv" -Force

# 3. Download latest release using GitHub API (auto-detect architecture)
$arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture) {
    "Arm64" { "aarch64" }
    "X64"   { "x86_64" }
    "X86"   { "i686" }
    default { if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i686" } }
}
Write-Host "Detected architecture: $arch"
$releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/astral-sh/uv/releases/latest"
$asset = $releaseInfo.assets | Where-Object { $_.name -like "uv-$arch-pc-windows-msvc.zip" } | Select-Object -First 1
Write-Host "Downloading: $($asset.name)"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile "$env:TEMP\uv.zip"

# 4. Extract
Expand-Archive -Path "$env:TEMP\uv.zip" -DestinationPath "C:\uv" -Force

# 5. Clean up
Remove-Item "$env:TEMP\uv.zip"

# 6. Add to PATH (User level)
[Environment]::SetEnvironmentVariable("Path", "C:\uv;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")

# 7. Refresh current session
$env:Path = "C:\uv;" + $env:Path

# 8. Verify
uv --version
```

## Verifying Installation

After installation, verify everything works:

```powershell
# Check uv is accessible
uv --version

# Check which uv is being used
Get-Command uv | Select-Object Source

# Test in a project directory
cd <your-project-folder>
uv sync
```

## For Instructors: Helping Students

When a student has issues:

1. Have them run the diagnostic script first:
   ```powershell
   .\diagnose-uv-windows.ps1
   ```

2. Look for:
   - Non-ASCII characters in paths (common with Chinese Windows)
   - Missing PATH entries
   - Multiple uv installations

3. The safest solution for problematic systems:
   ```powershell
   # As Administrator
   .\install-uv-windows.ps1 -SystemWide -Force
   ```

4. Have them **sign out and sign back in** to Windows (this refreshes all PATH variables system-wide)

## Setting Up Auto-Venv Activation

The installer script automatically sets this up, but you can add it manually to your PowerShell profile:

**Step 1:** Find your profile path:
```powershell
echo $PROFILE
```

**Step 2:** Edit the profile (create if it doesn't exist):
```powershell
notepad $PROFILE
```

**Step 3:** Add this code:
```powershell
# Auto-activate .venv when entering directory
function Set-LocationWithVenv {
    param([string]$Path)

    # Call the original Set-Location (handle cd with no argument -> go to $HOME)
    if ($Path) {
        Microsoft.PowerShell.Management\Set-Location $Path
    } else {
        Microsoft.PowerShell.Management\Set-Location $HOME
    }

    # Check for .venv in the new directory
    $venvActivate = Join-Path $PWD ".venv\Scripts\Activate.ps1"
    if (Test-Path $venvActivate) {
        if (-not $env:VIRTUAL_ENV -or $env:VIRTUAL_ENV -ne (Join-Path $PWD ".venv")) {
            & $venvActivate
            Write-Host "[venv] Activated .venv" -ForegroundColor Green
        }
    }
}

# Override cd and Set-Location
Set-Alias -Name cd -Value Set-LocationWithVenv -Option AllScope -Scope Global -Force
Set-Alias -Name Set-Location -Value Set-LocationWithVenv -Option AllScope -Scope Global -Force

# Check on profile load
$venvActivate = Join-Path $PWD ".venv\Scripts\Activate.ps1"
if (Test-Path $venvActivate) {
    & $venvActivate
    Write-Host "[venv] Activated .venv" -ForegroundColor Green
}
```

**Step 4:** Reload your profile:
```powershell
. $PROFILE
```

Now when you `cd` into a directory with a `.venv` folder, the virtual environment will be activated automatically.

## Additional Resources

- [uv Documentation](https://docs.astral.sh/uv/)
- [uv GitHub Issues](https://github.com/astral-sh/uv/issues) - Search for Windows-specific problems
