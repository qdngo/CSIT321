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
    Preprocess the image by resizing it to match the aspect ratio of 
    an Australian driver license (~1.585), converting to grayscale, and centering.
    """
    image = Image.open(io.BytesIO(image_data))

    # Resize based on standard license aspect ratio (85.6mm x 54mm)
    target_width = 800
    aspect_ratio = 1.585  # Australian driver license
    target_height = int(target_width / aspect_ratio)
    standardized_size = (target_width, target_height)

    # Resize and crop to fit
    image = ImageOps.fit(image, standardized_size, Image.Resampling.LANCZOS)

    # Convert to grayscale
    image = image.convert("L")
    return image



def perform_ocr(image: Image.Image, debug: bool = False) -> list:
    """
    Perform OCR on the image and return bounding boxes with text.
    """
    image_np = np.array(image)
    result = ocr.ocr(image_np, cls=True)
    
    if debug:
        print("\n--- OCR RESULTS ---")
        for line in result[0]:
            bbox = line[0]
            text = line[1][0]
            score = line[1][1]
            print(f"Text: {text}")
            print(f"Score: {score:.2f}")
            print(f"BBox: {bbox}")
            print("---")
    return result[0]  # Return only the detected text and bounding boxes    


def map_ocr_to_fields(ocr_results: list, field_regions: dict, doc_type: str, state_code: str = None) -> dict:
    """
    Map OCR results to specific fields based on bounding box regions, with logic for different document types.

    :param ocr_results: List of OCR results from PaddleOCR.
    :param field_regions: Dictionary of regions for each field.
    :param doc_type: Type of document ('passport', 'driver_license', 'photo_card').
    :param state_code: Detected state abbreviation (e.g. 'NSW', 'VIC')
    :return: Dictionary of extracted fields
    """
    extracted_data = {field: None for field in field_regions.keys()}

    for field, region in field_regions.items():
        x_min, y_min, x_max, y_max = region
        field_texts = []

        for result in ocr_results:
            bbox = result[0]
            text = result[1][0].strip()

            bbox_center_x = (bbox[0][0] + bbox[2][0]) / 2
            bbox_center_y = (bbox[0][1] + bbox[2][1]) / 2

            if x_min <= bbox_center_x <= x_max and y_min <= bbox_center_y <= y_max:
                if field == "address":
                    field_texts.append(text)

                elif field in ["first_name", "last_name"]:
                    # NSW & ACT logic: one line, need to split based on casing
                    if doc_type in ["driver_license", "photo_card"] and state_code in ["NSW", "ACT"]:
                        if extracted_data["first_name"] is None and extracted_data["last_name"] is None:
                            name_parts = text.split()
                            upper_case_parts = [part for part in name_parts if part.isupper()]
                            lower_case_parts = [part for part in name_parts if not part.isupper()]
                            extracted_data["last_name"] = " ".join(upper_case_parts)
                            extracted_data["first_name"] = " ".join(lower_case_parts)
                            break  # stop processing both name fields
                    else:
                        # For other states (like VIC), assign names individually if not already set
                        if extracted_data[field] is None:
                            extracted_data[field] = text
                            break

                else:
                    # All other fields
                    extracted_data[field] = text
                    break

        if field == "address" and field_texts:
            extracted_data[field] = " ".join(field_texts)

    return extracted_data



def draw_ocr_boxes(image: Image.Image, ocr_results: list, save_path="debug_ocr.jpg"):
    image_np = np.array(image.convert("RGB"))  # Ensure RGB for drawing
    for result in ocr_results:
        box = np.array(result[0], dtype=np.int32)
        text = result[1][0]
        cv2.polylines(image_np, [box], isClosed=True, color=(0, 255, 0), thickness=2)
        cv2.putText(image_np, text, tuple(box[0]), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 1)
    
    cv2.imwrite(save_path, cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR))
    print(f"[✅] OCR debug image saved to: {save_path}")


def log_normalized_bboxes(ocr_results: list, image_size: tuple):
    """
    Log normalized bounding box positions for defining field regions.
    """
    width, height = image_size
    print("\n🔍 NORMALIZED OCR BOUNDING BOXES:")

    for result in ocr_results:
        text = result[1][0]
        bbox = result[0]

        x_coords = [point[0] for point in bbox]
        y_coords = [point[1] for point in bbox]

        x_min = min(x_coords) / width
        x_max = max(x_coords) / width
        y_min = min(y_coords) / height
        y_max = max(y_coords) / height

        print(f"Text: {text}")
        print(f"Normalized region: ({x_min:.3f} * width, {y_min:.3f} * height, {x_max:.3f} * width, {y_max:.3f} * height)")
        print("---")
        
def detect_state_from_text(ocr_results: list) -> str:
    """
    Detects the Australian state based on OCR text results (case-insensitive).
    Prioritizes matches found in the first few (top) OCR lines.
    """
    state_keywords = {
        "new south wales": "NSW",
        "nsw": "NSW",
        "victoria": "VIC",
        "vic": "VIC",
        "queensland": "QLD",
        "qld": "QLD",
        "south australia": "SA",
        "sa": "SA",
        "western australia": "WA",
        "westernaustralia": "WA",
        "wa": "WA",
        "tasmania": "TAS",
        "personal information card": "TAS",
        "tasmanian": "TAS",
        "tas": "TAS",
        "australian capital territory": "ACT",
        "act": "ACT",
        "northern territory": "NT",
        "nt": "NT"
    }

    for result in ocr_results:
        text = result[1][0].lower()
        for keyword, code in state_keywords.items():
            if keyword in text:
                return code

    return None  # nothing matched



# ================= 1. DEFINE REGION FOR NSW =================
def define_nsw_license_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (NSW) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.033 * width, 0.186 * height, 0.369 * width, 0.225 * height),
        "last_name": (0.033 * width, 0.186 * height, 0.369 * width, 0.225 * height),
        "address": (0.03 * width, 0.37 * height, 0.46 * width, 0.5 * height), 
        "license_number": (0.03 * width, 0.592 * height, 0.19 * width, 0.64 * height), 
        "card_number": (0.76 * width, 0.22 * height, 0.97 * width, 0.277 * height),
        "date_of_birth": (0.47 * width, 0.908 * height, 0.675 * width, 0.988 * height),
        "expiry_date": (0.782 * width, 0.908 * height, 0.98 * width, 0.985 * height),
    } 

# ================= 2. DEFINE REGION FOR VIC =================
def define_vic_license_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (VIC) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.066 * width, 0.18 * height, 0.3 * width, 0.233 * height),
        "last_name": (0.066 * width, 0.245 * height, 0.3 * width, 0.29 * height),
        "address": (0.071 * width, 0.31 * height, 0.6 * width, 0.49 * height), 
        "license_number": (0.802 * width, 0.230 * height, 0.964 * width, 0.270 * height), 
        "card_number": (0.802 * width, 0.230 * height, 0.964 * width, 0.270 * height),
        "date_of_birth": (0.37 * width, 0.559 * height, 0.63 * width, 0.611 * height),
        "expiry_date": (0.072 * width, 0.556 * height, 0.318 * width, 0.613 * height),
    } 

# ================= 3. DEFINE REGION FOR QLD =================
def define_qld_license_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (QLD) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.071 * width, 0.187 * height, 0.3 * width, 0.25 * height),
        "last_name": (0.071 * width, 0.129 * height, 0.3 * width, 0.18 * height),
        "address": (0 * width, 0 * height, 0 * width, 0 * height), 
        "license_number": (0.757 * width, 0.094 * height, 0.978 * width, 0.139 * height), 
        "card_number": (0.42 * width, 0.93 * height, 0.58 * width, 0.985 * height),
        "date_of_birth": (0.284 * width, 0.294 * height, 0.562 * width, 0.350 * height),
        "expiry_date": (0.558 * width, 0.456 * height, 0.624 * width, 0.498 * height),
    } 

# ================= 4. DEFINE REGION FOR SA =================
def define_sa_license_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (SA) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.079 * width, 0.514 * height, 0.260 * width, 0.559 * height),
        "last_name": (0.079 * width, 0.514 * height, 0.260 * width, 0.559 * height),
        "address": (0.075 * width, 0.57 * height, 0.3 * width, 0.68 * height), 
        "license_number": (0.075 * width, 0.248 * height, 0.2 * width, 0.3 * height), 
        "card_number": (0 * width, 0 * height, 0 * width, 0 * height),
        "date_of_birth": (0.3 * width, 0.25 * height, 0.45 * width, 0.31 * height),
        "expiry_date": (0.545 * width, 0.25 * height, 0.71 * width, 0.31 * height),
    } 
    
# ================= 5. DEFINE REGION FOR WA =================
def define_wa_license_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (WA) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.055 * width, 0.439 * height, 0.231 * width, 0.486 * height),
        "last_name": (0.014 * width, 0.381 * height, 0.231 * width, 0.431 * height),
        "address": (0.015 * width, 0.49 * height, 0.228 * width, 0.6 * height), 
        "license_number": (0.8 * width, 0.29 * height, 0.933 * width, 0.355 * height), 
        "card_number": (0.712 * width, 0.834 * height, 0.893 * width, 0.880 * height),
        "date_of_birth": (0.34 * width, 0.66 * height, 0.59 * width, 0.72 * height),
        "expiry_date": (0.015 * width, 0.65 * height, 0.255 * width, 0.715 * height),
    } 
    

# ================= 6. DEFINE REGION FOR ACT =================
def define_act_license_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (ACT) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.027 * width, 0.24 * height, 0.3 * width, 0.300 * height),
        "last_name": (0.027 * width, 0.24 * height, 0.3 * width, 0.300 * height),
        "address": (0.029 * width, 0.325 * height, 0.510 * width, 0.49 * height), 
        "license_number": (0.022 * width, 0.597 * height, 0.383 * width, 0.653 * height), 
        "card_number": (0.654 * width, 0.633 * height, 0.685 * width, 0.966 * height),
        "date_of_birth": (0.024 * width, 0.518 * height, 0.355 * width, 0.577 * height),
        "expiry_date": (0.39 * width, 0.595 * height, 0.57 * width, 0.65 * height),
    } 
    
# ================= 7. DEFINE REGION FOR TAS =================
def define_tas_license_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (TAS) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.37 * width, 0.19 * height, 0.501 * width, 0.244 * height),
        "last_name": (0.37 * width, 0.247 * height, 0.476 * width, 0.300 * height),
        "address": (0.379 * width, 0.33 * height, 0.72 * width, 0.430 * height), 
        "license_number": (0.051 * width, 0.244 * height, 0.18 * width, 0.294 * height), 
        "card_number": (0.051 * width, 0.244 * height, 0.18 * width, 0.294 * height),
        "date_of_birth": (0.657 * width, 0.526 * height, 0.968 * width, 0.577 * height),
        "expiry_date": (0.477 * width, 0.643 * height, 0.723 * width, 0.685 * height),
    } 
    
# ================= 8. DEFINE REGION FOR NT =================
def define_nt_license_regions(image_size: tuple) -> dict:
    """
    Define approximate bounding box regions for each field based on the typical layout
    of an Australian (NT) driver license.
    :param image_size: Tuple of (width, height) of the image.
    :return: Dictionary of regions for each field.
    """
    width, height = image_size
    return {
        "first_name": (0.289 * width, 0.363 * height, 0.420 * width, 0.403 * height),
        "last_name": (0.287 * width, 0.413 * height, 0.385 * width, 0.452 * height),
        "address": (0.287 * width, 0.685 * height, 0.59 * width, 0.78 * height), 
        "license_number": (0.286 * width, 0.530 * height, 0.598 * width, 0.577 * height), 
        "card_number": (0 * width, 0 * height, 0 * width, 0 * height),
        "date_of_birth": (0.576 * width, 0.915 * height, 0.694 * width, 0.940 * height),
        "expiry_date": (0.801 * width, 0.911 * height, 0.922 * width, 0.942 * height),
    } 
    

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

# def define_photo_card_regions(image_size: tuple) -> dict:
#     """
#     Define precise bounding box regions for NSW photo cards based on the provided example image.
#     """
#     width, height = image_size
#     return {
#         "first_name": (0.02 * width, 0.17 * height, 0.4 * width, 0.25 * height), 
#         "last_name": (0.02 * width, 0.17 * height, 0.4 * width, 0.25 * height), 
#         "address": (0.02 * width, 0.36 * height, 0.4 * width, 0.55 * height), 
#         "photo_card_number": (0.02 * width, 0.59 * height, 0.26 * width, 0.65 * height), 
#         "card_number": (0.75 * width, 0.245 * height, 0.975 * width, 0.3 * height), 
#         "date_of_birth": (0.46 * width, 0.91 * height, 0.66 * width, 0.97 * height), 
#         "expiry_date": (0.77 * width, 0.91 * height, 0.97 * width, 0.97 * height), 
#     }

