from sqlalchemy import Column, Integer, String, Date
from database import Base

class PhotoCard(Base):
    __tablename__ = 'photo_card'
    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String, index=True)
    last_name = Column(String, index=True)
    address = Column(String)
    photo_card_number = Column(String, unique=True)
    date_of_birth = Column(Date)
    card_number = Column(String)
    gender = Column(String)
    expiry_date = Column(Date)
    image_url = Column(String, nullable=True)

class Passport(Base):
    __tablename__ = 'passport'
    id = Column(Integer, primary_key=True, index=True)
    given_name = Column(String, index=True)
    last_name = Column(String, index=True)
    date_of_birth = Column(Date)
    document_number = Column(String, unique=True)
    expiry_date = Column(Date)
    gender = Column(String)
    image_url = Column(String, nullable=True)

class DriverLicense(Base):
    __tablename__ = 'driver_license'
    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String, index=True)
    last_name = Column(String, index=True)
    address = Column(String)
    card_number = Column(String, unique=True)
    license_number = Column(String, unique=True)
    date_of_birth = Column(Date)
    expiry_date = Column(Date)
    image_url = Column(String, nullable=True)