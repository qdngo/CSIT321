import re
import spacy

nlp = spacy.load("en_core_web_sm")

def separate_numbers_and_letters(text: str) -> str:
    # Insert space between a digit followed by a letter, and vice versa.
    text = re.sub(r'(\d)([A-Za-z])', r'\1 \2', text)
    text = re.sub(r'([A-Za-z])(\d)', r'\1 \2', text)
    return text

def split_sticky_text(text: str) -> str:
    # Insert a space when a lowercase letter is followed by an uppercase letter.
    return re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', text)

def fix_common_address_abbreviations(text: str) -> str:
    """
    1) Add space after known abbreviations if they are not followed by whitespace.
    2) Add space before known abbreviations if they are not preceded by whitespace.
    3) Insert space around abbreviations if they appear in the middle of a word (e.g. JOHNSRDGREN).
    4) Add space before the suburb abbreviation (e.g., WOLLONGONGNSW -> WOLLONGONG NSW).
    """
    abbreviations = ["ST", "RD", "AVE", "NSW", "VIC", "QLD", "SA", "WA", "TAS", "ACT", "NT"]

    for abbr in abbreviations:
        # Case A: If abbreviation is stuck to the *following* text: "NSW2168" -> "NSW 2168"
        pattern_after = rf"\b{abbr}(?!\s)"
        text = re.sub(pattern_after, abbr + " ", text, flags=re.IGNORECASE)

        # Case B: If abbreviation is stuck to the *preceding* text: "JOHNSRD" -> "JOHNS RD"
        # This looks for a word boundary before the abbreviation or a run of letters, 
        # then the abbreviation, then a boundary or more letters.
        # Example: "([A-Za-z])RD([A-Za-z])" => "\1 RD \2"
        pattern_before = rf"([A-Za-z])({abbr})([A-Za-z])"
        text = re.sub(pattern_before, rf"\1 {abbr} \3", text, flags=re.IGNORECASE)

        # Case C: Add space before the suburb abbreviation (e.g., WOLLONGONGNSW -> WOLLONGONG NSW)
        pattern_suburb = rf"([A-Za-z])({abbr})"
        text = re.sub(pattern_suburb, rf"\1 {abbr}", text, flags=re.IGNORECASE)

    # Case D: Add space before the suburb code (e.g., NSW2500 -> NSW 2500)
    text = re.sub(r'(\b[A-Z]{3})(\d{4}\b)', r'\1 \2', text)

    # Remove potential extra spaces
    text = re.sub(r"\s+", " ", text).strip()
    return text

def process_text(text: str) -> str:
    # 1. Separate numbers from letters
    text = separate_numbers_and_letters(text)
    # 2. Fix known abbreviations
    text = fix_common_address_abbreviations(text)
    # 3. Split “sticky” upper/lower transitions
    text = split_sticky_text(text)
    # 4. Optionally refine further using spaCy tokenization
    doc = nlp(text)
    processed_text = " ".join(token.text for token in doc)
    return processed_text
