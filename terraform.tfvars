# ./terraform.tfvars

# 숫자형 변수(numbers)는 따옴표("") 없이 입력하세요. 예: worker_instance_count = 2
# For numeric variables, do not use quotes(""). ex: worker_instance_count = 2

region               = "YOUR-REGION"                # AWS 리전 / AWS Region. 예/ex: ap-northeast-2 (서울/Seoul)
availability_zone    = "YOUR-AZ"                    # 가용 영역 / Availability Zone. 예/ex: ap-northeast-2a
ami_id               = "YOUR-AMI-ID"                # AMI ID (Ubuntu 22.04 LTS 기준 k8s 설치 스크립트 작성) / AMI ID (k8s installation script based on Ubuntu 22.04 LTS)
master_instance_type = "YOUR-MASTER-TYPE"           # 마스터 노드 인스턴스 타입 / Master node instance type. 예/ex: t3.medium
node_instance_type   = "YOUR-WORKER-TYPE"           # 워커 노드 인스턴스 타입 / Worker node instance type. 예/ex: t3.medium
worker_instance_count= "YOUR-WORKER-COUNT"          # 워커 노드 수 / Number of worker nodes. 예/ex: 2
volume_size          = "YOUR-VOLUME-SIZE"           # 루트 볼륨 크기(GB) / Root volume size(GB). 예/ex: 30
volume_type          = "YOUR-VOLUME-TYPE"           # 볼륨 타입 / Volume type. 예/ex: gp3
key_name             = "YOUR-KEY-NAME"              # SSH 키 페어 이름 / SSH key pair name
private_key_path     = "YOUR-KEY-PATH"              # 프라이빗 키 경로 / Private key path. 예/ex: /home/ubuntu/your-key.pem
private_key_name     = "YOUR-KEY-FILE-NAME"         # 프라이빗 키 파일명 / Private key filename. 예/ex: your-key.pem





###################################################################################
# ---------------- Ubuntu 버전별 AMI ID / Ubuntu Version AMI IDs ------------------
###################################################################################

## Ubuntu Server 22.04 LTS (HVM)
## ami-042e76978adeb8c48 (64-bit(x86)) / (64비트(x86))

## Ubuntu Server 20.04 LTS (HVM)
## ami-08b2c3a9f2695e351 (64-bit(x86)) / (64비트(x86))