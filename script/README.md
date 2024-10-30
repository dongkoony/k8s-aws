# Kubernetes 1.27 자동 설치 스크립트

[![EN](https://img.shields.io/badge/lang-en-blue.svg)](README-en.md) 
[![KR](https://img.shields.io/badge/lang-kr-red.svg)](README.md)

AWS EC2 인스턴스(UBUNTU 22.04LTS)에 Kubernetes 1.27 클러스터를 자동으로 구축하는 스크립트입니다. 시스템 설정, 네트워크 구성, Docker 설치, Kubernetes 설치 및 초기화를 자동화합니다.

## 주요 기능

- Kubernetes 1.27 버전 자동 설치
- Docker 및 containerd 설치 및 구성
- 시스템 시간대 자동 설정 (Asia/Seoul)
- SSH 보안 강화 (포트 변경)
- Calico CNI 네트워크 플러그인 설치
- 마스터/워커 노드 자동 구성

## 환경 변수 설정 가이드

스크립트의 동작을 사용자의 환경에 맞게 수정하려면 다음 환경 변수들을 조정하시면 됩니다:

### 시스템 설정
```bash
# 로그 설정
LOG_FILE="/home/ubuntu/combined_settings.log"  # 로그 파일 위치
LOG_PREFIX="[K8S-SETUP]"                      # 로그 접두사

# 기본 시스템 설정
TIMEZONE="Asia/Seoul"                         # 시스템 시간대
SSH_PORT="1717"                               # SSH 포트 번호
SSH_CONFIG="/etc/ssh/sshd_config"             # SSH 설정 파일 위치
```

### 쿠버네티스 설정
```bash
# 네트워크 설정
POD_CIDR="10.244.0.0/16"                     # Pod 네트워크 대역
CNI_VERSION="v3.14"                          # Calico CNI 버전
CNI_MANIFEST="https://docs.projectcalico.org/v3.14/manifests/calico.yaml"

# 쿠버네티스 버전
K8S_VERSION="1.27.16-1.1"                    # 쿠버네티스 버전
```

### 시스템 요구사항
```bash
MIN_CPU_CORES=2                              # 최소 CPU 코어 수
MIN_MEMORY_GB=2                              # 최소 메모리 (GB)
REQUIRED_PORTS=(6443 10250 10251 10252)      # 필요한 포트 번호
```

### 재시도 설정
```bash
MAX_RETRIES=3                                # 최대 재시도 횟수
RETRY_INTERVAL=30                            # 재시도 간격 (초)
WAIT_INTERVAL=10                             # 대기 간격 (초)
```

## 시스템 요구사항

- Ubuntu 운영체제
- 최소 2 CPU 코어
- 최소 2GB RAM
- 인터넷 연결
- root 또는 sudo 권한

## 로그 확인

설치 과정은 다음 위치에서 확인할 수 있습니다:
```bash
tail -f /home/ubuntu/combined_settings.log
```

## 주의사항

- 스크립트는 **Ubuntu22.04LTS** 운영체제에서 테스트되었습니다.
- 실행 전 시스템(EC2 인스턴스) 요구사항을 충족하는지 확인하세요.
- 방화벽 설정에서 필요한 포트가 열려있는지 확인하세요.

## 문제 해결

설치 중 문제가 발생하면 다음 로그 파일들을 확인하세요:
- `/home/ubuntu/combined_settings.log`: 전체 설치 로그
- `/var/log/kubeadm_init.log`: kubeadm 초기화 로그
- `journalctl -xeu kubelet`: kubelet 서비스 로그

## 라이센스

이 프로젝트는 [MIT 라이센스](https://github.com/dongkoony/k8s-aws/blob/master/LICENSE) 하에 있습니다. 자세한 내용은 [LICENSE](https://github.com/dongkoony/k8s-aws/blob/master/LICENSE) 파일을 참조하세요.