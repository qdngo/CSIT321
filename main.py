from fastapi import FastAPI, Depends, UploadFile, File, Form, HTTPException, status
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from database import SessionLocal
from typing import List, Annotated
from models import PhotoCard, Passport, DriverLicense, User
import os
from uuid import uuid4
from pydantic import BaseModel, EmailStr
from jose import JWTError, jwt
from datetime import datetime, timedelta
import bcrypt


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
    return {"message": "Welcome to the OCR Backend!"}

# -------------- STORE FUNCTIONS --------------
@app.post("/store-photo-card")
def store_photo_card(data: dict, db: db_dependency):
    new_photo_card = PhotoCard(
        first_name=data['first_name'],
        last_name=data['last_name'],
        address=data['address'],
        photo_card_number=data['photo_card_number'],
        date_of_birth=data['date_of_birth'],
        card_number=data['card_number'],
        gender=data['gender'],
        expiry_date=data['expiry_date']
    )
    db.add(new_photo_card)
    db.commit()
    db.refresh(new_photo_card)
    return {"status": "Photo card information stored successfully", "id": new_photo_card.id}

@app.post("/store-passport")
def store_passport(data: dict, db: Session = Depends(get_db)):
    new_passport = Passport(
        given_name=data['given_name'],
        last_name=data['last_name'],
        date_of_birth=data['date_of_birth'],
        document_number=data['document_number'],
        expiry_date=data['expiry_date'],
        gender=data['gender']
    )
    db.add(new_passport)
    db.commit()
    db.refresh(new_passport)
    return {"status": "Passport information stored successfully", "id": new_passport.id}

@app.post("/store-driver-license")
def store_driver_license(data: dict, db: Session = Depends(get_db)):
    new_driver_license = DriverLicense(
        first_name=data['first_name'],
        last_name=data['last_name'],
        address=data['address'],
        card_number=data['card_number'],
        license_number=data['license_number'],
        date_of_birth=data['date_of_birth'],
        expiry_date=data['expiry_date']
    )
    db.add(new_driver_license)
    db.commit()
    db.refresh(new_driver_license)
    return {"status": "Driver license information stored successfully", "id": new_driver_license.id}
# ------------------------------------------

# -------------- STORE ID CARDS FUNCTIONS --------------
@app.get("/get-photo-card/{id}")
def get_photo_card(id: int, db: Session = Depends(get_db)):
    photo_card = db.query(PhotoCard).filter(PhotoCard.id == id).first()
    if photo_card is None:
        return {"status": "Photo card not found"}
    return photo_card

@app.get("/get-passport/{id}")
def get_passport(id: int, db: Session = Depends(get_db)):
    passport = db.query(Passport).filter(Passport.id == id).first()
    if passport is None:
        return {"status": "Passport not found"}
    return passport

@app.get("/get-driver-license/{id}")
def get_driver_license(id: int, db: Session = Depends(get_db)):
    driver_license = db.query(DriverLicense).filter(DriverLicense.id == id).first()
    if driver_license is None:
        return {"status": "Driver license not found"}
    return driver_license
# ------------------------------------------


# -------------- IMAGE PROCESSING FUNCTIONS --------------
def save_file(file: UploadFile):
    """Save uploaded file to the uploads directory."""
    file_extension = file.filename.split(".")[-1].lower()
    if file_extension not in ["jpg", "jpeg", "png"]:
        raise HTTPException(status_code=400, detail="Unsupported file format")

    unique_filename = f"{uuid4().hex}.{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)

    with open(file_path, "wb") as f:
        f.write(file.file.read())
    return file_path

@app.post("/process-photo-card")
async def process_photo_card(file: UploadFile = File(...), db: Session = Depends(get_db)):
    # Step 1: Save the image
    file_path = save_file(file)

    # Step 2: Save the image URL to the database
    new_photo_card = PhotoCard(
        first_name=None,
        last_name=None,
        address=None,
        photo_card_number=None,
        date_of_birth=None,
        card_number=None,
        gender=None,
        expiry_date=None,
        image_url=file_path
    )
    db.add(new_photo_card)
    db.commit()
    db.refresh(new_photo_card)

    # Step 3: Mock OCR data
    ocr_data = {
        "first_name": "John",
        "last_name": "Doe",
        "address": "123 Elm Street",
        "date_of_birth": "1990-01-01",
        "gender": "M"
    }

    return {
        "image_url": file_path,
        "ocr_data": ocr_data,
        "id": new_photo_card.id
    }

@app.post("/process-passport")
async def process_passport(file: UploadFile = File(...), db: Session = Depends(get_db)):
    # Step 1: Save the image
    file_path = save_file(file)

    # Step 2: Save the image URL to the database
    new_passport = Passport(
        given_name=None,
        last_name=None,
        date_of_birth=None,
        document_number=None,
        expiry_date=None,
        gender=None,
        image_url=file_path
    )
    db.add(new_passport)
    db.commit()
    db.refresh(new_passport)

    # Step 3: Mock OCR data
    ocr_data = {
        "given_name": "Jane",
        "last_name": "Smith",
        "date_of_birth": "1988-05-20",
        "document_number": "P12345678",
        "expiry_date": "2030-05-20",
        "gender": "F"
    }

    return {
        "image_url": file_path,
        "ocr_data": ocr_data,
        "id": new_passport.id
    }


@app.post("/process-driver-license")
async def process_driver_license(file: UploadFile = File(...), db: Session = Depends(get_db)):
    # Step 1: Save the image
    file_path = save_file(file)

    # Step 2: Save the image URL to the database
    new_driver_license = DriverLicense(
        first_name=None,
        last_name=None,
        address=None,
        card_number=None,
        license_number=None,
        date_of_birth=None,
        expiry_date=None,
        image_url=file_path
    )
    db.add(new_driver_license)
    db.commit()
    db.refresh(new_driver_license)

    # Step 3: Mock OCR data
    ocr_data = {
        "first_name": "Alice",
        "last_name": "Johnson",
        "address": "456 Oak Street",
        "card_number": "DLC987654",
        "license_number": "LIC123456",
        "date_of_birth": "1978-09-30",
        "expiry_date": "2030-09-30"
    }

    return {
        "image_url": file_path,
        "ocr_data": ocr_data,
        "id": new_driver_license.id
    }
    
# ----------------------------------------------

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
    # Check if user already exists
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

    return {"message": "User created successfully"}


@app.post("/login", response_model=Token)
def login(user: UserLogin, db: Session = Depends(get_db)):
    # Check if user exists
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