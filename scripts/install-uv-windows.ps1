# install-uv-windows.ps1
# Robust uv installer for Windows - handles non-ASCII paths, multiple drives, VS Code terminals
# Run in PowerShell as: .\install-uv-windows.ps1
# Or with admin rights for system-wide PATH: powershell -ExecutionPolicy Bypass -File .\install-uv-windows.ps1

param(
    [switch]$Force,           # Force reinstall even if uv exists
    [switch]$SystemWide,      # Install to C:\uv instead of user profile
    [string]$InstallDir       # Custom install directory
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  UV INSTALLER FOR WINDOWS" -ForegroundColor Cyan
Write-Host "  Modeling Macroeconomics - JHU" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# --- Helper Functions ---

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Test-PathContainsNonAscii {
    param([string]$Path)
    return $Path -match '[^\x00-\x7F]'
}

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Refresh-PathInSession {
    # Refresh PATH from both Machine and User scopes
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    Write-Info "PATH refreshed in current session"
}

function Add-ToPath {
    param(
        [string]$Directory,
        [string]$Scope  # "User" or "Machine"
    )

    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", $Scope)
    if (-not $currentPath) { $currentPath = "" }

    # Case-insensitive comparison for Windows paths
    $pathEntries = $currentPath -split ';' | Where-Object { $_ } | ForEach-Object { $_.ToLower().TrimEnd('\') }
    $dirLower = $Directory.ToLower().TrimEnd('\')
    if ($pathEntries -contains $dirLower) {
        Write-Info "$Directory already in $Scope PATH"
        return $true
    }
    
    try {
        $newPath = "$currentPath;$Directory"
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, $Scope)
        Write-Success "Added $Directory to $Scope PATH"
        return $true
    }
    catch {
        Write-Fail "Could not add to $Scope PATH: $_"
        return $false
    }
}

# --- Diagnostics ---

Write-Step "Running diagnostics..."

$diagnostics = @{
    "Username" = $env:USERNAME
    "User Profile" = $env:USERPROFILE
    "Local AppData" = $env:LOCALAPPDATA
    "Current Directory" = $PWD.Path
    "Current Drive" = $PWD.Drive.Name
    "PowerShell Version" = $PSVersionTable.PSVersion.ToString()
    "Is Admin" = Test-IsAdmin
    "Is VS Code Terminal" = $env:TERM_PROGRAM -eq "vscode"
}

Write-Host "`nSystem Information:" -ForegroundColor Magenta
foreach ($key in $diagnostics.Keys) {
    Write-Host "  $key : " -NoNewline
    Write-Host $diagnostics[$key] -ForegroundColor White
}

# Check for non-ASCII in user profile path
if (Test-PathContainsNonAscii $env:USERPROFILE) {
    Write-Host "`n  WARNING: User profile contains non-ASCII characters!" -ForegroundColor Yellow
    Write-Host "  This can cause issues. Will use alternative install location.`n" -ForegroundColor Yellow
    $useAlternativeLocation = $true
} else {
    $useAlternativeLocation = $false
}

# --- Determine Install Location ---

Write-Step "Determining install location..."

if ($InstallDir) {
    $uvInstallDir = $InstallDir
    Write-Info "Using custom install directory: $uvInstallDir"
}
elseif ($SystemWide -or $useAlternativeLocation) {
    # Use C:\uv for system-wide or when user profile has issues
    $uvInstallDir = "C:\uv"
    Write-Info "Using system-wide location: $uvInstallDir (avoids user profile issues)"
}
else {
    # Default location
    $uvInstallDir = Join-Path $env:LOCALAPPDATA "uv\bin"
    Write-Info "Using default location: $uvInstallDir"
}

$uvExe = Join-Path $uvInstallDir "uv.exe"

# --- Check Existing Installation ---

Write-Step "Checking for existing uv installation..."

$existingUv = Get-Command uv -ErrorAction SilentlyContinue

if ($existingUv -and -not $Force) {
    Write-Success "uv is already installed at: $($existingUv.Source)"
    Write-Host "`nCurrent uv version:" -ForegroundColor Magenta
    & uv --version
    
    Write-Host "`nTo reinstall, run with -Force flag" -ForegroundColor Yellow
    
    # Set actualUvDir for PATH verification below
    $actualUvDir = Split-Path $existingUv.Source -Parent
}
else {
    if ($Force -and $existingUv) {
        Write-Info "Force flag set, reinstalling..."
    }
    
    # --- Create Install Directory ---
    
    Write-Step "Creating install directory..."
    
    if (-not (Test-Path $uvInstallDir)) {
        try {
            New-Item -ItemType Directory -Path $uvInstallDir -Force | Out-Null
            Write-Success "Created directory: $uvInstallDir"
        }
        catch {
            Write-Fail "Could not create directory: $_"
            Write-Host "`nTry running as Administrator or use a different install location" -ForegroundColor Yellow
            exit 1
        }
    }
    else {
        Write-Info "Directory exists: $uvInstallDir"
    }
    
    # --- Download and Install uv ---
    
    Write-Step "Downloading uv..."
    
    # Determine if we need custom location (system-wide or non-ASCII path)
    $useCustomLocation = $SystemWide -or $useAlternativeLocation -or $InstallDir
    
    if (-not $useCustomLocation) {
        # Use official installer for default location
        try {
            $installerUrl = "https://astral.sh/uv/install.ps1"
            $installerScript = (Invoke-WebRequest -Uri $installerUrl -UseBasicParsing).Content
            Invoke-Expression $installerScript
            Write-Success "uv installed via official installer"
        }
        catch {
            Write-Fail "Official installer failed: $_"
            $useCustomLocation = $true  # Fall back to direct download
        }
    }
    
    if ($useCustomLocation) {
        # Direct download for custom locations (official installer doesn't support custom paths)
        Write-Info "Using direct download for custom install location..."
        
        try {
            # Detect architecture including ARM64
            $arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture) {
                "Arm64" { "aarch64" }
                "X64"   { "x86_64" }
                "X86"   { "i686" }
                default {
                    if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i686" }
                }
            }
            Write-Info "Detected architecture: $arch"
            # Get latest release URL from GitHub API
            $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/astral-sh/uv/releases/latest" -UseBasicParsing
            $asset = $releaseInfo.assets | Where-Object { $_.name -like "uv-$arch-pc-windows-msvc.zip" } | Select-Object -First 1
            
            if (-not $asset) {
                throw "Could not find Windows binary for architecture: $arch"
            }
            
            $downloadUrl = $asset.browser_download_url
            $zipPath = Join-Path $env:TEMP "uv-download.zip"
            
            Write-Info "Downloading from: $downloadUrl"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
            
            # Extract to install directory
            Expand-Archive -Path $zipPath -DestinationPath $uvInstallDir -Force
            Remove-Item $zipPath -Force
            
            # Check if uv.exe is in a subdirectory and move it up if needed
            $uvExeInSubdir = Get-ChildItem -Path $uvInstallDir -Recurse -Filter "uv.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($uvExeInSubdir -and $uvExeInSubdir.DirectoryName -ne $uvInstallDir) {
                try {
                    $sourceDir = $uvExeInSubdir.DirectoryName
                    Write-Info "Moving files from subdirectory: $sourceDir"
                    Get-ChildItem -Path $sourceDir -File | ForEach-Object {
                        Move-Item -Path $_.FullName -Destination $uvInstallDir -Force -ErrorAction Stop
                    }
                    # Clean up empty subdirectories
                    Get-ChildItem -Path $uvInstallDir -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Fail "Could not reorganize extracted files: $_"
                    Write-Info "uv.exe may be in a subdirectory - check $uvInstallDir"
                }
            }

            Write-Success "uv downloaded and extracted to $uvInstallDir"
        }
        catch {
            Write-Fail "Direct download failed: $_"
            Write-Host "  Please check your internet connection and try again" -ForegroundColor Yellow
            exit 1
        }
    }
}

# --- Update PATH ---

Write-Step "Updating PATH environment variable..."

# Find where uv.exe actually is (if not already known from existing installation)
if (-not $actualUvDir) {
    $possibleLocations = @(
        $uvInstallDir,
        (Join-Path $env:LOCALAPPDATA "uv\bin"),
        (Join-Path $env:LOCALAPPDATA "uv"),
        (Join-Path $env:USERPROFILE ".local\bin"),
        (Join-Path $env:USERPROFILE ".cargo\bin"),
        "C:\uv",
        "C:\uv\bin"
    )

    # Add CARGO_HOME if set
    if ($env:CARGO_HOME) {
        $possibleLocations += (Join-Path $env:CARGO_HOME "bin")
    }

    foreach ($loc in $possibleLocations) {
        $testPath = Join-Path $loc "uv.exe"
        if (Test-Path $testPath) {
            $actualUvDir = $loc
            Write-Info "Found uv.exe at: $testPath"
            break
        }
    }
}

if (-not $actualUvDir) {
    Write-Fail "Could not locate uv.exe after installation"
    Write-Host "Please check the installation manually" -ForegroundColor Yellow
    exit 1
}

# Add to User PATH (always)
Add-ToPath -Directory $actualUvDir -Scope "User"

# Add to Machine PATH if admin (makes it available to all users and terminals)
if (Test-IsAdmin) {
    Add-ToPath -Directory $actualUvDir -Scope "Machine"
    Write-Success "Added to System PATH (admin)"
} else {
    Write-Info "Not running as admin - only added to User PATH"
    Write-Host "  For best results, run this script as Administrator" -ForegroundColor Yellow
}

# Refresh PATH in current session
Refresh-PathInSession

# Also add to current session explicitly
if ($env:Path -notlike "*$actualUvDir*") {
    $env:Path = "$actualUvDir;$env:Path"
}

# --- Verification ---

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Step "Verifying uv is accessible..."

# Test 1: Direct path execution
Write-Info "Test 1: Direct path execution"
$directPath = Join-Path $actualUvDir "uv.exe"
if (Test-Path $directPath) {
    $version = & $directPath --version 2>&1
    Write-Success "Direct execution: $version"
} else {
    Write-Fail "uv.exe not found at $directPath"
}

# Test 2: PATH execution
Write-Info "Test 2: PATH execution (using 'uv' command)"
try {
    $uvCommand = Get-Command uv -ErrorAction Stop
    $version = & uv --version 2>&1
    Write-Success "PATH execution: $version"
    Write-Success "uv location: $($uvCommand.Source)"
} catch {
    Write-Fail "uv not found in PATH"
    Write-Host "  Current PATH entries containing 'uv':" -ForegroundColor Yellow
    $env:Path -split ';' | Where-Object { $_ -like '*uv*' } | ForEach-Object { Write-Host "    $_" }
}

# Test 3: Create test project and run uv sync
Write-Step "Testing uv sync functionality..."

$testDir = Join-Path $env:TEMP "uv-test-$(Get-Random)"
try {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    Push-Location $testDir
    
    Write-Info "Created test directory: $testDir"
    
    # Initialize project
    & uv init 2>&1 | Out-Null
    Write-Success "uv init succeeded"
    
    # Run sync
    $syncResult = & uv sync 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "uv sync succeeded"
    } else {
        Write-Fail "uv sync failed: $syncResult"
    }
    
    Pop-Location
    Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
}
catch {
    Write-Fail "Test failed: $_"
    Pop-Location -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $testDir -ErrorAction SilentlyContinue
}

