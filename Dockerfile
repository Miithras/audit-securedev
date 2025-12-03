# Dockerfile
FROM python:3.9-slim

WORKDIR /app

# Instalar dependencias
RUN pip install flask

# Copiar los scripts
COPY vulnerable_flask_app.py .
COPY create_db.py .

# Inicializar la DB y exponer puerto
RUN python create_db.py
EXPOSE 5000

# Ejecutar la app
CMD ["python", "vulnerable_flask_app.py"]