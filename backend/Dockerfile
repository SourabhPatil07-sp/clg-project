# Dockerfile for FastAPI application

FROM python:3.10

# Set the working directory
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose the port the app runs on
EXPOSE 8900

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8900"]