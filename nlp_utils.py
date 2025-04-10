import re
import spacy
from datetime import datetime

nlp = spacy.load("en_core_web_sm")

def separate_numbers_and_letters(text: str, field_name: str = "") -> str:
    """
    Adds spaces between digits and letters (and vice versa),
    but only for fields like address — not for license/card numbers.
    """
    if field_name.lower() not in ["address"]:
        return text

    text = re.sub(r'(\d)([A-Za-z])', r'\1 \2', text)
    text = re.sub(r'([A-Za-z])(\d)', r'\1 \2', text)
    return text


def split_sticky_text(text: str) -> str:
    return re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', text)

def fix_common_address_abbreviations(text: str) -> str:
    street_abbreviations = ["ST", "RD", "AVE", "CR", "DR", "GR", "HTS", "HWY",""]
    state_abbreviations = ["NSW", "VIC", "QLD", "SA", "WA", "TAS", "ACT", "NT"]

    # --- Handle street abbreviations ---
    for abbr in street_abbreviations:
        # Case A: abbreviation stuck to the following text: "RD16" -> "RD 16"
        pattern_after = rf"\b{abbr}(?!\s)"
        text = re.sub(pattern_after, abbr + " ", text, flags=re.IGNORECASE)


        # Case B: abbreviation stuck to the preceding text: "LANEST" -> "LANE ST"
        pattern_suburb = rf"([A-Za-z])({abbr})\b"
        text = re.sub(pattern_suburb, rf"\1 {abbr}", text, flags=re.IGNORECASE)

    # --- Handle state abbreviations ---
    for state in state_abbreviations:
        # Match something like MEADOWNSW2500 and turn into "MEADOW NSW 2500"
        # Step 1: add space before state code only if followed by 4-digit postcode
        pattern_wordstate = rf"([A-Za-z])({state})(\d{{4}}\b)"
        text = re.sub(pattern_wordstate, rf"\1 {state} \3", text, flags=re.IGNORECASE)

        # Step 2: also catch cases like "NSW2500" without a leading word
        pattern_state_postcode = rf"\b({state})(\d{{4}}\b)"
        text = re.sub(pattern_state_postcode, r"\1 \2", text, flags=re.IGNORECASE)

    # Clean up extra spaces
    text = re.sub(r"\s+", " ", text).strip()
    return text


def clean_date_of_birth_field(text: str) -> str:
    text = normalize_sticky_keywords(text)

    patterns = [
        r"\bDOB\b",
        r"\bD\.O\.B\b",
        r"\bDATE OF BIRTH\b",
        r"\bDATE\s*OF\s*BIRTH\b"
    ]

    for pattern in patterns:
        text = re.sub(pattern, "", text, flags=re.IGNORECASE)

    text = re.sub(r"\s+", " ", text).strip()
    return auto_format_date(text)


def clean_license_number_field(text: str) -> str:
    text = normalize_sticky_keywords(text)

    patterns = [
        r"\bLICEN[CS]E\s*NO\.?\s*",
        r"\bLICEN[CS]E\s*NUMBER\.?\s*",
        r"\bLIC\s*NO\.?\s*",
        r"\bLIC\.?\s*NO\.?\s*"
    ]

    for pattern in patterns:
        text = re.sub(pattern, "", text, flags=re.IGNORECASE)

    return re.sub(r"\s+", " ", text).strip()


def clean_expiry_date_field(text: str) -> str:
    text = normalize_sticky_keywords(text)

    patterns = [
        r"\bLICENSE\s*EXPIRES\b",
        r"\bLICENSE\s*EXPIRY\b",
        r"\bEXPIRY\s*DATE\b",
        r"\bEXPIRY\b",
        r"\bEXPIRES\b"
    ]

    for pattern in patterns:
        text = re.sub(pattern, "", text, flags=re.IGNORECASE)

    text = re.sub(r"\s+", " ", text).strip()
    return auto_format_date(text)

def clean_nt_number_prefix(text: str) -> str:
    """
    Removes number-dot (e.g. '1.', '2.', '5 . ') prefixes from NT license OCR text.
    """
    # Remove patterns like '1.', '2.', '5 .', '3. '
    return re.sub(r"^\s*\d+\s*\.\s*", "", text).strip()


def auto_format_date(text: str) -> str:
    """
    Tries to convert a raw OCR date string into 'DD MMM YYYY' format.
    If it can't parse the date, returns the original text.
    """
    # Remove non-alphanumeric separators
    cleaned = re.sub(r"[^A-Za-z0-9]", " ", text).upper().strip()

    # Try common date formats
    possible_formats = [
        "%d %m %Y", "%d %m %y",
        "%d %b %Y", "%d %b %y",
        "%d %B %Y", "%d %B %y",
        "%Y %m %d", "%Y %b %d", "%Y %B %d",
        "%d%m%Y", "%d%m%y",
        "%d%b%Y", "%d%b%y",
        "%Y%m%d", "%d %b %y", "%d%b%y", "%d%b%y"
    ]

    for fmt in possible_formats:
        try:
            parsed = datetime.strptime(cleaned, fmt)
            return parsed.strftime("%d %b %Y").upper()
        except ValueError:
            continue

    return text.strip()  # fallback if parsing fails

def normalize_sticky_keywords(text: str) -> str:
    """
    Inserts missing spaces in known sticky label patterns, e.g.,
    'DateofBirth' -> 'Date of Birth', 'ExpiryDate' -> 'Expiry Date'
    """
    corrections = {
        r"(?i)dateofbirth": "date of birth ",
        r"(?i)dateof8irth": "date of birth ",
        r"(?i)date ofbirth": "date of birth ",
        r"(?i)dateof birth": "date of birth ",
        r"(?i)dob": "dob ",
        r"(?i)expirydate": "expiry date ",
        r"(?i)expireson": "expires ",
        r"(?i)licenseexpires": "license expires ",
        r"(?i)licenseexpiry": "license expiry "
    }

    for pattern, replacement in corrections.items():
        text = re.sub(pattern, replacement, text)

    return text


def process_text(text: str, field_name: str = "", doc_type: str = "", state_code: str = "") -> str:
    # Remove number-dot prefixes for NT driver licenses only
    if doc_type == "driver_license" and state_code == "NT":
        if field_name in ["first_name", "last_name", "license_number", "address"]:
            text = clean_nt_number_prefix(text)

    text = separate_numbers_and_letters(text, field_name)

    if field_name.lower() == "address":
        text = fix_common_address_abbreviations(text)

    if field_name.lower() == "date_of_birth":
        text = clean_date_of_birth_field(text)

    if field_name.lower() == "license_number":
        text = clean_license_number_field(text)

    if field_name.lower() == "expiry_date":
        text = clean_expiry_date_field(text)

    text = split_sticky_text(text)

    doc = nlp(text)
    processed_text = " ".join(token.text for token in doc)
    return processed_text
