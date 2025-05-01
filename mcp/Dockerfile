# ── 1) Builder 스테이지: Poetry로 requirements.txt 생성
FROM python:3.12.2-slim AS builder
WORKDIR /app

# 시스템 패키지 설치 + Poetry 설치
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc python3-dev \
    && pip install --no-cache-dir poetry==2.1.2 poetry-plugin-export \
    && rm -rf /var/lib/apt/lists/*

# 의존성 정의 파일 복사 및 export
COPY pyproject.toml poetry.lock* ./
RUN poetry export \
    --format requirements.txt \
    --output requirements.txt \
    --without-hashes

# ── 2) Runtime 스테이지: 순수 런타임
FROM python:3.12.2-slim AS runtime
WORKDIR /app

# Builder에서 생성된 requirements만 복사 후 설치
COPY --from=builder /app/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 코드 복사
COPY *.py __init__.py ./

# 포트 노출 및 실행 커맨드
EXPOSE 8080
CMD ["python", "main.py"]
