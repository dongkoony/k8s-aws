## Terraform 변수 설정 파일 (terraform.tfvars)

[![EN](https://img.shields.io/badge/lang-en-blue.svg)](README-vars-en.md) 
[![KR](https://img.shields.io/badge/lang-kr-red.svg)](README-vars-kr.md)

이 파일은 AWS 인프라 구성에 필요한 주요 변수들을 정의합니다.

### 중요 안내사항
- 숫자형 변수는 따옴표("") 없이 입력해야 합니다.
  ```bash
  # 올바른 예시
  worker_instance_count = 2
  volume_size = 30
  
  # 잘못된 예시
  worker_instance_count = "2"    # 따옴표 사용하지 않음
  volume_size = "30"             # 따옴표 사용하지 않음
  ```

### 필수 설정 변수
```bash
region               = "YOUR-REGION"          # AWS 리전 (예: ap-northeast-2)
availability_zone    = "YOUR-AZ"              # 가용 영역 (예: ap-northeast-2a)
ami_id               = "YOUR-AMI-ID"          # Ubuntu 22.04 LTS AMI ID
```

### 인스턴스 설정
```bash
master_instance_type = "YOUR-MASTER-TYPE"     # 마스터 노드 유형 (권장: t3.medium)
node_instance_type   = "YOUR-WORKER-TYPE"     # 워커 노드 유형 (권장: t3.medium)
worker_instance_count = YOUR-WORKER-COUNT     # 워커 노드 수 (예: 2)
```

### 스토리지 설정
```bash
volume_size         = YOUR-VOLUME-SIZE        # 루트 볼륨 크기(GB) (예: 30)
volume_type         = "YOUR-VOLUME-TYPE"      # 볼륨 타입 (권장: gp3)
```

### SSH 접속 설정
```bash
key_name           = "YOUR-KEY-NAME"          # SSH 키 페어 이름
private_key_path   = "YOUR-KEY-PATH"          # 프라이빗 키 경로
private_key_name   = "YOUR-KEY-FILE-NAME"     # 프라이빗 키 파일명
```

### Ubuntu AMI 정보
| Ubuntu 버전 | AMI ID | 아키텍처 |
|------------|---------|----------|
| 22.04 LTS | ami-042e76978adeb8c48 | 64비트(x86) |
| 20.04 LTS | ami-08b2c3a9f2695e351 | 64비트(x86) |

**주의사항**: 
- 쿠버네티스 설치 스크립트는 Ubuntu 22.04 LTS를 기준으로 작성되었습니다.
- AMI ID는 리전별로 다를 수 있으니 확인 후 사용하세요.
- 프라이빗 키 경로는 절대 경로로 입력해야 합니다.

### 사용 예시
```bash
region               = "ap-northeast-2"
availability_zone    = "ap-northeast-2a"
ami_id               = "ami-042e76978adeb8c48"
master_instance_type = "t3.medium"
node_instance_type   = "t3.medium"
worker_instance_count = 2
volume_size          = 30
volume_type          = "gp3"
key_name             = "my-key"
private_key_path     = "/home/ubuntu/my-key.pem"
private_key_name     = "my-key.pem"
```

이 설정 파일은 Terraform을 통해 AWS에 쿠버네티스 클러스터를 자동으로 구축하는 데 사용됩니다.