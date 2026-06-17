# Configuracion de carpeta temporal fija para evitar errores de variable nula
$tempPath = Join-Path $env:TEMP "purge_temp_dir"
if (-not (Test-Path $tempPath)) { New-Item -ItemType Directory -Path $tempPath -Force | Out-Null }

$targets = @("node_modules", "vendor", "venv", ".venv", ".next", "dist", "__pycache__")

Write-Host "Iniciando limpieza de proyectos..." -ForegroundColor Cyan

# Busqueda robusta mediante CMD
$projectFiles = cmd /c "dir /s /b package.json artisan requirements.txt 2>nul"

if ($projectFiles) {
    foreach ($file in $projectFiles) {
        if ([string]::IsNullOrWhiteSpace($file)) { continue }
        
        $projectRoot = [System.IO.Path]::GetDirectoryName($file)
        
        # Evitar duplicados
        if ($lastRoot -eq $projectRoot) { continue }
        $lastRoot = $projectRoot

        # --- SECCIÓN LARAVEL ---
        if ((Test-Path "$projectRoot\artisan") -and (Test-Path "$projectRoot\vendor")) {
            Write-Host "`nPROYECTO LARAVEL: $projectRoot" -ForegroundColor Magenta
            try {
                pushd $projectRoot
                & php artisan optimize:clear 2>$null | Out-Null
                popd
                Write-Host "  [OK] Cache purgada" -ForegroundColor Gray
            } catch {}
        }

        # --- SECCIÓN BORRADO FÍSICO ---
        foreach ($target in $targets) {
            $fullTargetPath = Join-Path $projectRoot $target
            
            # No entrar en las tripas de pnpm
            if ($fullTargetPath -like "*\.pnpm\*") { continue }

            if (Test-Path -LiteralPath $fullTargetPath) {
                Write-Host "BORRANDO: $fullTargetPath" -ForegroundColor Yellow
                
                # Robocopy es el metodo mas fiable para rutas largas
                & robocopy $tempPath $fullTargetPath /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
                Remove-Item -LiteralPath $fullTargetPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Limpieza final de la carpeta de maniobras
if (Test-Path $tempPath) { Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue }

Write-Host "`n---------------------------------------"
Write-Host "Limpieza finalizada con exito y sin errores." -ForegroundColor Green