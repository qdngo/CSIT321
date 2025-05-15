from fastapi import FastAPI, Depends, UploadFile, File, Form, HTTPException, status, Query
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from database import SessionLocal, create_tables
from typing import List, Annotated, Optional
from models import PhotoCard, Passport, DriverLicense, User
import os
from uuid import uuid4
from pydantic import BaseModel, EmailStr, Field
from jose import JWTError, jwt
from datetime import datetime, timedelta
import bcrypt
from ocr_utils import *
from nlp_utils import process_text  # Import the NLP post-processing function

# Initialize the application
app = FastAPI()


# Secret key and algorithm for JWT
SECRET_KEY = "CSIT321"  # Replace with a strong secret key
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Create tables at startup
# create_tables()

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Serve the static files from the 'uploads' directory
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]

@app.get("/")
def read_root():
    return {"message": "Welcome to the Armadillo Backend!"}


# ---------------------------- IMAGE PROCESSING FUNCTIONS ----------------------------
# Save uploaded file to a specific folder
def save_file(file: UploadFile, folder: str = "uploads") -> str:
    if not os.path.exists(folder):
        os.makedirs(folder)

    file_extension = file.filename.split(".")[-1]
    unique_filename = f"{uuid4()}.{file_extension}"
    file_path = os.path.join(folder, unique_filename)

    with open(file_path, "wb") as f:
        f.write(file.file.read())

    return file_path

