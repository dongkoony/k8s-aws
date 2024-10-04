## 개요 (Overview)
이 레포지토리는 **Terraform**을 사용하여 **AWS EC2 인스턴스(Ubuntu 22.04LTS)** 위에 **Kubernetes(1.27) 클러스터**를 손쉽게 구축하고 실습할 수 있도록 설계된 인프라 코드입니다. EC2 인스턴스를 통해 Kubernetes 1.27 버전을 설치하고, Terraform의 **apply** 명령으로 인프라가 자동으로 설정됩니다. 또한, **destroy** 명령으로 인프라를 제거할 때는 EBS 스냅샷을 통해 데이터를 백업하며, 이후 **apply** 명령을 다시 실행할 경우 스냅샷을 통해 기존 데이터를 복원하여 인프라를 재구축합니다. 이 방식은 EC2 관련 비용을 절감하는 최적화된 인프라 관리 방식을 제공합니다.

## 목적 (Purpose)
이 프로젝트의 목적은 **Terraform**을 사용하여 AWS 인프라 안에서 **Kubernetes 클러스터**를 손쉽게 배포하고 관리하는 환경을 구축하는 것입니다. 사용자는 Terraform의 **apply** 명령을 통해 Kubernetes 클러스터가 자동으로 생성되고, **destroy** 시 스냅샷으로 데이터를 백업하여 비용 효율적으로 인프라를 관리할 수 있습니다. 스냅샷 복원 기능을 통해 인프라를 제거했다가 다시 생성하더라도 데이터를 유지할 수 있어 EC2 사용 비용을 최적화할 수 있습니다. 또한, 인프라 설정 과정에서 **SSH 포트(1717) 변경** 및 **서울 시간대 설정** 등과 같은 기본 설정도 자동으로 적용됩니다.

## 목표 (Goals)
- **Terraform**으로 AWS 인프라를 코드화하여 **Kubernetes 1.27** 클러스터 자동 배포
- EC2 인스턴스 생성 시 **SSH 포트(1717)** 변경 및 **서울 시간대(Asia/Seoul)** 설정
- **Master 노드**와 **Node**에 대한 인프라 배포 및 관리 자동화
- **Terraform 변수 파일**을 통해 인프라의 유지보수를 간편하게 관리

## Terraform 버전 (Terraform Version)
이 프로젝트는 다음 버전의 Terraform에서 테스트되었습니다.
- **Terraform 1.7 이상**

## 사용하는 법 (How to Use)

