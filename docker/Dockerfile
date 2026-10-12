# Contenedor del ETL: solo se conecta a la red interna etl-red (sin salida a internet ni a producción).
FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && useradd -m etl
USER etl
WORKDIR /app/etl
ENTRYPOINT ["python", "-m", "adn_etl"]
