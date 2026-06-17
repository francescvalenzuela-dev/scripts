"""
Organize photos into YYYYMM/YYYYMMDD folders based on capture date.

What it does:
  Walks a source folder and moves each image into a date-based subfolder:
    source/202403/20240315/photo.jpg

  Date resolution order:
    1. EXIF DateTimeOriginal metadata
    2. File modification date
    3. YYYYMMDD pattern found in the file name

  Supported formats: JPG, JPEG, PNG, TIFF, BMP, GIF
  Name collisions are resolved by appending _1, _2, etc.
  Existing YYYYMM/YYYYMMDD folders are skipped during the walk.

Usage:
  python photos/photos_in_folders.py "C:\\path\\to\\your\\photos"

Requirements:
  Python 3, Pillow (pip install Pillow)
"""

import os
import shutil
from datetime import datetime
from PIL import Image
from PIL.ExifTags import TAGS
import sys
import argparse
import re

ALLOWED_EXTENSIONS = ('.jpg', '.jpeg', '.png', '.tiff', '.bmp', '.gif')

PATTERN_YEARMONTH = re.compile(r'^\d{6}$')       # YYYYMM
PATTERN_YEARDAY = re.compile(r'^\d{8}$')         # YYYYMMDD

PATTERN_DATE_IN_NAME = re.compile(r'(\d{4})(\d{2})(\d{2})')

DEFAULT_DATE = datetime(1980, 1, 1)

def get_exif_date(image_path):
    """
    Extract the capture date from image EXIF metadata.
    Returns None if no EXIF date is found.
    """
    try:
        image = Image.open(image_path)
        exif_data = image._getexif()
        if exif_data is not None:
            for tag_id, value in exif_data.items():
                tag = TAGS.get(tag_id, tag_id)
                if tag == 'DateTimeOriginal':
                    # EXIF format: 'YYYY:MM:DD HH:MM:SS'
                    date = datetime.strptime(value, '%Y:%m:%d %H:%M:%S')
                    return date
    except Exception as e:
        print(f"[EXIF Error] Failed to read EXIF from {image_path}: {e}")
    return None

def get_file_date(image_path):
    """
    Use the file modification date as a fallback when EXIF date is unavailable.
    Returns None if the date matches the default placeholder date.
    """
    try:
        timestamp = os.path.getmtime(image_path)
        date = datetime.fromtimestamp(timestamp)
        if date != DEFAULT_DATE:
            return date
        else:
            print(f"[File Date] Modification date of {image_path} is the default date {DEFAULT_DATE}.")
            return None
    except Exception as e:
        print(f"[File Date Error] Failed to get file date for {image_path}: {e}")
        return None

def extract_date_from_name(image_path):
    """
    Try to extract a YYYYMMDD date from the file name.
    Returns a datetime object on success, otherwise None.
    """
    file_name = os.path.basename(image_path)
    matches = PATTERN_DATE_IN_NAME.findall(file_name)
    for match in matches:
        try:
            year, month, day = match
            date = datetime(int(year), int(month), int(day))
            if date != DEFAULT_DATE:
                return date
            else:
                print(f"[Name Date] Date extracted from file name {image_path} is the default date {DEFAULT_DATE}.")
        except ValueError as ve:
            print(f"[Name Date Error] Invalid date in file name {image_path}: {ve}")
            continue
    return None

def create_destination_folder(source, date):
    """
    Create destination folders based on date (YYYYMM/YYYYMMDD) inside the source folder.
    """
    month_folder_name = date.strftime('%Y%m')
    month_folder_path = os.path.join(source, month_folder_name)
    if not os.path.exists(month_folder_path):
        os.makedirs(month_folder_path)
    
    day_folder_name = date.strftime('%Y%m%d')
    day_folder_path = os.path.join(month_folder_path, day_folder_name)
    if not os.path.exists(day_folder_path):
        os.makedirs(day_folder_path)
    
    return day_folder_path

def is_destination_folder(folder_name):
    """
    Check whether a folder name matches the YYYYMM or YYYYMMDD format.
    """
    return PATTERN_YEARMONTH.match(folder_name) or PATTERN_YEARDAY.match(folder_name)

def organize_photos(source):
    """
    Walk the source folder, organize photos by month and day, and move them to destination folders.
    """
    if not os.path.exists(source):
        print(f"[Error] Source folder '{source}' does not exist.")
        sys.exit(1)

    for root, dirs, files in os.walk(source):
        rel_path = os.path.relpath(root, source)
        if rel_path == ".":
            rel_path = ""
        else:
            current_folder_name = os.path.basename(root)
            if is_destination_folder(current_folder_name):
                dirs[:] = []
                continue

        for file in files:
            if file.lower().endswith(ALLOWED_EXTENSIONS):
                image_path = os.path.join(root, file)
                date = get_exif_date(image_path)
                if date is None:
                    date = get_file_date(image_path)
                if date is None:
                    date = extract_date_from_name(image_path)
                if date is None:
                    print(f"[Skipped] Could not determine a valid date for {image_path}. Photo will be skipped.")
                    continue
                destination_folder = create_destination_folder(source, date)
                final_path = os.path.join(destination_folder, file)

                counter = 1
                original_file = file
                while os.path.exists(final_path):
                    name, extension = os.path.splitext(original_file)
                    new_name = f"{name}_{counter}{extension}"
                    final_path = os.path.join(destination_folder, new_name)
                    counter += 1

                try:
                    shutil.move(image_path, final_path)
                    print(f"[Moved] {image_path} --> {final_path}")
                except Exception as e:
                    print(f"[Error] Failed to move {image_path}: {e}")

def main():
    parser = argparse.ArgumentParser(description='Organize photos by capture month (YYYYMM) and day (YYYYMMDD).')
    parser.add_argument('source', help='Path to the source folder containing photos')

    args = parser.parse_args()
    source_folder = args.source

    organize_photos(source_folder)
    print("[Done] Organization complete.")

if __name__ == "__main__":
    main()
