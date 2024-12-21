from sqlalchemy import Column, Integer, String, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
from sqlalchemy.sql import func

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
    email = Column(String, ForeignKey('users.email'), nullable=False)  # Foreign key to User's email


class Passport(Base):
    __tablename__ = 'passport'
    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String, index=True)
    last_name = Column(String, index=True)
    date_of_birth = Column(Date)
    document_number = Column(String, unique=True)
    expiry_date = Column(Date)
    gender = Column(String)
    email = Column(String, ForeignKey('users.email'), nullable=False)  # Foreign key to User's email


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
    email = Column(String, ForeignKey('users.email'), nullable=False)  # Foreign key to User's email


class User(Base):
    __tablename__ = "users"
    email = Column(String, primary_key=True, unique=True, nullable=False, index=True)
    password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    passports = relationship("Passport", backref="user", cascade="all, delete-orphan")
    photo_cards = relationship("PhotoCard", backref="user", cascade="all, delete-orphan")
    driver_licenses = relationship("DriverLicense", backref="user", cascade="all, delete-orphan")