# --- VS Code Specific Instructions ---

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  VS CODE TERMINAL FIX" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host @"
If uv still doesn't work in VS Code's terminal:

1. RESTART VS CODE COMPLETELY
   - Close all VS Code windows
   - Reopen VS Code
   - VS Code caches the PATH when it starts

2. If still not working, add this to VS Code settings.json:
   
   "terminal.integrated.env.windows": {
       "Path": "$actualUvDir;`${env:Path}"
   }

3. Or run this in VS Code's PowerShell terminal:
   
   `$env:Path = "$actualUvDir;`$env:Path"

4. NUCLEAR OPTION - Sign out and sign back into Windows
   This fully refreshes all environment variables

"@ -ForegroundColor White

# --- Create a batch file for easy PATH fix ---

$batchContent = @"
@echo off
REM Quick fix for uv PATH issues - run this in any terminal
set PATH=$actualUvDir;%PATH%
echo PATH updated. uv should now work.
uv --version
"@

$batchFile = Join-Path $actualUvDir "fix-uv-path.bat"
try {
    $batchContent | Out-File -FilePath $batchFile -Encoding ASCII -Force
    Write-Info "Created quick-fix batch file: $batchFile"
    Write-Host "  Run 'fix-uv-path' in any terminal if uv stops working" -ForegroundColor White
} catch {
    Write-Info "Could not create batch file (non-critical)"
}

