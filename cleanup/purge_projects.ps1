<#
.SYNOPSIS
    Deletes dependencies and build artifacts from development projects.

.DESCRIPTION
    Recursively searches the directory tree from the current working directory for
    project indicator files (package.json, artisan, requirements.txt).

    For each project found, deletes:
      node_modules, vendor, venv, .venv, .next, dist, __pycache__

    For Laravel projects (with artisan and vendor), also runs:
      php artisan optimize:clear

    Uses robocopy to handle long paths reliably during deletion.

.EXAMPLE
    cd C:\Source2
    ..\scripts\cleanup\purge_projects.ps1

.NOTES
    Requirements: PHP (Laravel projects only)
    IMPORTANT: Run from the root of the projects you want to clean.
               The search scope is the entire subtree below the current directory.
    pnpm internal folders (.pnpm) are skipped.
#>

# Fixed temp folder to avoid null variable errors
$tempPath = Join-Path $env:TEMP "purge_temp_dir"
if (-not (Test-Path $tempPath)) { New-Item -ItemType Directory -Path $tempPath -Force | Out-Null }

$targets = @("node_modules", "vendor", "venv", ".venv", ".next", "dist", "__pycache__")

Write-Host "Starting project cleanup..." -ForegroundColor Cyan

# Robust search via CMD
$projectFiles = cmd /c "dir /s /b package.json artisan requirements.txt 2>nul"

if ($projectFiles) {
    foreach ($file in $projectFiles) {
        if ([string]::IsNullOrWhiteSpace($file)) { continue }
        
        $projectRoot = [System.IO.Path]::GetDirectoryName($file)
        
        # Skip duplicates
        if ($lastRoot -eq $projectRoot) { continue }
        $lastRoot = $projectRoot

        # --- LARAVEL SECTION ---
        if ((Test-Path "$projectRoot\artisan") -and (Test-Path "$projectRoot\vendor")) {
            Write-Host "`nLARAVEL PROJECT: $projectRoot" -ForegroundColor Magenta
            try {
                Push-Location $projectRoot
                & php artisan optimize:clear 2>$null | Out-Null
                Pop-Location
                Write-Host "  [OK] Cache cleared" -ForegroundColor Gray
            } catch {}
        }

        # --- PHYSICAL DELETION SECTION ---
        foreach ($target in $targets) {
            $fullTargetPath = Join-Path $projectRoot $target
            
            # Skip pnpm internals
            if ($fullTargetPath -like "*\.pnpm\*") { continue }

            if (Test-Path -LiteralPath $fullTargetPath) {
                Write-Host "DELETING: $fullTargetPath" -ForegroundColor Yellow
                
                # Robocopy is the most reliable method for long paths
                & robocopy $tempPath $fullTargetPath /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
                Remove-Item -LiteralPath $fullTargetPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Final cleanup of the staging folder
if (Test-Path $tempPath) { Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue }

Write-Host "`n---------------------------------------"
Write-Host "Cleanup finished successfully." -ForegroundColor Green
