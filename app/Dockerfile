# Multi-stage build for security and efficiency
FROM python:3.11-slim as builder

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.11-slim

# Security: Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Security: Install security updates only
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Python packages from builder
COPY --from=builder /root/.local /home/appuser/.local

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser . .

# Security: Remove write permissions from application files
RUN chmod -R 555 /app

# Security: Create read-only tmp directory
RUN mkdir -p /tmp/app && chown appuser:appuser /tmp/app && chmod 755 /tmp/app

# Switch to non-root user
USER appuser

# Security: Set PATH for user packages
ENV PATH=/home/appuser/.local/bin:$PATH

# Security: Set secure environment variables
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV TMPDIR=/tmp/app

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

# Expose port
EXPOSE 8080

# Run application
CMD ["python", "app.py"]