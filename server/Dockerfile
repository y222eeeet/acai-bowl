# 프로젝트 루트에서 빌드: docker build -f server/Dockerfile .
FROM python:3.11-slim

WORKDIR /app

COPY scripts/ ./scripts/
COPY server/ ./server/

RUN pip install --no-cache-dir -r server/requirements.txt

ENV PYTHONPATH=/app/scripts
EXPOSE 8080

CMD ["python", "-m", "uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8080"]
