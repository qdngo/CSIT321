# **OCR Backend**

This is a Django-based backend application for managing and handling `PhotoCard`, `Passport`, and `DriverLicense` data. It provides RESTful API endpoints for CRUD operations on these entities.

---

## **Table of Contents**

1. [Features](#features)
2. [Technologies Used](#technologies-used)
3. [Getting Started](#getting-started)
4. [API Endpoints](#api-endpoints)
5. [Notes](#notes)

---

## **Features**

- Create, read, update, and delete records for:
  - `PhotoCard`
  - `Passport`
  - `DriverLicense`
- REST API built using Django REST Framework.

---

## **Technologies Used**

- **Python** (3.8+)
- **Django** (5.x)
- **Django REST Framework** (DRF)
- **PostgreSQL** as the database

---

## **Getting Started**

Follow these steps to get the project up and running.

---

### **1. Clone the Repository**

Clone the repository from GitHub and navigate to the project directory:
```bash
git clone <repository-url>
cd ocr_be
```

### **2. Set Up a Virtual Environment**
Create and activate a Python virtual environment:
```bash
python -m venv env
source env/bin/activate  # On Mac/Linux
.\env\Scripts\activate   # On Windows
```

### **3. Install Dependencies**

Install the required Python packages listed in the `requirements.txt` file:

```bash
pip install -r requirements.txt
```

### **4. Set Up the Database**

1. Open your PostgreSQL terminal:
```bash
psql -U postgres
```

2. Create the database:
```bash
CREATE DATABASE csit321;
```

3. Update the .env file with your database credentials:
```bash
SECRET_KEY=your_secret_key
DEBUG=True
DATABASE_NAME=csit321
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password
DATABASE_HOST=localhost
DATABASE_PORT=5432
```

### **5. Configure Environment Variables**
Ensure the .env file is in the root of the project (same directory as manage.py) and includes all necessary variables:

SECRET_KEY (required)
Database settings: DATABASE_NAME, DATABASE_USER, DATABASE_PASSWORD, DATABASE_HOST, DATABASE_PORT.

### **6. Apply Migrations**
Run the following commands to create and apply the database tables:
```bash
python manage.py makemigrations
python manage.py migrate
```

### **7. Run the Development Server**
Start the server:
```bash
python manage.py runserver
```