async def process_document(file: UploadFile, region_func, doc_type: str) -> dict:
    """
    Common function to process a document:
      1. Reads the file.
      2. Preprocesses the image.
      3. Determines the image size.
      4. Defines OCR regions using the provided region function.
      5. Performs OCR and maps the results to fields.
      6. Applies post-processing to correct sticky text.
    """
    # Ensure the file is uploaded
    if not file:
        raise HTTPException(status_code=400, detail="File not uploaded.")
    
    # Read file data
    try:
        image_data = await file.read()
    except Exception:
        raise HTTPException(status_code=400, detail="Failed to read the uploaded file.")
    
    # Preprocess the image
    try:
        preprocessed_image = preprocess_image(image_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error during preprocessing: {str(e)}")
    
    # Get image dimensions (width, height)
    try:
        image_size = preprocessed_image.size
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error determining image size: {str(e)}")
    
    # Define regions, perform OCR, and map the results
    try:
        ocr_results = perform_ocr(preprocessed_image, debug=True)
        regions = region_func(image_size)
        state_code1 = detect_state_from_text(ocr_results)

        if doc_type == "driver_license":
            if state_code1 == "NSW":
                regions = define_nsw_license_regions(image_size)
            elif state_code1 == "VIC":
                regions = define_vic_license_regions(image_size)
            elif state_code1 == "QLD":
                regions = define_qld_license_regions(image_size)
            elif state_code1 == "SA":
                regions = define_sa_license_regions(image_size)
            elif state_code1 == "WA":
                regions = define_wa_license_regions(image_size)
            elif state_code1 == "TAS":
                regions = define_tas_license_regions(image_size)
            elif state_code1 == "ACT":
                regions = define_act_license_regions(image_size)
            elif state_code1 == "NT":
                regions = define_nt_license_regions(image_size)
            else:
                raise HTTPException(status_code=400, detail="Unable to detect state from license.")
        else:
            regions = region_func(image_size)
        
        
        #draw_ocr_boxes(preprocessed_image, ocr_results)
        #log_normalized_bboxes(ocr_results, image_size)
        
        
        extracted_data = map_ocr_to_fields(ocr_results, regions, doc_type=doc_type, state_code=state_code1)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error during OCR processing: {str(e)}")
    
    # Post-process each extracted field using the NLP function
    for field, text in extracted_data.items():
        if text:
            extracted_data[field] = process_text(text, field_name=field, doc_type=doc_type, state_code=state_code1)
    
    return {"doc_type": doc_type, "extracted_data": extracted_data}


def define_license_regions(image_size: tuple) -> dict:
    """
    Dummy function placeholder — actual region is selected in `process_document()`
    based on the detected state.
    """
    return {}

@app.post("/process_driver_license/")
async def process_driver_license(file: UploadFile = File(...)):
    """
    Handles uploaded NSW, VIC, QLD, ACT, and other AU driver licenses.
    Uses state-specific field mapping based on OCR-detected state code.
    """
    return await process_document(file, define_license_regions, "driver_license")

@app.post("/process_passport/")
async def process_passport(file: UploadFile = File(...)):
    return await process_document(file, define_passport_regions, "passport")

@app.post("/process_photo_card/")
async def process_photo_card(file: UploadFile = File(...)):
    return await process_document(file, define_photo_card_regions, "photo_card")

    
# --------------------------------------------------------------------------

# -------------- PYDANTIC MODELS FOR REQUEST VALIDATION --------------
class UserCreate(BaseModel):
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str

# -------------- UTILITY FUNCTIONS --------------
def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a hashed password."""
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))


def create_access_token(data: dict, expires_delta: timedelta = None):
    """Create a JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# -------------- ENDPOINTS --------------
@app.post("/signup", response_model=dict)
def signup(user: UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists using the email primary key
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # Hash the password and save user
    hashed_password = hash_password(user.password)
    new_user = User(email=user.email, password=hashed_password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"message": "User created successfully", "email": new_user.email}


@app.post("/login", response_model=Token)
def login(user: UserLogin, db: Session = Depends(get_db)):
    # Fetch the user by email
    db_user = db.query(User).filter(User.email == user.email).first()
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    # Verify password
    if not verify_password(user.password, db_user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    # Create JWT token
    access_token = create_access_token(data={"sub": db_user.email})
    return {"access_token": access_token, "token_type": "bearer"}

'''
# -------------- OCR FUNCTIONS --------------
@app.post("/ocr/")
async def ocr_endpoint(
    file: UploadFile = File(...),
    doc_type: str = Query(..., regex="^(photo_card|passport|driver_license)$")
):
    # Validate file type
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=400, detail="Invalid file format. Please upload a JPEG or PNG file.")
    
    # Read file data
    try:
        image_data = await file.read()
    except Exception:
        raise HTTPException(status_code=400, detail="Failed to read the uploaded file.")
    
    # Perform OCR
    ocr_results = perform_ocr(image_data)

    # Map fields based on document type
    if doc_type == "photo_card":
        extracted_data = map_ocr_to_fields(ocr_results, PHOTO_CARD_FIELDS)
    elif doc_type == "passport":
        extracted_data = map_ocr_to_fields(ocr_results, PASSPORT_FIELDS)
    elif doc_type == "driver_license":
        extracted_data = map_ocr_to_fields(ocr_results, DRIVER_LICENSE_FIELDS)
    else:
        raise HTTPException(status_code=400, detail="Unsupported document type.")

    return {"doc_type": doc_type, "extracted_data": extracted_data}

@app.post("/ocr/driver_license/")
async def extract_driver_license_fields(file: UploadFile = File(...)):
    # Ensure the file is uploaded correctly
    if not file:
        raise HTTPException(status_code=400, detail="File not uploaded.")
    
    # Read and preprocess the image
    image_data = await file.read()
    preprocessed_image = preprocess_image(image_data)
    
    # Perform OCR and map fields
    ocr_results = perform_ocr(preprocessed_image)
    regions = define_regions(preprocessed_image.size)
    extracted_fields = map_fields(ocr_results, regions)

    return {"extracted_fields": extracted_fields}
'''

# -------------- STORING FIELDS FROM FRONTEND FUNCTIONS --------------
# Define the Pydantic models for incoming payloads
class DriverLicensePayload(BaseModel):
    email: EmailStr
    first_name: str
    last_name: str
    address: str
    license_number: str
    card_number: str
    date_of_birth: str  # String in "DD MMM YYYY" format
    expiry_date: str    # String in "DD MMM YYYY" format

class PassportPayload(BaseModel):
    email: EmailStr
    first_name: str
    last_name: str
    date_of_birth: str  # String in "DD MMM YYYY" format
    document_number: str
    expiry_date: str    # String in "DD MMM YYYY" format
    gender: Optional[str]

class PhotoCardPayload(BaseModel):
    email: EmailStr
    first_name: str
    last_name: str
    address: str
    photo_card_number: str
    date_of_birth: str  # String in "DD MMM YYYY" format
    card_number: str
    gender: Optional[str]
    expiry_date: str    # String in "DD MMM YYYY" format
    
# Endpoint to store validated driver's license data
@app.post("/store_driver_license/")
async def store_driver_license(payload: DriverLicensePayload, db: Session = Depends(get_db)):
    # Ensure user exists
    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="User with the given email does not exist.")
    
    try:
        date_of_birth = datetime.strptime(payload.date_of_birth, "%d %b %Y").date()
        expiry_date = datetime.strptime(payload.expiry_date, "%d %b %Y").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use 'DD MMM YYYY'.")

    new_driver_license = DriverLicense(
        email=payload.email,
        first_name=payload.first_name,
        last_name=payload.last_name,
        address=payload.address,
        license_number=payload.license_number,
        card_number=payload.card_number,
        date_of_birth=date_of_birth,
        expiry_date=expiry_date,
    )

    db.add(new_driver_license)
    db.commit()
    db.refresh(new_driver_license)
    return {"message": "Driver license data stored successfully."}

# Endpoint to store validated passport data
@app.post("/store_passport/")
async def store_passport(payload: PassportPayload, db: Session = Depends(get_db)):
    # Ensure user exists
    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="User with the given email does not exist.")

    try:
        date_of_birth = datetime.strptime(payload.date_of_birth, "%d %b %Y").date()
        expiry_date = datetime.strptime(payload.expiry_date, "%d %b %Y").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use 'DD MMM YYYY'.")

    new_passport = Passport(
        email=payload.email,
        first_name=payload.first_name,
        last_name=payload.last_name,
        date_of_birth=date_of_birth,
        document_number=payload.document_number,
        expiry_date=expiry_date,
        gender=payload.gender,
    )

    db.add(new_passport)
    db.commit()
    db.refresh(new_passport)
    return {"message": "Passport data stored successfully."}

# Endpoint to store validated photo card data
@app.post("/store_photo_card/")
async def store_photo_card(payload: PhotoCardPayload, db: Session = Depends(get_db)):
    # Ensure user exists
    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="User with the given email does not exist.")

    try:
        date_of_birth = datetime.strptime(payload.date_of_birth, "%d %b %Y").date()
        expiry_date = datetime.strptime(payload.expiry_date, "%d %b %Y").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use 'DD MMM YYYY'.")

    new_photo_card = PhotoCard(
        email=payload.email,
        first_name=payload.first_name,
        last_name=payload.last_name,
        address=payload.address,
        photo_card_number=payload.photo_card_number,
        date_of_birth=date_of_birth,
        card_number=payload.card_number,
        gender=payload.gender,
        expiry_date=expiry_date,
    )

    db.add(new_photo_card)
    db.commit()
    db.refresh(new_photo_card)
    return {"message": "Photo card data stored successfully."}

