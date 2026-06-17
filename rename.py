import os
import re

# Ruta a la carpeta que contiene los archivos
folder_path = r"C:\Users\franc\Downloads\Madrid2018Marca"

# Cambiar el directorio a la carpeta especificada
os.chdir(folder_path)

# Obtener la lista de archivos en la carpeta
files = os.listdir(folder_path)

# Patrón para buscar y eliminar la parte no deseada del nombre
pattern = re.compile(r"(_\d+_.*)")

for file in files:
    # Asegurarse de que sea un archivo jpg
    if file.endswith(".jpg"):
        # Obtener el nombre base y la extensión del archivo
        base_name, extension = os.path.splitext(file)

        # Renombrar eliminando la parte que coincide con el patrón
        new_name = re.sub(pattern, '', base_name) + extension

        # Renombrar el archivo
        os.rename(file, new_name)

print("Renombrado completado")
