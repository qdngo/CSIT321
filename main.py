from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
from typing import List, Annotated

from models import PhotoCard, Passport, DriverLicense

app = FastAPI()

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
