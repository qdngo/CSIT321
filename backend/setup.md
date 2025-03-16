Before you begin, ensure you have the following installed:
1. Python 3.8 or later
2. PostgreSQL
3. Docker (optional, for containerization)

Installation
Clone the repository
git clone https://github.com/qdngo/CSIT321.git
cd CSIT321

Set up a virtual environment (optional but recommended)

python -m venv venv
source venv/bin/activate  # On Windows use `venv\Scripts\activate`

Install dependencies

pip install -r requirements.txt

Environment Variables Create a .env file in the root directory and populate it with the necessary environment variables:

DATABASE_URL=postgresql://username:password@localhost:5432/patientdb
SECRET_KEY=your_secret_key

Initialize the database

python manage.py migrate

Run the application

python manage.py runserver

Docker Setup (Optional)
If you prefer using Docker, follow these steps:

Build the Docker image

docker build -t patient-identity-management .

Run the Docker container

docker run -p 8000:8000 patient-identity-management
