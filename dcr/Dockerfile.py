# syntax=docker/dockerfile:1
# Build: docker build -f Dockerfile.py -t app .
ARG PYTHON_VERSION=3.14

FROM python:${PYTHON_VERSION}-slim-trixie AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Build deps for packages with C extensions (psycopg2, etc.)
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     build-essential gcc libpq-dev && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# ---- pip ----
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install -r requirements.txt

# ---- uv (replace pip block above; much faster) ----
# COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
# ENV UV_PROJECT_ENVIRONMENT=/opt/venv UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
# COPY pyproject.toml uv.lock ./
# RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev --no-install-project

FROM python:${PYTHON_VERSION}-slim-trixie AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Runtime libs only (no compilers)
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     libpq5 curl && rm -rf /var/lib/apt/lists/*

# Python as PID 1 ignores SIGTERM -> slow `docker stop`. Use tini here OR `init: true` in compose.
# RUN apt-get update && apt-get install -y --no-install-recommends tini && rm -rf /var/lib/apt/lists/*
# ENTRYPOINT ["/usr/bin/tini", "--"]

RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /usr/sbin/nologin --no-create-home appuser

COPY --from=builder /opt/venv /opt/venv
# Requires a .dockerignore, otherwise .git, .env, venv/ etc. end up in the image
COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 8000

# HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
#   CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=2)" || exit 1

CMD ["python", "main.py"]
# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
# CMD ["fastapi", "run", "main.py", "--port", "8000"]
# CMD ["gunicorn", "app:app", "-b", "0.0.0.0:8000", "-w", "4", "-k", "uvicorn.workers.UvicornWorker"]
