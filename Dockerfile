FROM python:3.12-slim

# Evita la creación de archivos .pyc y fuerza el buffer de stdout/stderr sin buffering
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Se asigna un puerto por defecto, el que Heroku provea sobrescribirá este valor
ENV PORT=8888

# Establece el directorio de trabajo
WORKDIR /mediaflow_proxy

# Crea un usuario no-root y asigna permisos
RUN useradd -m mediaflow_proxy && \
    chown -R mediaflow_proxy:mediaflow_proxy /mediaflow_proxy

# Actualiza el PATH para incluir los binarios personales
ENV PATH="/home/mediaflow_proxy/.local/bin:$PATH"

# Cambia al usuario no-root
USER mediaflow_proxy

# Instala Poetry usando pip
RUN pip install --user --no-cache-dir poetry

# Copia los archivos de configuración para cachear las dependencias
COPY --chown=mediaflow_proxy:mediaflow_proxy pyproject.toml poetry.lock* /mediaflow_proxy/

# Configura Poetry e instala las dependencias necesarias (sin incluir el paquete raíz)
RUN poetry config virtualenvs.in-project true && \
    poetry install --no-interaction --no-ansi --no-root --only main

# Copia el resto del proyecto
COPY --chown=mediaflow_proxy:mediaflow_proxy . /mediaflow_proxy

# Expone el puerto configurado (aunque EXPOSE es informativo y no configura el binding real)
EXPOSE 8888

# Inicia la aplicación usando Gunicorn, enlazando al puerto definido por Heroku a través de la variable PORT
CMD sh -c 'poetry run gunicorn mediaflow_proxy.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:${PORT} --timeout 120 --max-requests 500 --max-requests-jitter 200 --access-logfile - --error-logfile - --log-level info'
