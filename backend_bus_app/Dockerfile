# Stage 1: Builder - Install dependencies
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies (only what's needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# Stage 2: Runner - Minimal runtime image
FROM python:3.11-slim

WORKDIR /app

# Copy only installed packages from builder
COPY --from=builder /install /usr/local

# Copy only the app directory (not entire project)
COPY app/ ./app/

# Expose port
EXPOSE 8000

# Run the API (no --reload in production)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]