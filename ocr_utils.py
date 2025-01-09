from paddleocr import PaddleOCR
from PIL import Image, ImageOps
import io
from io import BytesIO
from typing import List, Dict, Union, Tuple, Optional
import numpy as np
import cv2
import imutils

# Initialize PaddleOCR once
ocr = PaddleOCR(
    use_angle_cls=True, 
    lang='en', 
    use_gpu=True,
    det_db_box_thresh=0.5,
    det_db_unclip_ratio=1.6
)

# ----------------------------------------------------------------------
 
def order_points(pts: np.ndarray) -> np.ndarray:
    """
    Order points in clockwise order (top-left, top-right, bottom-right, bottom-left)
    """
    rect = np.zeros((4, 2), dtype="float32")
    
    # Top-left will have smallest sum, bottom-right will have largest sum
    s = pts.sum(axis=1)
    rect[0] = pts[np.argmin(s)]
    rect[2] = pts[np.argmax(s)]
    
    # Top-right will have smallest difference, bottom-left will have largest difference
    diff = np.diff(pts, axis=1)
    rect[1] = pts[np.argmin(diff)]
    rect[3] = pts[np.argmax(diff)]
    
    return rect

def four_point_transform(image: np.ndarray, pts: np.ndarray) -> np.ndarray:
    """
    Apply perspective transform to obtain a "bird's eye view" of the image
    """
    rect = order_points(pts)
    (tl, tr, br, bl) = rect
    
    # Compute width of new image
    widthA = np.sqrt(((br[0] - bl[0]) ** 2) + ((br[1] - bl[1]) ** 2))
    widthB = np.sqrt(((tr[0] - tl[0]) ** 2) + ((tr[1] - tl[1]) ** 2))
    maxWidth = max(int(widthA), int(widthB))
    
    # Compute height of new image
    heightA = np.sqrt(((tr[0] - br[0]) ** 2) + ((tr[1] - br[1]) ** 2))
    heightB = np.sqrt(((tl[0] - bl[0]) ** 2) + ((tl[1] - bl[1]) ** 2))
    maxHeight = max(int(heightA), int(heightB))
    
    # Define destination points for bird's eye view
    dst = np.array([
        [0, 0],
        [maxWidth - 1, 0],
        [maxWidth - 1, maxHeight - 1],
        [0, maxHeight - 1]
    ], dtype="float32")
    
    # Compute perspective transform matrix and apply it
    M = cv2.getPerspectiveTransform(rect, dst)
    warped = cv2.warpPerspective(image, M, (maxWidth, maxHeight))
    
    return warped

def detect_document_edges(image: np.ndarray) -> Optional[np.ndarray]:
    """
    Detect document edges in the image using adaptive methods
    """
    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Apply different blur methods and combine results
    gaussian_blur = cv2.GaussianBlur(gray, (5, 5), 0)
    median_blur = cv2.medianBlur(gray, 5)
    bilateral_blur = cv2.bilateralFilter(gray, 9, 75, 75)
    
    # Apply different edge detection methods
    canny_edges = cv2.Canny(gaussian_blur, 75, 200)
    sobel_x = cv2.Sobel(median_blur, cv2.CV_64F, 1, 0, ksize=3)
    sobel_y = cv2.Sobel(median_blur, cv2.CV_64F, 0, 1, ksize=3)
    sobel_combined = cv2.magnitude(sobel_x, sobel_y)
    
    # Normalize and combine edge detection results
    sobel_combined = cv2.normalize(sobel_combined, None, 0, 255, cv2.NORM_MINMAX, cv2.CV_8U)
    edges = cv2.addWeighted(canny_edges, 0.7, sobel_combined, 0.3, 0)
    
    # Find contours
    cnts = cv2.findContours(edges.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cnts = imutils.grab_contours(cnts)
    
    if not cnts:
        return None
    
    # Sort contours by area and keep the largest ones
    cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:5]
    
    # Find the document contour
    document_contour = None
    for c in cnts:
        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)
        
        if len(approx) == 4:
            document_contour = approx
            break
    
    return document_contour

def enhance_image(image: np.ndarray) -> np.ndarray:
    """
    Enhance the image quality using various techniques
    """
    # Convert to LAB color space
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    
    # Apply CLAHE to L channel
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
    l = clahe.apply(l)
    
    # Merge channels
    lab = cv2.merge((l, a, b))
    enhanced = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
    
    # Adjust contrast and brightness
    alpha = 1.2  # Contrast control
    beta = 10    # Brightness control
    enhanced = cv2.convertScaleAbs(enhanced, alpha=alpha, beta=beta)
    
    return enhanced



# ----------------------------------------------------------------------

def preprocess_image(image_data: bytes) -> Tuple[Image.Image, bool]:
    """
    Enhanced preprocessing pipeline for ID card images
    Returns a tuple of (processed_image, is_cropped)
    """
    # Convert bytes to numpy array
    nparr = np.frombuffer(image_data, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # Resize image while maintaining aspect ratio
    height = 800
    ratio = height / image.shape[0]
    dim = (int(image.shape[1] * ratio), height)
    image = cv2.resize(image, dim, interpolation=cv2.INTER_AREA)
    
    # Keep original for later use
    original = image.copy()
    
    # Detect document edges
    document_contour = detect_document_edges(image)
    
    if document_contour is not None:
        # Apply perspective transform
        warped = four_point_transform(original, document_contour.reshape(4, 2))
        
        # Enhance image quality
        enhanced = enhance_image(warped)
        
        # Convert to PIL Image
        enhanced_pil = Image.fromarray(cv2.cvtColor(enhanced, cv2.COLOR_BGR2RGB))
        
        # Resize to standard size
        enhanced_pil = enhanced_pil.resize((1024, 640), Image.Resampling.LANCZOS)
        
        return enhanced_pil, True
    else:
        # If no document edges detected, process the original image
        enhanced = enhance_image(original)
        enhanced_pil = Image.fromarray(cv2.cvtColor(enhanced, cv2.COLOR_BGR2RGB))
        enhanced_pil = enhanced_pil.resize((1024, 640), Image.Resampling.LANCZOS)
        return enhanced_pil, False
    
def process_image_with_status(preprocessed_image: Image.Image, is_cropped: bool, doc_type: str) -> dict:
    """
    Process the image and return results with cropping status
    """
    ocr_results = perform_ocr(preprocessed_image)
    
    # Get appropriate regions based on document type
    if doc_type == "driver_license":
        regions = define_license_regions(preprocessed_image.size)
    elif doc_type == "passport":
        regions = define_passport_regions(preprocessed_image.size)
    else:  # photo_card
        regions = define_photo_card_regions(preprocessed_image.size)
    
    extracted_data = map_ocr_to_fields(ocr_results, regions, doc_type)
    
    return {
        "doc_type": doc_type,
        "extracted_data": extracted_data,
        "preprocessing_status": {
            "cropped": is_cropped,
            "image_size": preprocessed_image.size
        }
    }



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