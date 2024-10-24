from sqlalchemy import Column, Integer, String
from .database import Base

class IDInformation(Base):
    __tablename__ = 'id_information'
    id = Column(Integer, primary_key=True, index=True)
    id_type = Column(String, index=True)
    full_name = Column(String, index=True)
    date_of_birth = Column(String)
    document_number = Column(String, unique=True)