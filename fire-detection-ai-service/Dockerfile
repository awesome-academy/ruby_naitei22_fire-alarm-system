FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY model_server.py ./
COPY fire_detection_model.h5 ./

ENV MODEL_PATH=/app/fire_detection_model.h5
ENV IMG_SIZE=256
ENV PORT=5001
ENV PYTHONUNBUFFERED=1

EXPOSE 5001

CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:5001", "--timeout", "120", "model_server:app"]
