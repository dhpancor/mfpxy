FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8888

WORKDIR /mediaflow_proxy

RUN useradd -m mediaflow_proxy

# Instala Poetry globalmente mientras eres root
RUN pip install --no-cache-dir poetry

# Cambia la propiedad de la carpeta y cambia a usuario no-root
RUN chown -R mediaflow_proxy:mediaflow_proxy /mediaflow_proxy
USER mediaflow_proxy

# Copia archivos de configuración
COPY --chown=mediaflow_proxy:mediaflow_proxy pyproject.toml poetry.lock* /mediaflow_proxy/

RUN poetry config virtualenvs.in-project true && \
    poetry install --no-interaction --no-ansi --no-root --only main

COPY --chown=mediaflow_proxy:mediaflow_proxy . /mediaflow_proxy

EXPOSE 8888

CMD ["poetry", "run", "gunicorn", "mediaflow_proxy.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:${PORT}", "--timeout", "120", "--max-requests", "500", "--max-requests-jitter", "200", "--access-logfile", "-", "--error-logfile", "-", "--log-level", "info"]
