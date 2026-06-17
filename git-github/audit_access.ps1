<#
.SYNOPSIS
    Audits collaborators on GitHub-hosted Git repositories.

.DESCRIPTION
    Scans the same folder structure as update_repos.ps1 (first- and second-level folders).
    For each repository with a GitHub origin remote, it:
      - Prints a direct link to the repository access settings page
      - Lists direct collaborators and their role (admin, write, etc.) via the GitHub CLI API

    If no active gh session is found, starts an interactive login automatically.

.PARAMETER BasePath
    Full path to the root folder containing your projects.
    Defaults to the current directory if omitted.

.EXAMPLE
    .\git-github\audit_access.ps1 -BasePath "C:\Source2"

.EXAMPLE
    .\git-github\audit_access.ps1
    # Uses the current directory as BasePath

.NOTES
    Requirements: Git, GitHub CLI (gh) - https://cli.github.com/
    Admin access may be required to list collaborators on some repositories.
    SSO authorization errors are reported per repository.
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$BasePath = (Get-Location).Path
)

# --- Authentication check ---
Write-Host "--- CONFIGURING ACCESS ---" -ForegroundColor Cyan
$activeUser = gh api user --jq '.login' 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "No active session. Starting login..." -ForegroundColor Yellow
    gh auth login --hostname github.com --web --scopes "repo,read:org"
    $activeUser = gh api user --jq '.login'
}
Write-Host "Connected as: $activeUser" -ForegroundColor Green

function Get-GitPermissions {
    param (
        [string]$Path,
        [string]$DisplayName
    )

    Push-Location -Path $Path
    
    try {
        $remoteUrl = (git remote get-url origin 2>$null)
        if ($null -eq $remoteUrl) { return }
        
        if ($remoteUrl.Trim() -match "github\.com[:/]([^/]+)/([^/.]+)") {
            $owner = $Matches[1]
            $repo = $Matches[2].Replace(".git", "").Trim()

            Write-Host "`n[REPO] https://github.com/$owner/$repo/settings/access" -ForegroundColor Cyan

            $fullPath = "repos/$owner/$repo/collaborators"
            $env:GH_AUDIT_PATH = $fullPath
            
            # Run via CMD to avoid PowerShell parsing errors
            $result = cmd /c "gh api %GH_AUDIT_PATH% --header ""Accept: application/vnd.github+json"" --jq "".[] | \""\(.login) [\(.role_name)]\""""" 2>&1

            if ($lastExitCode -eq 0) {
                if ($result) {
                    $result | ForEach-Object {
                        $line = $_.ToString()
                        $color = if ($line -like "*[admin]*") { "Yellow" } else { "White" }
                        Write-Host "   [ ] $line" -ForegroundColor $color
                    }
                } else {
                    Write-Host "   [INFO] No direct collaborators." -ForegroundColor Gray
                }
            } else {
                Write-Host "   [WARNING] Access error (possible missing Admin permissions or SSO)" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "   [ERROR] Unexpected exception in $DisplayName" -ForegroundColor Red
    }
    finally {
        Pop-Location
        Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    }
}

# --- Scan start ---
if (-not (Test-Path -Path $BasePath)) {
    Write-Host "Error: Path '$BasePath' does not exist." -ForegroundColor Red
    exit
}

Write-Host "`n--- SCANNING: $BasePath ---" -ForegroundColor Magenta

$items = Get-ChildItem -Path $BasePath -Directory
foreach ($item in $items) {
    if (Test-Path "$($item.FullName)\.git") {
        Get-GitPermissions -Path $item.FullName -DisplayName $item.Name
    } else {
        $subs = Get-ChildItem -Path $item.FullName -Directory
        foreach ($sub in $subs) {
            if (Test-Path "$($sub.FullName)\.git") {
                Get-GitPermissions -Path $sub.FullName -DisplayName "$($item.Name)/$($sub.Name)"
            }
        }
    }
}

Write-Host "`n--- Audit complete ---" -ForegroundColor Magenta
