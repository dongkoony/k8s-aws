# 빌드 단계: Poetry 사용
# 여기서는 Python 3.12 slim 이미지를 기반으로 빌드 단계 시작 (builder라는 이름으로 지정)
FROM python:3.12.2-slim AS builder

# 시스템 패키지 업데이트 및 보안 패치
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Poetry 패키지 매니저 설치 (의존성 관리를 위해 필요)
RUN pip install poetry

# 프로젝트 의존성 파일 복사 (pyproject.toml과 poetry.lock)
# '*'는 poetry.lock 파일이 존재하지 않을 경우에도 오류 없이 진행하기 위함
COPY pyproject.toml poetry.lock* ./

# Poetry를 사용하여 의존성을 requirements.txt 형식으로 내보내기
# --without-hashes 옵션은 해시 정보를 제외하여 pip 설치 시 호환성 문제 방지
RUN poetry export -f requirements.txt -o requirements.txt --without-hashes

# 런타임 단계: pip 사용
# 이미지 크기 최적화를 위해 다시 Python 3.12 slim 이미지에서 시작
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
# 이는 Poetry와 관련된 모든 도구를 최종 이미지에서 제외하여 크기 감소
COPY --from=builder requirements.txt /app/

# pip를 사용하여 의존성 설치
# --no-cache-dir 옵션은 캐시를 사용하지 않아 이미지 레이어 크기 최소화
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 소스 코드 복사
# 의존성 설치 후에 소스 코드를 복사하여 코드 변경 시 캐시 레이어 재사용 최적화
# mcp 디렉토리의 모든 Python 파일과 기타 필요 파일을 복사
COPY *.py /app/
COPY __init__.py /app/

# 포트 노출 (필요한 경우)
EXPOSE 8080

# 컨테이너 시작 시 실행할 명령어 설정
# main.py 직접 실행
CMD ["python", "main.py"]