# ================= 1. NSW PHOTO CARD =================
def define_nsw_photo_card_regions(image_size: tuple) -> dict:
    width, height = image_size
    return {
        "first_name": (0.02 * width, 0.17 * height, 0.4 * width, 0.25 * height), 
        "last_name": (0.02 * width, 0.17 * height, 0.4 * width, 0.25 * height), 
        "address": (0.02 * width, 0.36 * height, 0.4 * width, 0.55 * height), 
        "photo_card_number": (0.02 * width, 0.59 * height, 0.26 * width, 0.65 * height), 
        "card_number": (0.75 * width, 0.245 * height, 0.975 * width, 0.3 * height), 
        "date_of_birth": (0.46 * width, 0.91 * height, 0.66 * width, 0.97 * height), 
        "expiry_date": (0.77 * width, 0.91 * height, 0.97 * width, 0.97 * height), 
    }
    
# ================= 2. VIC PHOTO CARD =================
def define_vic_photo_card_regions(image_size: tuple) -> dict:
    width, height = image_size
    return {
        "first_name": (0.04 * width, 0.225 * height, 0.25 * width, 0.275 * height),
        "last_name": (0.04 * width, 0.225 * height, 0.25 * width, 0.275 * height),
        "address": (0.043 * width, 0.300 * height, 0.4 * width, 0.4 * height),
        "photo_card_number": (0.8 * width, 0.3 * height, 0.943 * width, 0.355 * height),
        "card_number": (0.8 * width, 0.3 * height, 0.943 * width, 0.355 * height),
        "date_of_birth": (0.040 * width, 0.524 * height, 0.194 * width, 0.569 * height),
        "expiry_date": (0 * width, 0 * height, 0 * width, 0 * height), 
    }
    
