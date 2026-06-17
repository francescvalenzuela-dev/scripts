import os
import shutil
from datetime import datetime
from PIL import Image
from PIL.ExifTags import TAGS
import sys
import argparse
import re

# Tipos de archivos soportados
EXTENSIONES_PERMITIDAS = ('.jpg', '.jpeg', '.png', '.tiff', '.bmp', '.gif')

# Expresiones regulares para identificar carpetas YYYYMM y YYYYMMDD
PATTERN_YEARMONTH = re.compile(r'^\d{6}$')       # YYYYMM
PATTERN_YEARDAY = re.compile(r'^\d{8}$')         # YYYYMMDD

# Expresión regular para extraer fecha YYYYMMDD del nombre del archivo
PATTERN_FECHA_NOMBRE = re.compile(r'(\d{4})(\d{2})(\d{2})')

# Fecha por defecto a evitar
FECHA_POR_DEFECTO = datetime(1980, 1, 1)

def obtener_fecha_exif(ruta_imagen):
    """
    Extrae la fecha de captura de una imagen utilizando los metadatos EXIF.
    Si no se encuentra la fecha EXIF, devuelve None.
    """
    try:
        imagen = Image.open(ruta_imagen)
        exif_data = imagen._getexif()
        if exif_data is not None:
            for tag_id, value in exif_data.items():
                tag = TAGS.get(tag_id, tag_id)
                if tag == 'DateTimeOriginal':
                    # Formato EXIF: 'YYYY:MM:DD HH:MM:SS'
                    fecha = datetime.strptime(value, '%Y:%m:%d %H:%M:%S')
                    return fecha
    except Exception as e:
        print(f"[EXIF Error] Al leer EXIF de {ruta_imagen}: {e}")
    return None

def obtener_fecha_archivo(ruta_imagen):
    """
    Obtiene la fecha de modificación del archivo como respaldo si no se encuentra la fecha EXIF.
    Verifica que la fecha no sea la por defecto.
    """
    try:
        timestamp = os.path.getmtime(ruta_imagen)
        fecha = datetime.fromtimestamp(timestamp)
        if fecha != FECHA_POR_DEFECTO:
            return fecha
        else:
            print(f"[Fecha Archivo] Fecha de modificación de {ruta_imagen} es la fecha por defecto {FECHA_POR_DEFECTO}.")
            return None
    except Exception as e:
        print(f"[Fecha Archivo Error] Al obtener fecha de archivo para {ruta_imagen}: {e}")
        return None

def extraer_fecha_desde_nombre(ruta_imagen):
    """
    Intenta extraer la fecha del nombre del archivo en formato YYYYMMDD.
    Retorna un objeto datetime si tiene éxito, de lo contrario, None.
    """
    nombre_archivo = os.path.basename(ruta_imagen)
    # Buscar todas las coincidencias de 8 dígitos consecutivos
    matches = PATTERN_FECHA_NOMBRE.findall(nombre_archivo)
    for match in matches:
        try:
            año, mes, dia = match
            fecha = datetime(int(año), int(mes), int(dia))
            # Verificar que la fecha no sea la por defecto
            if fecha != FECHA_POR_DEFECTO:
                return fecha
            else:
                print(f"[Fecha Nombre] Fecha extraída de nombre de archivo {ruta_imagen} es la fecha por defecto {FECHA_POR_DEFECTO}.")
        except ValueError as ve:
            print(f"[Fecha Nombre Error] Fecha inválida en el nombre del archivo {ruta_imagen}: {ve}")
            continue
    return None

def crear_carpeta_destino(origen, fecha):
    """
    Crea la ruta de las carpetas destino basadas en la fecha (YYYYMM/YYYYMMDD) dentro de la carpeta de origen.
    """
    nombre_carpeta_mes = fecha.strftime('%Y%m')
    ruta_carpeta_mes = os.path.join(origen, nombre_carpeta_mes)
    if not os.path.exists(ruta_carpeta_mes):
        os.makedirs(ruta_carpeta_mes)
    
    nombre_carpeta_dia = fecha.strftime('%Y%m%d')
    ruta_carpeta_dia = os.path.join(ruta_carpeta_mes, nombre_carpeta_dia)
    if not os.path.exists(ruta_carpeta_dia):
        os.makedirs(ruta_carpeta_dia)
    
    return ruta_carpeta_dia

def es_carpeta_destino(nombre_carpeta):
    """
    Verifica si una carpeta sigue el formato YYYYMM o YYYYMMDD.
    """
    return PATTERN_YEARMONTH.match(nombre_carpeta) or PATTERN_YEARDAY.match(nombre_carpeta)

def organizar_fotos(origen):
    """
    Recorre la carpeta de origen, organiza las fotos en carpetas por mes y día, y las mueve a las carpetas destino.
    """
    if not os.path.exists(origen):
        print(f"[Error] La carpeta de origen '{origen}' no existe.")
        sys.exit(1)

    for root, dirs, files in os.walk(origen):
        # Obtener la ruta relativa respecto a la carpeta de origen
        rel_path = os.path.relpath(root, origen)
        if rel_path == ".":
            rel_path = ""
        else:
            # Si la carpeta actual es una carpeta de destino (YYYYMM o YYYYMMDD), saltarla
            nombre_carpeta_actual = os.path.basename(root)
            if es_carpeta_destino(nombre_carpeta_actual):
                dirs[:] = []  # No recorrer subdirectorios
                continue

        for file in files:
            if file.lower().endswith(EXTENSIONES_PERMITIDAS):
                ruta_imagen = os.path.join(root, file)
                # Obtener fecha de EXIF
                fecha = obtener_fecha_exif(ruta_imagen)
                if fecha is None:
                    # Si no hay EXIF, usar la fecha de modificación del archivo
                    fecha = obtener_fecha_archivo(ruta_imagen)
                if fecha is None:
                    # Si aún no se obtuvo la fecha, intentar extraerla del nombre del archivo
                    fecha = extraer_fecha_desde_nombre(ruta_imagen)
                if fecha is None:
                    print(f"[Omitido] No se pudo obtener una fecha válida para {ruta_imagen}. La foto será omitida.")
                    continue
                # Crear carpetas destino
                ruta_carpeta_destino = crear_carpeta_destino(origen, fecha)
                # Definir ruta final
                ruta_final = os.path.join(ruta_carpeta_destino, file)

                # Manejar posibles conflictos de nombres
                contador = 1
                archivo_original = file
                while os.path.exists(ruta_final):
                    nombre, extension = os.path.splitext(archivo_original)
                    nuevo_nombre = f"{nombre}_{contador}{extension}"
                    ruta_final = os.path.join(ruta_carpeta_destino, nuevo_nombre)
                    contador += 1

                try:
                    shutil.move(ruta_imagen, ruta_final)
                    print(f"[Movido] {ruta_imagen} --> {ruta_final}")
                except Exception as e:
                    print(f"[Error] Al mover {ruta_imagen}: {e}")

def main():
    # Configurar el analizador de argumentos
    parser = argparse.ArgumentParser(description='Organizar fotos por mes (YYYYMM) y día (YYYYMMDD) de captura.')
    parser.add_argument('origen', help='Ruta de la carpeta de origen de las fotos')

    args = parser.parse_args()
    carpeta_origen = args.origen

    organizar_fotos(carpeta_origen)
    print("[Completado] Organización completada.")

if __name__ == "__main__":
    main()
