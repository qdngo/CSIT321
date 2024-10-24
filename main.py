from fastapi import Depends
from sqlalchemy.orm import Session
from .database import SessionLocal
from .models import IDInformation

app = FastAPI()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/store-id")
def store_id(data: dict, db: Session = Depends(get_db)):
    new_id = IDInformation(
        id_type=data['id_type'],
        full_name=data['full_name'],
        date_of_birth=data['date_of_birth'],
        document_number=data['document_number']
    )
    db.add(new_id)
    db.commit()
    db.refresh(new_id)
    return {"status": "ID information stored successfully", "id": new_id.id}

@app.get("/get-id/{id}")
def get_id(id: int, db: Session = Depends(get_db)):
    id_info = db.query(IDInformation).filter(IDInformation.id == id).first()
    if id_info is None:
        return {"status": "ID not found"}
    return {
        "id_type": id_info.id_type,
        "full_name": id_info.full_name,
        "date_of_birth": id_info.date_of_birth,
        "document_number": id_info.document_number
    }