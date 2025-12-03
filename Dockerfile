FROM python:3.9-slim

WORKDIR /app

# Copiamos los archivos necesarios
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiamos el código fuente y el script de la BD
COPY app.py .
COPY create_db.py .

# Ejecutamos la creación de la base de datos durante la construcción de la imagen
RUN python create_db.py

# Exponemos el puerto 5000
EXPOSE 5000

# Comando para iniciar la aplicación
CMD ["python", "app.py"]