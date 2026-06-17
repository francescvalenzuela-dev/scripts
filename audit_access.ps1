<#
.SYNOPSIS
    Auditoria de colaboradores con enlaces directos a la gestion de miembros.
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$RutaBase = (Get-Location).Path
)

# --- Verificacion de Autenticacion ---
Write-Host "--- CONFIGURANDO ACCESO ---" -ForegroundColor Cyan
$usuarioActivo = gh api user --jq '.login' 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "No hay sesion. Iniciando login..." -ForegroundColor Yellow
    gh auth login --hostname github.com --web --scopes "repo,read:org"
    $usuarioActivo = gh api user --jq '.login'
}
Write-Host "Conectado como: $usuarioActivo" -ForegroundColor Green

function Get-GitPermissions {
    param (
        [string]$Ruta,
        [string]$NombreVisual
    )

    Push-Location -Path $Ruta
    
    try {
        $remoteUrl = (git remote get-url origin 2>$null)
        if ($null -eq $remoteUrl) { return }
        
        if ($remoteUrl.Trim() -match "github\.com[:/]([^/]+)/([^/.]+)") {
            $owner = $Matches[1]
            $repo = $Matches[2].Replace(".git", "").Trim()

            # Mostramos la URL de settings directamente
            Write-Host "`n[REPO] https://github.com/$owner/$repo/settings/access" -ForegroundColor Cyan

            # Preparamos la llamada a la API
            $fullPath = "repos/$owner/$repo/collaborators"
            $env:GH_AUDIT_PATH = $fullPath
            
            # Ejecucion via CMD para evitar errores de parseo de PS
            $resultado = cmd /c "gh api %GH_AUDIT_PATH% --header ""Accept: application/vnd.github+json"" --jq "".[] | \""\(.login) [\(.role_name)]\""""" 2>&1

            if ($lastExitCode -eq 0) {
                if ($resultado) {
                    $resultado | ForEach-Object {
                        $line = $_.ToString()
                        $color = if ($line -like "*[admin]*") { "Yellow" } else { "White" }
                        Write-Host "   [ ] $line" -ForegroundColor $color
                    }
                } else {
                    Write-Host "   [INFO] Sin colaboradores directos." -ForegroundColor Gray
                }
            } else {
                Write-Host "   [AVISO] Error de acceso (Posible falta de permisos Admin o SSO)" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "   [ERROR] Excepcion inesperada en $NombreVisual" -ForegroundColor Red
    }
    finally {
        Pop-Location
        Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    }
}

# --- Inicio del Escaneo ---
if (-not (Test-Path -Path $RutaBase)) {
    Write-Host "Error: La ruta '$RutaBase' no existe." -ForegroundColor Red
    exit
}

Write-Host "`n--- ESCANEANDO EN: $RutaBase ---" -ForegroundColor Magenta

$items = Get-ChildItem -Path $RutaBase -Directory
foreach ($item in $items) {
    if (Test-Path "$($item.FullName)\.git") {
        Get-GitPermissions -Ruta $item.FullName -NombreVisual $item.Name
    } else {
        $subs = Get-ChildItem -Path $item.FullName -Directory
        foreach ($sub in $subs) {
            if (Test-Path "$($sub.FullName)\.git") {
                Get-GitPermissions -Ruta $sub.FullName -NombreVisual "$($item.Name)/$($sub.Name)"
            }
        }
    }
}

Write-Host "`n--- Auditoria finalizada ---" -ForegroundColor Magenta