# --- Summary ---

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "uv install directory: " -NoNewline
Write-Host $actualUvDir -ForegroundColor Green

Write-Host "uv executable: " -NoNewline
Write-Host (Join-Path $actualUvDir "uv.exe") -ForegroundColor Green

Write-Host "`nTo use uv from any location:" -ForegroundColor Magenta
Write-Host "  1. Open a NEW terminal window (or restart VS Code)"
Write-Host "  2. Run: uv --version"
Write-Host "  3. In your project folder, run: uv sync"

Write-Host "`nIf problems persist, run as Administrator:" -ForegroundColor Yellow
Write-Host "  powershell -ExecutionPolicy Bypass -File install-uv-windows.ps1 -SystemWide" -ForegroundColor White

# --- Setup Auto-Venv Activation ---

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  AUTO-VENV ACTIVATION SETUP" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Step "Setting up automatic venv activation..."

$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir = Split-Path $profilePath -Parent

# Create profile directory if it doesn't exist
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Info "Created profile directory: $profileDir"
}

# Define the auto-venv activation function
$autoVenvCode = @'

# --- Auto-activate .venv when entering directory (added by uv installer) ---
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

# Override cd and Set-Location to use our function
Set-Alias -Name cd -Value Set-LocationWithVenv -Option AllScope -Scope Global -Force
Set-Alias -Name Set-Location -Value Set-LocationWithVenv -Option AllScope -Scope Global -Force

