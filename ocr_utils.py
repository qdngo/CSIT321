from paddleocr import PaddleOCR
from PIL import Image, ImageOps
import io
from io import BytesIO
from typing import List, Dict, Union
import numpy as np
import cv2

# Initialize PaddleOCR once
ocr = PaddleOCR(use_angle_cls=True, lang='en')

def preprocess_image(image_data: bytes) -> Image.Image:
    """
    Preprocess the image to detect the edges of the ID card, rotate if necessary, and crop it to include only the ID card.
    It also handles poor lighting and resizes the output image to a standard size.
    """
    try:
        # Step 1: Load the image
        image = cv2.imdecode(np.frombuffer(image_data, np.uint8), cv2.IMREAD_COLOR)

        # Step 2: Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Step 3: Improve contrast using CLAHE (adaptive histogram equalization)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        gray = clahe.apply(gray)

        # Step 4: Reduce noise with GaussianBlur
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        # Step 5: Edge detection using Canny
        edges = cv2.Canny(blurred, threshold1=50, threshold2=150)

        # Step 6: Find contours
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        contours = sorted(contours, key=cv2.contourArea, reverse=True)

        # Step 7: Find the largest quadrilateral contour
        id_card_contour = None
        for contour in contours:
            perimeter = cv2.arcLength(contour, True)
            approx = cv2.approxPolyDP(contour, 0.02 * perimeter, True)
            if len(approx) == 4:
                id_card_contour = approx
                break

        if id_card_contour is None:
            raise ValueError("No ID card contour found in the image.")

        # Step 8: Apply perspective transformation
        # Order the points in a consistent order (top-left, top-right, bottom-right, bottom-left)
        def order_points(pts):
            rect = np.zeros((4, 2), dtype="float32")
            s = pts.sum(axis=1)
            rect[0] = pts[np.argmin(s)]  # Top-left
            rect[2] = pts[np.argmax(s)]  # Bottom-right
            diff = np.diff(pts, axis=1)
            rect[1] = pts[np.argmin(diff)]  # Top-right
            rect[3] = pts[np.argmax(diff)]  # Bottom-left
            return rect

        card_points = id_card_contour.reshape(4, 2)
        ordered_points = order_points(card_points)

        # Define the dimensions for the output (width and height of the ID card)
        width = 1024
        height = 640
        dst = np.array([[0, 0], [width - 1, 0], [width - 1, height - 1], [0, height - 1]], dtype="float32")

        # Perform perspective transformation
        M = cv2.getPerspectiveTransform(ordered_points, dst)
        warped = cv2.warpPerspective(image, M, (width, height))

        # Step 9: Convert the image back to PIL format
        result_image = Image.fromarray(cv2.cvtColor(warped, cv2.COLOR_BGR2RGB))

        return result_image

    except Exception as e:
        raise ValueError(f"Error in preprocessing: {str(e)}")



def perform_ocr(image: Image.Image) -> list:
    """
    Perform OCR on the image and return bounding boxes with text.
    """
    image_np = np.array(image)
    result = ocr.ocr(image_np, cls=True)
    return result[0]  # Return only the detected text and bounding boxes


def map_ocr_to_fields(ocr_results: list, field_regions: dict, doc_type: str) -> dict:
    """
    Map OCR results to specific fields based on bounding box regions, with logic for different document types.
    
    :param ocr_results: List of OCR results from PaddleOCR.
    :param field_regions: Dictionary of regions for each field.
    :param doc_type: Type of document ('passport', 'driver_license', 'photo_card').
    :return: Dictionary of extracted data mapped to the fields.
    """
    extracted_data = {field: None for field in field_regions.keys()}

    for field, region in field_regions.items():
        x_min, y_min, x_max, y_max = region
        field_texts = []  # Collect all text pieces within the region

        for result in ocr_results:
            bbox = result[0]  # Bounding box coordinates
            text = result[1][0].strip()  # Detected text

            # Check if the center of the bounding box lies within the region
            bbox_center_x = (bbox[0][0] + bbox[2][0]) / 2
            bbox_center_y = (bbox[0][1] + bbox[2][1]) / 2

            if x_min <= bbox_center_x <= x_max and y_min <= bbox_center_y <= y_max:
                # Aggregate all text for the address field
                if field == "address":
                    field_texts.append(text)
                else:
                    # Skip first_name/last_name logic for passports
                    if doc_type != "passport":
                        if field == "first_name" or field == "last_name":
                            if extracted_data["first_name"] is None and extracted_data["last_name"] is None:
                                # Split the name into parts and classify
                                name_parts = text.split()
                                upper_case_parts = [part for part in name_parts if part.isupper()]
                                lower_case_parts = [part for part in name_parts if not part.isupper()]

                                # Assign first and last names
                                extracted_data["last_name"] = " ".join(upper_case_parts)
                                extracted_data["first_name"] = " ".join(lower_case_parts)
                            break
                        else:
                            extracted_data[field] = text
                        break
                    else:
                        extracted_data[field] = text  # No special handling for passport fields
                        break

        # Combine all text pieces for the address field
        if field == "address" and field_texts:
            extracted_data[field] = " ".join(field_texts)

    return extracted_data



'''
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
'''

def define_license_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (NSW) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.028 * width, 0.16 * height, 0.46 * width, 0.23 * height),
        "last_name": (0.028 * width, 0.16 * height, 0.46 * width, 0.23 * height),
        "address": (0.025 * width, 0.35 * height, 0.46 * width, 0.5 * height), 
        "license_number": (0.02 * width, 0.57 * height, 0.2 * width, 0.65 * height), 
        "card_number": (0.75 * width, 0.22 * height, 1 * width, 0.28 * height),
        "date_of_birth": (0.46 * width, 0.89 * height, 0.67 * width, 0.96 * height),
        "expiry_date": (0.77 * width, 0.89 * height, 0.98 * width, 0.96 * height),
    } 
    # Change the values to match the actual layout of the driver's license


def define_passport_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for Australian passports.
    """
    width, height = image_size
    return {
        "first_name": (0.31 * width, 0.23 * height, 0.64 * width, 0.29 * height),
        "last_name": (0.31 * width, 0.29 * height, 0.64 * width, 0.33 * height),
        "date_of_birth": (0.31 * width, 0.426 * height, 0.56 * width, 0.467 * height),
        "document_number": (0.72 * width, 0.15 * height, 0.95 * width, 0.22 * height),
        "expiry_date": (0.31 * width, 0.63 * height, 0.57 * width, 0.68 * height),
        "gender": (0.31 * width, 0.49 * height, 0.39 * width, 0.54 * height),
    }

def define_photo_card_regions(image_size: tuple) -> dict:
    """
    Define precise bounding box regions for NSW photo cards based on the provided example image.
    """
    width, height = image_size
    return {
        "first_name": (0.02 * width, 0.17 * height, 0.4 * width, 0.25 * height), 
        "last_name": (0.02 * width, 0.17 * height, 0.4 * width, 0.25 * height), 
        "address": (0.02 * width, 0.36 * height, 0.4 * width, 0.55 * height), 
        "photo_card_number": (0.02 * width, 0.59 * height, 0.26 * width, 0.66 * height), 
        "card_number": (0.75 * width, 0.248 * height, 0.975 * width, 0.3 * height), 
        "date_of_birth": (0.46 * width, 0.91 * height, 0.66 * width, 0.97 * height), 
        "expiry_date": (0.78 * width, 0.91 * height, 0.97 * width, 0.97 * height), 
    }
