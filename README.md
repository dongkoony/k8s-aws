# Kubernetes on AWS with Terraform

[![EN](https://img.shields.io/badge/lang-en-blue.svg)](README-en.md) 
[![KR](https://img.shields.io/badge/lang-kr-red.svg)](README.md)

## 개요 (Overview)
이 레포지토리는 **Terraform**을 사용하여 **AWS EC2 인스턴스(Ubuntu 22.04 LTS)** 위에 **Kubernetes v1.31 클러스터와 Calico CNI v3.28.0**를 손쉽게 구축하고 실습할 수 있도록 설계된 인프라 코드입니다. EC2 인스턴스를 통해 Kubernetes를 설치하고, Terraform의 **apply** 명령으로 인프라가 자동으로 설정됩니다.

## 기술 스택 (Tech Stack)
- **Kubernetes**: v1.31
- **CNI**: Calico v3.28.0
- **운영체제**: Ubuntu 22.04 LTS
- **클라우드**: AWS
- **IaC**: Terraform 1.8+

## 시스템 요구사항 (System Requirements)
- **마스터 노드**: 최소 t3.medium (2 vCPU, 4GB RAM)
- **워커 노드**: 최소 t3.medium (2 vCPU, 4GB RAM)
- **스토리지**: 최소 30GB gp3 EBS 볼륨
- **네트워크**: VPC 내 프라이빗 서브넷

## 주요 기능 (Key Features)
- Kubernetes v1.31 클러스터 자동 구성
- Calico CNI v3.28.0 자동 설치 및 구성
- SSH 보안 강화 (포트 변경)
- 서울 시간대 자동 설정
- 워커 노드 자동 조인

## 아키텍처 (Architecture)
- **마스터 노드**: 컨트롤 플레인 구성 요소 실행
- **워커 노드**: 애플리케이션 워크로드 실행
- **네트워킹**: Calico CNI를 통한 파드 네트워크 구성
- **스토리지**: gp3 EBS 볼륨을 통한 영구 스토리지 제공

## 목적 (Purpose)
이 프로젝트의 목적은 **Terraform**을 사용하여 AWS 인프라 안에서 **Kubernetes 클러스터**를 손쉽게 배포하고 관리하는 환경을 구축하는 것입니다. 사용자는 Terraform의 **apply** 명령을 통해 Kubernetes 클러스터가 자동으로 생성되고 관리됩니다.

## 목표 (Goals)
- **Terraform**으로 AWS 인프라를 코드화하여 **Kubernetes v1.31** 클러스터 자동 배포
- EC2 인스턴스 생성 시 **SSH 포트** 변경 및 **서울 시간대(Asia/Seoul)** 설정
- **Master 노드**와 **Worker 노드**에 대한 인프라 배포 및 관리 자동화
- **Terraform 변수 파일**을 통해 인프라의 유지보수를 간편하게 관리

## 사용하는 법 (How to Use)

### 1. 환경 설정
먼저, [**Terraform**](https://developer.hashicorp.com/terraform/install#darwin)이 설치된 환경이 필요합니다. [AWS CLI](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/getting-started-install.html)도 필요하며, 올바르게 설정된 **AWS 자격 증명(AWS credentials)** 이 있어야 합니다.
```bash
aws configure    # AWS 자격 증명 등록
aws configure list    # AWS 자격 증명 리스트
```

### 2. 클론 레포지토리 (Clone the Repository)
```bash
git clone https://github.com/dongkoony/k8s-aws
cd k8s-aws
```

### 3. 변수 설정 파일 수정
[`terraform.tfvars`](terraform.tfvars) 파일을 환경에 맞게 수정합니다. 자세한 설정 방법은 [변수 설정 가이드](https://github.com/dongkoony/k8s-aws/blob/master/README/README-vars-kr.md)를 참조하세요.

```bash
region               = "YOUR-REGION"                # AWS 리전 예: ap-northeast-2 (서울/Seoul)
availability_zone    = "YOUR-AZ"                    # 가용 영역 예: ap-northeast-2a
ami_id               = "YOUR-AMI-ID"                # AMI ID (Ubuntu 22.04 LTS 기준 k8s 설치 스크립트 작성)
master_instance_type = "YOUR-MASTER-TYPE"           # 마스터 노드 인스턴스 타입 예: t3.medium
node_instance_type   = "YOUR-WORKER-TYPE"           # 워커 노드 인스턴스 타입 예: t3.medium
worker_instance_count= "YOUR-WORKER-COUNT"          # 워커 노드 수 예: 2
volume_size          = "YOUR-VOLUME-SIZE"           # 루트 볼륨 크기(GB)
volume_type          = "YOUR-VOLUME-TYPE"           # 볼륨 타입 예: gp3
key_name             = "YOUR-KEY-NAME"              # SSH 키 페어 이름
private_key_path     = "YOUR-KEY-PATH"              # 프라이빗 키 경로  예: /home/ubuntu/your-key.pem
private_key_name     = "YOUR-KEY-FILE-NAME"         # 프라이빗 키 파일 예: your-key.pem
```

### 4. Terraform 명령 실행
```bash
terraform init    # 초기화
terraform plan    # 실행 계획 확인
terraform apply --auto-approve      # 인프라 배포
terraform destroy --auto-approve    # 인프라 제거
```

## 주의사항 (Precautions)
- Kubernetes v1.31과 Calico v3.28.0 버전에 최적화되어 있습니다
- Ubuntu 22.04 LTS에서만 테스트되었습니다
- t3.medium 이상의 인스턴스 타입을 권장합니다
- gp3 볼륨 타입 사용을 권장합니다

## 문제 해결 (Troubleshooting)
문제 발생 시 다음을 확인하세요:
- AWS 자격 증명이 올바르게 설정되었는지 확인
- 필요한 AWS 권한이 있는지 확인
- 인스턴스 타입과 볼륨 크기가 요구사항을 충족하는지 확인
- 네트워크 설정이 올바른지 확인

## 라이선스 (License)
이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

추가 문의사항이나 기여하고 싶은 부분이 있다면 이슈를 생성하거나 풀 리퀘스트를 보내주세요.