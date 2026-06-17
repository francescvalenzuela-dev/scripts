import os
import re

# Ruta a la carpeta que contiene los archivos
folder_path = r"C:\Users\franc\Downloads\Andorra2024Marca-Francesc"

# Cambiar el directorio a la carpeta especificada
os.chdir(folder_path)

# Obtener la lista de archivos en la carpeta
files = os.listdir(folder_path)

# Patrón para buscar y eliminar la parte "_resultado" del nombre
pattern = re.compile(r"_resultado")

for file in files:
    # Asegurarse de que sea un archivo jpg
    if file.endswith(".jpg"):
        # Obtener el nombre base y la extensión del archivo
        base_name, extension = os.path.splitext(file)

        # Verificar si el patrón está presente en el nombre base
        if pattern.search(base_name):
            # Renombrar eliminando la parte que coincide con el patrón
            new_base_name = pattern.sub('', base_name)

            # Construir el nuevo nombre completo con la extensión
            new_name = new_base_name + extension

            # Renombrar el archivo
            os.rename(file, new_name)

print("Renombrado completado")
