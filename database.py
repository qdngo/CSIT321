# database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

DATABASE_URL = "postgresql://postgres:12345678@localhost/csit321"

# Load environment variables
load_dotenv()

# Get the database URL from environment variables
DATABASE_URL = os.getenv("DATABASE_URL")

# Create the SQLAlchemy engine to connect to PostgreSQL
engine = create_engine(DATABASE_URL)

# Create a session factory that will allow the FastAPI app to interact with the database
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models (used to define the database schema)
Base = declarative_base()

# Create tables in the database
Base.metadata.create_all(bind=engine)
