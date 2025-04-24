# === builder 단계 ===
FROM python:3.12.2-slim AS builder

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends gcc python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Poetry + export 플러그인 설치 (poetry --version 2.1.2)
RUN pip install poetry poetry-plugin-export

# 의존성 파일 복사 및 export
COPY pyproject.toml poetry.lock* ./
RUN poetry export -f requirements.txt -o requirements.txt --without-hashes


# === runtime 단계 ===
FROM python:3.12.2-slim

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends gcc python3-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 빌드 결과물만 복사
COPY --from=builder requirements.txt /app/

# 종속성 설치
RUN pip install --no-cache-dir -r requirements.txt

# 앱 소스 복사
COPY *.py __init__.py /app/

EXPOSE 8080

CMD ["python", "fastmcp_server.py"]
