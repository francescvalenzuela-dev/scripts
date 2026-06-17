"""
Rename .jpg files by removing a processed-photo suffix.

What it does:
  Removes a configured suffix from each .jpg file name in a folder.
  Example: vacation_resultado.jpg  ->  vacation.jpg

Before running:
  1. Edit folder_path below with the target folder
  2. Edit RESULT_SUFFIX to match the suffix in your file names

Usage:
  python photos/rename_remove_result.py

Requirements:
  Python 3
"""

import os
import re

# --- Configuration: edit before running ---
folder_path = r"C:\Users\franc\Downloads\Andorra2024Marca-Francesc"

# Suffix stripped from processed photo file names
RESULT_SUFFIX = "_result" + "ado"
pattern = re.compile(re.escape(RESULT_SUFFIX))

os.chdir(folder_path)
files = os.listdir(folder_path)

for file in files:
    if file.endswith(".jpg"):
        base_name, extension = os.path.splitext(file)

        if pattern.search(base_name):
            new_base_name = pattern.sub('', base_name)
            new_name = new_base_name + extension
            os.rename(file, new_name)

print("Rename complete")