# ================= 3. QLD PHOTO CARD =================
def define_qld_photo_card_regions(image_size: tuple) -> dict:
    width, height = image_size
    return {
        "first_name": (0.074 * width, 0.133 * height, 0.209 * width, 0.183 * height),
        "last_name": (0.072 * width, 0.190 * height, 0.209 * width, 0.246 * height),
        "address": (0 * width, 0 * height, 0 * width, 0 * height),
        "photo_card_number": (0.744 * width, 0.103 * height, 0.969 * width, 0.157 * height),
        "card_number": (0.744 * width, 0.103 * height, 0.969 * width, 0.157 * height),
        "date_of_birth": (0.287 * width, 0.413 * height, 0.564 * width, 0.478 * height),
        "expiry_date": (0.287 * width, 0.633 * height, 0.395 * width, 0.683 * height), 
    }
    
# ================= 4. SA PHOTO CARD =================
def define_sa_photo_card_regions(image_size: tuple) -> dict:
    width, height = image_size
    return {
        "first_name": (0.090 * width, 0.498 * height, 0.444 * width, 0.546 * height),
        "last_name": (0.090 * width, 0.498 * height, 0.444 * width, 0.546 * height),
        "address": (0.089 * width, 0.577 * height, 0.321 * width, 0.7 * height),
        "photo_card_number": (0.068 * width, 0.226 * height, 0.211 * width, 0.290 * height),
        "card_number": (0.068 * width, 0.226 * height, 0.211 * width, 0.290 * height),
        "date_of_birth": (0.540 * width, 0.260 * height, 0.880 * width, 0.345 * height),
        "expiry_date": (0 * width, 0 * height, 0 * width, 0 * height), 
    }
    
