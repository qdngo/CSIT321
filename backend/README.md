# 🦾 Armadillo Backend – Patient Identity Verification System

Welcome to the backend repository of the **Armadillo Project**, a smart healthcare solution developed to streamline patient identity verification using OCR and AI.

This backend system powers the secure API services and OCR processing capabilities behind Armadillo's mobile application. Built using **FastAPI**, **PostgreSQL**, and **PaddleOCR**, it provides endpoints for image upload, identity data extraction, user authentication, and secure data storage.

---

## 🚀 Features

- JWT-based user authentication and role management
- Image upload and real-time OCR processing (via PaddleOCR)
- PostgreSQL database with SQLAlchemy ORM
- RESTful API interface (`/docs`) with Swagger UI
- Environment-ready for Docker deployment
- Built-in CI/CD support with GitHub Actions

---

## 📦 Local Installation

### Prerequisites
- Python 3.11+
- pip
- PostgreSQL
- Git
- (Optional) Docker and Docker Compose

### 1. Clone the repository
```bash
git clone https://github.com/your-org/armadillo-backend.git
cd armadillo-backend
```

### 2. Set up a virtual environment
```bash
python -m venv venv
source venv/bin/activate      # Mac/Linux
venv\Scripts\activate         # Windows
```

### 3. Install dependencies
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Configure environment variables
Create a .env file in the project root directory with the following keys:

```bash
DATABASE_URL=postgresql://username:password@localhost:5432/armadillo_db
```

### 5. Run the FastAPI server
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 6. Open the API docs in your browser

http://localhost:8000/docs

## ✅ Testing & CI

This project uses GitHub Actions for CI. A workflow is configured in .github/workflows/ci.yml to:

Set up Python 3.11
Install dependencies from requirements.txt
Run flake8 for code linting
Run pytest (placeholder for future test coverage)

## 🗃️ Database Overview

This backend supports three main ID types:

passport
driver_license
photo_card
All identity records are linked to users via their registered email address using foreign key relationships.

## 📬 Feedback & Contributions

We welcome feature suggestions, testing feedback, and contributions.
Feel free to open an issue or submit a pull request!
