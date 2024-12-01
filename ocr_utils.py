from paddleocr import PaddleOCR
from PIL import Image, ImageOps
import io
from typing import List, Dict, Union
import numpy as np

# Initialize PaddleOCR once
ocr = PaddleOCR(use_angle_cls=True, lang='en')

def preprocess_image(image_data: bytes) -> Image.Image:
    """
    Preprocess the image by resizing, converting to grayscale, and centering.
    """
    image = Image.open(io.BytesIO(image_data))
    
    # Resize to a standard size (e.g., 1024x640) using LANCZOS for resampling
    standardized_size = (1024, 640)
    image = ImageOps.fit(image, standardized_size, Image.Resampling.LANCZOS)
    
    # Convert to grayscale
    image = image.convert("L")
    return image

def perform_ocr(image: Image.Image) -> list:
    """
    Perform OCR on the image and return bounding boxes with text.
    """
    image_np = np.array(image)
    result = ocr.ocr(image_np, cls=True)
    return result[0]  # Return only the detected text and bounding boxes

def define_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (NSW) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.05 * width, 0.12 * height, 0.4 * width, 0.2 * height),  # Example percentages
        "last_name": (0.05 * width, 0.2 * height, 0.9 * width, 0.3 * height),
        "address": (0.4 * width, 0.12 * height, 0.9 * width, 0.2 * height), 
        "license_number": (0.05 * width, 0.3 * height, 0.5 * width, 0.4 * height),
        "card_number": (0.7 * width, 0.12 * height, 0.95 * width, 0.2 * height),
        "date_of_birth": (0.05 * width, 0.4 * height, 0.4 * width, 0.5 * height),
        "expiry_date": (0.6 * width, 0.4 * height, 0.9 * width, 0.5 * height),
    }

def map_ocr_to_fields(ocr_results: list, field_regions: dict) -> dict:
    """
    Map OCR results to specific fields based on bounding box regions.
    :param ocr_results: List of OCR results from PaddleOCR.
    :param field_regions: Dictionary of regions for each field.
    :return: Dictionary of extracted data mapped to the fields.
    """
    extracted_data = {field: None for field in field_regions.keys()}

    for field, region in field_regions.items():
        x_min, y_min, x_max, y_max = region

        for result in ocr_results:
            bbox = result[0]  # Bounding box coordinates
            text = result[1][0].strip()  # Detected text

            # Check if the center of the bounding box lies within the region
            bbox_center_x = (bbox[0][0] + bbox[2][0]) / 2
            bbox_center_y = (bbox[0][1] + bbox[2][1]) / 2

            if x_min <= bbox_center_x <= x_max and y_min <= bbox_center_y <= y_max:
                # Additional logic for specific fields (e.g., first name and last name)
                if field == "first_name" and text.islower():
                    extracted_data[field] = text
                elif field == "last_name" and text.isupper():
                    extracted_data[field] = text
                else:
                    extracted_data[field] = text
                break

    return extracted_data

def map_fields(ocr_results: list, regions: dict) -> dict:
    """
    Map OCR results to specific fields based on bounding box positions.
    :param ocr_results: OCR results with text and bounding boxes.
    :param regions: Predefined regions for each field.
    :return: Dictionary with extracted fields.
    """
    extracted_data = {
        "first_name_last_name": None,
        "address": None,
        "license_number": None,
        "card_number": None,
        "date_of_birth": None,
        "expiry_date": None
    }

    for result in ocr_results:
        text = result[1][0]  # Extracted text
        bbox = result[0]  # Bounding box coordinates
        bbox_center = ((bbox[0][0] + bbox[2][0]) / 2, (bbox[0][1] + bbox[2][1]) / 2)

        for field, (x_min, y_min, x_max, y_max) in regions.items():
            if x_min <= bbox_center[0] <= x_max and y_min <= bbox_center[1] <= y_max:
                extracted_data[field] = text
                break  # Assign the text to the first matching region

    return extracted_data
