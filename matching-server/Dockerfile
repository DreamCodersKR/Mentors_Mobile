FROM python:3.12-slim

WORKDIR /app

# 필요한 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 필요한 Python 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 서비스 계정 키 파일 복사
COPY key_folder /app/key_folder

# 애플리케이션 코드 복사
COPY . .

# 8080 포트 노출
EXPOSE 8080

# 서버 실행
CMD ["gunicorn", "--bind", "0.0.0.0:8080","--workers", "2",  "--worker-class", "sync",  "main:app"]