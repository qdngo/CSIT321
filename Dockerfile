FROM python:3.11.7

WORKDIR /app

COPY . /app

# Install any Python dependencies
RUN pip install -r requirement.txt

# Expose the port FastAPI will run on
EXPOSE 8000

# Command to run FastAPI using Uvicorn
CMD uvicorn main:app --reload --port=8000 --host=0.0.0.0