### 1. 환경 설정
먼저, [**Terraform**](https://developer.hashicorp.com/terraform/install#darwin)이 설치된 환경이 필요합니다. [AWS CLI](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/getting-started-install.html)도 필요하며, 올바르게 설정된 **AWS 자격 증명(AWS credentials)** 이 있어야 합니다.
```bash
aws configure (AWS 자격 증명 등록)
aws configure list (AWS 자격 증명 리스트)
```

### 2. 클론 레포지토리 (Clone the Repository)
레포지토리를 클론하여 프로젝트 폴더로 이동합니다

```bash
git clone https://github.com/dongkoony/k8s-aws
cd k8s-aws
```

### 3. [`terraform.tfvars`](https://github.com/dongkoony/k8s-aws/blob/master/terraform.tfvars) 파일 수정
프로젝트의 변수 관리를 쉽게 하기 위해, [`terraform.tfvars`](https://github.com/dongkoony/k8s-aws/blob/master/terraform.tfvars) 파일을 사용하고 있습니다. 각 변수를 **환경에 맞게** 수정합니다

```bash
# ./terraform.tfvars

region            = "YOUR-REGION"             # AWS에서 사용할 리전. 예: ap-northeast-2 (서울 리전)
availability_zone = "YOUR-AZ"                 # EC2 인스턴스가 생성될 가용 영역. 예: ap-northeast-2a
ami_id            = "ami-042e76978adeb8c48"   # 사용할 AMI ID **(Ubuntu 22.04 LTS AMI ID) 22.04 LTS 기준 k8s 설치 스크립트 작성 되어 있음.**
master_instance_type = "YOUR-MASTER-EC2-TYPE" # k8s-master 인스턴스 타입. 예: t3.small
node_instance_type   = "YOUR-NODE-EC2-TYPE"   # k8s-node 인스턴스 타입. 예: t2.micro
ebs_size             = 30                     # EBS 볼륨 크기 (GB). 예: 30GB
key_name             = "YOUR-KEY-NAME"        # EC2 인스턴스에 사용할 SSH 키 페어 이름
```

#### 변수 수정 및 유지보수 (How to Manage and Update Variables)
[`terraform.tfvars`](https://github.com/dongkoony/k8s-aws/blob/master/terraform.tfvars) 파일을 통해 모든 주요 변수를 유지보수할 수 있습니다. 이 파일에서 AWS 리전, EC2 인스턴스 유형, AMI ID 등을 수정할 수 있습니다. 예를 들어, 새로운 인스턴스 유형을 사용하려면 다음과 같이 변수 값을 변경합니다:

```bash
# 새로운 인스턴스 유형으로 변경
master_instance_type = "t3.medium"
node_instance_type   = "t3.micro"
```

변경 후에는 다시 `terraform plan`과 `terraform apply` 명령을 실행하여 인프라를 업데이트할 수 있습니다.

### 주요 변수:
- **`region`**: AWS 리전을 설정합니다.
- **`availability_zone`**: EC2 인스턴스가 생성될 가용 영역을 설정합니다.
- **`ami_id`**: 사용할 AMI ID를 설정합니다. (예: Ubuntu 22.04 LTS) **UBUNTU 22.04 LTS 기준으로 KUBERNETES 설치 스크립트 작성 되어 있음.**
- **`master_instance_type`**: Kubernetes 마스터 노드 인스턴스의 유형을 설정합니다.
- **`node_instance_type`**: Kubernetes 워커 노드 인스턴스의 유형을 설정합니다.
- **`ebs_size`**: EBS 볼륨 크기를 설정합니다.
- **`key_name`**: EC2 인스턴스에 사용할 SSH 키 페어 이름을 설정합니다.


### 4. Terraform 명령 실행

1. **초기화**: Terraform을 사용할 수 있도록 초기화합니다.
   ```bash
   terraform init
   ```

2. **인프라 계획**: Terraform이 생성할 리소스를 확인합니다.
   ```bash
   terraform plan
   ```
 
3. **인프라 배포**: Terraform을 사용해 AWS에 Kubernetes 클러스터를 배포합니다.
   ```bash
   terraform apply --auto-approve
   ```

4. **인프라 제거**: 더 이상 인프라가 필요 없을 때는 리소스를 제거합니다.
   ```bash
   terraform destroy --auto-approve
   ```

### 5. 스크립트 관리
EC2 인스턴스가 생성될 때 **SSH 포트 변경** 및 **서울 시간대 설정**, 그리고 **Kubernetes 설치**가 자동으로 이루어지도록 스크립트를 관리하고 있습니다.

- **SSH 포트 변경 및 시간대 설정 && Kubernetes 1.27 설치**: [`./script/combined_settings.sh`](https://github.com/dongkoony/k8s-aws/blob/master/script/combined_settings.sh)

스크립트는 EC2 인스턴스가 생성될 때 자동으로 실행됩니다. 필요에 따라 스크립트를 수정하거나 업데이트할 수 있습니다.


---

이 가이드를 통해 Terraform과 함께 Kubernetes 클러스터를 AWS에 손쉽게 배포하고 관리할 수 있습니다. 추가적인 도움이 필요하면 언제든지 이슈를 남겨주세요!

---

## 라이선스

이 프로젝트는 MIT 라이선스에 따라 라이선스가 부여됩니다. 자세한 내용은 [LICENSE](https://github.com/dongkoony/k8s-aws/blob/master/LICENSE) 파일을 참조하세요.