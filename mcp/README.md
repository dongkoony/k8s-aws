# K8s-AWS MCP Server

[![Korean](https://img.shields.io/badge/lang-한국어-blue.svg)](README.md) [![English](https://img.shields.io/badge/lang-English-red.svg)](README-en.md)

실무에서 바로 사용 가능한 쿠버네티스 MCP(Model Context Protocol) 서버입니다. AI 어시스턴트(Claude, Cursor)를 통해 자연어로 쿠버네티스 클러스터를 제어하고 모니터링할 수 있습니다.

## 🚀 주요 기능

### 핵심 기능
| 카테고리 | 기능 | 설명 |
|---------|------|------|
| 쿠버네티스 기본 | Pod 관리 | 파드 생성/조회/삭제/상태확인 |
| | Deployment 관리 | 디플로이먼트 생성/수정/삭제/스케일링 |
| | 고급 기능 | HPA/StatefulSet/CronJob/카나리 배포 |
| AWS 통합 | EC2 관리 | 인스턴스 조회/시작/중지 |
| 승인 워크플로우 | Slack 통합 | 민감 작업 승인/알림/로깅 |

### 모니터링 기능
```
📊 클러스터 메트릭
 ├── CPU 사용량/용량/사용률
 ├── 메모리 사용량/용량/사용률
 └── 전체 클러스터 상태

🔍 파드 모니터링
 ├── 컨테이너별 리소스 사용량
 ├── 네임스페이스별 집계
 └── 상태 및 이벤트 추적

📝 로그 분석
 ├── 에러/경고/예외 탐지
 ├── 시간별 분석
 └── 컨테이너별 분석
```

## 🛠 설치 방법

### 요구사항
- Python 3.11+
- Kubernetes 클러스터 접근 권한
- AWS 자격 증명 (EC2 관리용)
- Slack Workspace (승인 워크플로우용)

### 설치
```bash
# 프로젝트 클론
git clone https://github.com/dongkoony/k8s-aws.git
cd k8s-aws/mcp

# 의존성 설치
poetry install
```

## ⚙️ 설정

### 1. Kubernetes 설정
```bash
# kubeconfig 설정 확인
kubectl config view

# 컨텍스트 설정
kubectl config use-context your-context
```

### 2. Slack 설정
```python
# workflows/slack_approval.py 수정
SLACK_BOT_TOKEN = "your-bot-token"
SLACK_CHANNEL_ID = "your-channel-id"
```

### 3. AWS 설정
```bash
# AWS 자격 증명 설정
aws configure
```

## 🚀 실행 방법

### 서버 시작
```bash
poetry run python main.py
```

### AI 어시스턴트 연동
```json
// ~/.config/claude/mcp.json 또는 ~/.cursor/mcp.json
{
  "mcpServers": {
    "kubernetes": {
      "command": "python",
      "args": ["-m", "k8s_aws_copilot.minimal_wrapper"],
      "env": {
        "KUBECONFIG": "/path/to/your/.kube/config"
      }
    }
  }
}
```

## 📚 사용 예시

### 1. 파드 관리
```python
# 파드 목록 조회
response = await mcp.tools.list_pods(namespace="default")

# 파드 생성
response = await mcp.tools.create_pod(
    name="nginx",
    image="nginx:latest",
    namespace="default"
)
```

### 2. 모니터링
```python
# 클러스터 메트릭 조회
metrics = await mcp.tools.get_cluster_metrics()

# 파드 로그 분석
logs = await mcp.tools.get_pod_logs_analysis(
    namespace="default",
    pod_name="nginx",
    hours=1
)
```

### 3. 승인 워크플로우
```python
# EC2 인스턴스 중지 (승인 필요)
response = await mcp.tools.stop_ec2_instance(
    instance_id="i-1234567890abcdef0",
    user="admin"
)
```

## 🔒 보안 기능

- Slack 기반 승인 워크플로우
- 민감 작업 로깅
- 작업 결과 알림
- AWS 자격 증명 관리

## 📊 모니터링 대시보드

| 메트릭 | 설명 | 갱신 주기 |
|--------|------|-----------|
| 클러스터 상태 | CPU/메모리 사용률 | 실시간 |
| 노드 상태 | 준비성/압박 상태 | 1분 |
| 파드 상태 | 실행/오류/재시작 | 30초 |
| 이벤트 | 경고/오류/정보 | 실시간 |

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🌟 크레딧

이 프로젝트는 [kubectl-mcp-server](https://github.com/rohitg00/kubectl-mcp-server)를 참고하여 제작되었습니다. 