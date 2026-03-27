FROM python:3.12-slim

WORKDIR /app

# Install dependencies first (layer caching)
COPY pyproject.toml .
RUN pip install --no-cache-dir ".[prod]"

# Copy source
COPY src/ ./src/

# Non-root user — security best practice
RUN useradd -m -u 1000 gooclaim && chown -R gooclaim:gooclaim /app
USER gooclaim

# Build args for audit trail
ARG BUILD_ENV=dev
ARG BUILD_SHA=unknown
ENV BUILD_ENV=${BUILD_ENV} BUILD_SHA=${BUILD_SHA}

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
