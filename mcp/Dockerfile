# 빌드 단계: Poetry 사용
FROM python:3.12.2-slim AS builder

# 시스템 패키지 업데이트 및 보안 패치
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Poetry 설치 및 export 플러그인 추가
RUN pip install poetry==2.1.2
RUN pip install poetry-plugin-export

# 프로젝트 의존성 파일 복사
COPY pyproject.toml poetry.lock* ./

# Poetry를 사용하여 의존성을 requirements.txt 형식으로 내보내기
RUN poetry export > requirements.txt

# 런타임 단계: pip 사용
FROM python:3.12.2-slim

# 시스템 패키지 업데이트 및 보안 패치
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 생성
WORKDIR /app

# 빌드 단계에서 생성한 requirements.txt 파일만 복사
COPY --from=builder requirements.txt /app/

# pip를 사용하여 의존성 설치
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 소스 코드 복사
COPY *.py /app/
COPY __init__.py /app/

# 포트 노출
EXPOSE 8080

# 컨테이너 시작 시 실행할 명령어 설정
CMD ["python", "main.py"]
