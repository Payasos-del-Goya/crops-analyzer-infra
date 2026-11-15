# syntax=docker/dockerfile:1.7-labs
# Backend (FastAPI) de crops-analyzer. El código no está aquí: llega como contexto "app"
# (el repo crops-analyzer-backend, ver compose.yaml -> additional_contexts).
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Dependencias primero: si solo cambia el código, no se reinstalan.
COPY --from=app requirements.txt .
RUN pip install -r requirements.txt

COPY --from=app --exclude=.git --exclude=.venv --exclude=venv --exclude=**/__pycache__ --exclude=cache . .

# Usuario sin privilegios. cache/ guarda el clima de Meteomatics (volumen en compose).
RUN useradd --system --uid 1001 --home /app app \
    && mkdir -p /app/cache \
    && chown -R app /app/cache
USER app

EXPOSE 8000
# Un solo proceso: las cachés (Meteomatics, InfluxDB, Eurostat) y el precalentamiento viven en memoria.
CMD ["sh", "-c", "exec uvicorn main:app --host ${HOST:-0.0.0.0} --port ${PORT:-8000}"]