# ---------------------------- RETRIEVAL ENDPOINTS ----------------------------
@app.get("/get-photo-card/")
def get_photo_card(email: str, db: Session = Depends(get_db)):
    photo_cards = db.query(PhotoCard).filter(PhotoCard.email == email).all()
    if not photo_cards:
        return {"status": "No photo cards found for the given email."}
    return photo_cards

@app.get("/get-passport/")
def get_passport(email: str, db: Session = Depends(get_db)):
    passports = db.query(Passport).filter(Passport.email == email).all()
    if not passports:
        return {"status": "No passports found for the given email."}
    return passports

@app.get("/get-driver-license/")
def get_driver_license(email: str, db: Session = Depends(get_db)):
    driver_licenses = db.query(DriverLicense).filter(DriverLicense.email == email).all()
    if not driver_licenses:
        return {"status": "No driver licenses found for the given email."}
    return driver_licenses

# ---------------------------- DELETE ACCOUNT ENDPOINTS ----------------------------
@app.delete("/delete_account")
def delete_account(email: str = Query(...), db: Session = Depends(get_db)):
    # Get the user
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Delete associated records
    db.query(PhotoCard).filter(PhotoCard.email == email).delete()
    db.query(DriverLicense).filter(DriverLicense.email == email).delete()
    db.query(Passport).filter(Passport.email == email).delete()

    # Delete the user
    db.delete(user)
    db.commit()

    return {"message": "User account and all associated data deleted successfully"}