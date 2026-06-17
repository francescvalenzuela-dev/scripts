# Configurar título de la ventana y limpiar pantalla
$Host.UI.RawUI.WindowTitle = "Limpieza Segura de Docker"
Clear-Host

Write-Host "========================================================"
Write-Host "   LIMPIEZA DE RECURSOS HUÉRFANOS DE DOCKER"
Write-Host "   (Se conservan contenedores detenidos y sus datos)"
Write-Host "========================================================"
Write-Host ""

# 1. Eliminar imágenes "dangling" (colgantes)
# Estas son capas de imágenes que no tienen nombre (tag <none>) 
# y no son usadas por ningún contenedor (ni encendido ni apagado).
Write-Host "[1/4] Eliminando imágenes huérfanas (dangling)..."
docker image prune --force

# 2. Eliminar redes no usadas
# Borra redes que no están conectadas a NINGÚN contenedor.
Write-Host ""
Write-Host "[2/4] Eliminando redes no utilizadas..."
docker network prune --force

# 3. Eliminar volúmenes no usados (Opcional - seguro si está huérfano)
# Solo borra volúmenes que no estén montados en ningún contenedor.
# Si un contenedor detenido usa un volumen, este NO se borrará.
Write-Host ""
Write-Host "[3/4] Eliminando volúmenes huérfanos..."
docker volume prune --force

# 4. Eliminar caché de construcción
# Libera espacio de compilaciones anteriores.
Write-Host ""
Write-Host "[4/4] Limpiando caché del builder..."
docker builder prune --force

Write-Host ""
Write-Host "========================================================"
Write-Host "   LIMPIEZA COMPLETADA"
Write-Host "========================================================"

# Pausar la ejecución para ver el resultado
Read-Host -Prompt "Presiona Enter para salir"