# Also check on profile load (for when terminal opens in a project directory)
$venvActivate = Join-Path $PWD ".venv\Scripts\Activate.ps1"
if (Test-Path $venvActivate) {
    & $venvActivate
    Write-Host "[venv] Activated .venv" -ForegroundColor Green
}
# --- End auto-venv activation ---
'@

# Check if already added to profile
$profileExists = Test-Path $profilePath
$alreadyAdded = $false

if ($profileExists) {
    $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($profileContent -and $profileContent -match "Auto-activate \.venv when entering directory") {
        $alreadyAdded = $true
    }
}

if ($alreadyAdded) {
    Write-Info "Auto-venv activation already configured in PowerShell profile"
} else {
    try {
        # Append to profile (create if doesn't exist)
        Add-Content -Path $profilePath -Value $autoVenvCode -Force
        Write-Success "Added auto-venv activation to PowerShell profile"
        Write-Info "Profile location: $profilePath"
        Write-Host @"

  Auto-venv activation is now enabled!
  When you 'cd' into a directory with a .venv folder,
  the virtual environment will be activated automatically.

"@ -ForegroundColor White
    } catch {
        Write-Fail "Could not update PowerShell profile: $_"
        Write-Host "  You can manually add auto-venv by editing: $profilePath" -ForegroundColor Yellow
    }
}

Write-Host "`n"
