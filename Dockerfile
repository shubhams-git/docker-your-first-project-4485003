# --- Stage 1: Build environment ---
    FROM python:3.12-slim-bookworm AS builder

    # Set working directory
    WORKDIR /app
    
    # Pre-install system dependencies
    RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential gcc libpq-dev curl && \
        rm -rf /var/lib/apt/lists/*
    
    # Copy only requirement files to cache dependencies
    COPY requirements.txt .
    
    # Install Python dependencies to a wheel cache
    RUN pip install --upgrade pip && \
        pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt
    
    # --- Stage 2: Runtime environment ---
    FROM python:3.12-slim-bookworm
    
    # Set working directory
    WORKDIR /app
    
    # Install only runtime dependencies
    COPY --from=builder /wheels /wheels
    COPY requirements.txt .
    RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt
    
    # Create non-root user
    RUN useradd -m flaskuser
    USER flaskuser
    
    # Copy application code
    COPY --chown=flaskuser:flaskuser . .
    
    # Set environment variables
    ENV FLASK_APP=app.py \
        FLASK_ENV=production \
        PYTHONDONTWRITEBYTECODE=1 \
        PYTHONUNBUFFERED=1
    
    # Expose port
    EXPOSE 5000
    
    # Run with Gunicorn (recommended in production)
    CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
    