# ================= 5. WA PHOTO CARD =================
def define_wa_photo_card_regions(image_size: tuple) -> dict:
    width, height = image_size
    return {
        "first_name": (0.079 * width, 0.454 * height, 0.264 * width, 0.496 * height),
        "last_name": (0.029 * width, 0.405 * height, 0.146 * width, 0.452 * height),
        "address": (0.035 * width, 0.506 * height, 0.381 * width, 0.6 * height),
        "photo_card_number": (0.816 * width, 0.302 * height, 0.966 * width, 0.349 * height),
        "card_number": (0.816 * width, 0.302 * height, 0.966 * width, 0.349 * height),
        "date_of_birth": (0.338 * width, 0.681 * height, 0.546 * width, 0.732 * height),
        "expiry_date": (0.033 * width, 0.681 * height, 0.244 * width, 0.732 * height), 
    }
    
# ================= 6. ACT PHOTO CARD =================
def define_act_photo_card_regions(image_size: tuple) -> dict:
    width, height = image_size
    return {
        "first_name": (0.030 * width, 0.246 * height, 0.290 * width, 0.288 * height),
        "last_name": (0.030 * width, 0.246 * height, 0.290 * width, 0.288 * height),
        "address": (0.026 * width, 0.321 * height, 0.509 * width, 0.48 * height),
        "photo_card_number": (0.024 * width, 0.605 * height, 0.371 * width, 0.661 * height),
        "card_number": (0.024 * width, 0.605 * height, 0.371 * width, 0.661 * height),
        "date_of_birth": (0.014 * width, 0.532 * height, 0.352 * width, 0.575 * height),
        "expiry_date": (0 * width, 0 * height, 0 * width, 0 * height), 
    }
    
