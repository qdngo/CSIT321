


### Note for image storing:
Install these libraries:
pip install alembic
pip install python-multipart

For future schema updates:
alembic revision --autogenerate -m "Describe the change here"
alembic upgrade head
>>>>>>> 3990acbca691240cae609473e253cb960aba6487


🛠️ Backend Installation Setup (Planned Deployment)
This section outlines the future steps for installing and running the Armadillo backend system, which includes the API server, OCR service, and database integration.

🔧 System Requirements

Python 3.11+
pip (Python package manager)
PostgreSQL (hosted locally or on GCP/AWS RDS)
Docker (optional for containerized deployment)
Git
Environment variables file (.env)
📦 Local Installation (Manual)

Clone the Repository
git clone https://github.com/your-org/armadillo-backend.git
cd armadillo-backend
Set Up Virtual Environment
python -m venv venv
source venv/bin/activate  # For Mac/Linux
venv\Scripts\activate     # For Windows
Install Dependencies
pip install --upgrade pip
pip install -r requirements.txt
Configure Environment Variables
Create a .env file in the project root:
DATABASE_URL=postgresql://username:password@localhost:5432/armadillo_db
SECRET_KEY=your_secret_key
OCR_MODEL_PATH=./models/paddleocr/
Run the FastAPI Server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
Test the API
Open your browser and navigate to:
http://localhost:8000/docs
🐳 Docker Installation (Recommended for Deployment)

Build and Run Using Docker
docker build -t armadillo-backend .
docker run -d -p 8000:8000 --env-file .env armadillo-backend
Optional: Use Docker Compose
Add this docker-compose.yml file:
version: "3.8"
services:
  backend:
    build: .
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      - db
  db:
    image: postgres:13
    environment:
      POSTGRES_USER: youruser
      POSTGRES_PASSWORD: yourpassword
      POSTGRES_DB: armadillo_db
    ports:
      - "5432:5432"
Then run:

docker-compose up --build
✅ Verification

Visit http://localhost:8000/docs to test endpoints
Ensure OCR service responds by uploading a sample ID image
Confirm database writes using pgAdmin or CLI queries

