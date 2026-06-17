"""
Rename .jpg files by removing an unwanted suffix from file names.

What it does:
  Removes the part of each .jpg file name matching the pattern _<number>_...
  Example: photo_123_extra_info.jpg  ->  photo.jpg

  Useful for cleaning suffixes added by download or processing tools.

Before running:
  1. Edit folder_path below with the target folder
  2. Adjust the pattern regex if your suffix format differs

Usage:
  python photos/rename.py

Requirements:
  Python 3
"""

import os
import re

# --- Configuration: edit before running ---
folder_path = r"C:\Users\franc\Downloads\Madrid2018Marca"

# Pattern to find and remove the unwanted part of the file name
pattern = re.compile(r"(_\d+_.*)")

os.chdir(folder_path)
files = os.listdir(folder_path)

for file in files:
    if file.endswith(".jpg"):
        base_name, extension = os.path.splitext(file)
        new_name = re.sub(pattern, '', base_name) + extension
        os.rename(file, new_name)

print("Rename complete")
