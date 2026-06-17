<#
.SYNOPSIS
    Safely removes orphaned Docker resources to free disk space.

.DESCRIPTION
    Runs four cleanup steps without touching stopped containers or their data:
      1. Dangling images     - docker image prune
      2. Unused networks     - docker network prune
      3. Orphaned volumes    - docker volume prune  (volumes used by stopped containers are kept)
      4. Builder cache       - docker builder prune

    A CMD equivalent is available: cleanup\clean-docker.cmd

.EXAMPLE
    .\cleanup\clean-docker.ps1

.NOTES
    Requirements: Docker
    Safe to run regularly. Stopped containers and their mounted volumes are preserved.
#>

$Host.UI.RawUI.WindowTitle = "Safe Docker Cleanup"
Clear-Host

Write-Host "========================================================"
Write-Host "   DOCKER ORPHANED RESOURCE CLEANUP"
Write-Host "   (Stopped containers and their data are preserved)"
Write-Host "========================================================"
Write-Host ""

# 1. Remove dangling images
# These are image layers with no name (tag <none>)
# and not used by any container (running or stopped).
Write-Host "[1/4] Removing orphaned images (dangling)..."
docker image prune --force

# 2. Remove unused networks
# Deletes networks not connected to ANY container.
Write-Host ""
Write-Host "[2/4] Removing unused networks..."
docker network prune --force

# 3. Remove unused volumes (safe when orphaned)
# Only deletes volumes not mounted by any container.
# If a stopped container uses a volume, it will NOT be deleted.
Write-Host ""
Write-Host "[3/4] Removing orphaned volumes..."
docker volume prune --force

# 4. Remove build cache
# Frees space from previous builds.
Write-Host ""
Write-Host "[4/4] Cleaning builder cache..."
docker builder prune --force

Write-Host ""
Write-Host "========================================================"
Write-Host "   CLEANUP COMPLETE"
Write-Host "========================================================"

Read-Host -Prompt "Press Enter to exit"
