FROM python:3.10-slim-bullseye

WORKDIR /app

RUN apt-get update

RUN apt-get install -y --no-install-recommends \
    wget \
    sed \
    curl \
    procps \
    net-tools \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY .env ./.env

COPY . .

RUN chmod +x run_job.sh

RUN chmod +x start_run_job.sh

ENV PORT 10000

CMD ["/bin/bash", "-c", "gunicorn --bind 0.0.0.0:$PORT app:app"]
