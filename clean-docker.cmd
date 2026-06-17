@echo off
title Limpieza Segura de Docker
cls

echo ========================================================
echo   LIMPIEZA DE RECURSOS HUERFANOS DE DOCKER
echo   (Se conservan contenedores detenidos y sus datos)
echo ========================================================
echo.

:: 1. Eliminar im genes "dangling" (colgantes)
:: Estas son capas de im genes que no tienen nombre (tag <none>) 
:: y no son usadas por ning£n contenedor (ni encendido ni apagado).
echo [1/4] Eliminando imagenes huerfanas (dangling)...
docker image prune --force

:: 2. Eliminar redes no usadas
:: Borra redes que no est n conectadas a NINGéN contenedor.
echo.
echo [2/4] Eliminando redes no utilizadas...
docker network prune --force

:: 3. Eliminar vol£menes no usados (Opcional - seguro si est  hu‚rfano)
:: Solo borra vol£menes que no est n montados en ning£n contenedor.
:: Si un contenedor detenido usa un volumen, este NO se borrar .
echo.
echo [3/4] Eliminando volumenes huerfanos...
docker volume prune --force

:: 4. Eliminar cach‚ de construcci¢n
:: Libera espacio de compilaciones anteriores.
echo.
echo [4/4] Limpiando cache del builder...
docker builder prune --force

echo.
echo ========================================================
echo   LIMPIEZA COMPLETADA
echo ========================================================
pause
