@echo off
rem ============================================================================
rem  Safe Docker Cleanup
rem
rem  Removes orphaned Docker resources to free disk space without touching
rem  stopped containers or their data:
rem    1. Dangling images   - docker image prune
rem    2. Unused networks   - docker network prune
rem    3. Orphaned volumes  - docker volume prune
rem    4. Builder cache     - docker builder prune
rem
rem  Usage:  cleanup\clean-docker.cmd
rem  Requires: Docker
rem  PowerShell equivalent: cleanup\clean-docker.ps1
rem ============================================================================

title Safe Docker Cleanup
cls

echo ========================================================
echo   DOCKER ORPHANED RESOURCE CLEANUP
echo   (Stopped containers and their data are preserved)
echo ========================================================
echo.

:: 1. Remove dangling images
:: These are image layers with no name (tag <none>)
:: and not used by any container (running or stopped).
echo [1/4] Removing orphaned images (dangling)...
docker image prune --force

:: 2. Remove unused networks
:: Deletes networks not connected to ANY container.
echo.
echo [2/4] Removing unused networks...
docker network prune --force

:: 3. Remove unused volumes (safe when orphaned)
:: Only deletes volumes not mounted by any container.
:: If a stopped container uses a volume, it will NOT be deleted.
echo.
echo [3/4] Removing orphaned volumes...
docker volume prune --force

:: 4. Remove build cache
:: Frees space from previous builds.
echo.
echo [4/4] Cleaning builder cache...
docker builder prune --force

echo.
echo ========================================================
echo   CLEANUP COMPLETE
echo ========================================================
pause