# ================= 7. TAS PHOTO CARD =================
def define_tas_photo_card_regions(image_size: tuple) -> dict:
    width, height = image_size
    return {
        "first_name": (0.35 * width, 0.205 * height, 0.43 * width, 0.27 * height),
        "last_name": (0.35 * width, 0.15 * height, 0.48 * width, 0.2 * height),
        "address": (0.365 * width, 0.58 * height, 0.745 * width, 0.7 * height),
        "photo_card_number": (0.367 * width, 0.462 * height, 0.502 * width, 0.524 * height),
        "card_number": (0.367 * width, 0.462 * height, 0.502 * width, 0.524 * height),
        "date_of_birth": (0.095 * width, 0.74 * height, 0.25 * width, 0.81 * height),
        "expiry_date": (0 * width, 0 * height, 0 * width, 0 * height), 
    }
    
# ================= 8. NT PHOTO CARD =================
def define_nt_photo_card_regions(image_size: tuple) -> dict:
    width, height = image_size
    return {
        "first_name": (0.316 * width, 0.369 * height, 0.416 * width, 0.417 * height),
        "last_name": (0.318 * width, 0.319 * height, 0.450 * width, 0.361 * height),
        "address": (0 * width, 0 * height, 0 * width, 0 * height),
        "photo_card_number": (0.026 * width, 0.915 * height, 0.171 * width, 0.952 * height),
        "card_number": (0.026 * width, 0.915 * height, 0.171 * width, 0.952 * height),
        "date_of_birth": (0.360 * width, 0.486 * height, 0.723 * width, 0.562 * height),
        "expiry_date": (0.319 * width, 0.694 * height, 0.568 * width, 0.732 * height), 
    }
    