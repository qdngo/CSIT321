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
    Define positional regions for each field based on the license layout.
    :param image_size: Tuple (width, height) of the license image.
    :return: Dictionary with regions for each field.
    """
    width, height = image_size

    return {
        "first_name_last_name": (0, 0, width * 0.5, height * 0.2),  # Top-left region
        "address": (0, height * 0.2, width * 0.5, height * 0.4),    # Below name
        "license_number": (0, height * 0.4, width * 0.5, height * 0.5),  # Mid-left
        "card_number": (width * 0.5, 0, width, height * 0.2),       # Top-right
        "date_of_birth": (0, height * 0.5, width * 0.5, height * 0.6),  # Bottom-left
        "expiry_date": (width * 0.5, height * 0.5, width, height * 0.6)  # Bottom-right
    }

def map_ocr_to_fields(ocr_results: List[Dict], field_mapping: Dict[str, str]) -> Dict[str, Union[str, None]]:
    """
    Map OCR results to the required fields based on the field mapping.

    :param ocr_results: List of OCR results containing text and bounding boxes.
    :param field_mapping: Dictionary mapping model fields to expected labels in OCR output.
    :return: Dictionary containing extracted field values.
    """
    extracted_data = {field: None for field in field_mapping.keys()}

    for result in ocr_results:
        text = result.get("text", "").strip()
        for field, expected_label in field_mapping.items():
            if expected_label.lower() in text.lower():
                extracted_data[field] = text.replace(expected_label, "").strip()

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
