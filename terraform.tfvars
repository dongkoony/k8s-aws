region            = "ap-northeast-2"           # AWS에서 사용할 리전. 예: ap-northeast-2 (서울 리전)
availability_zone = "ap-northeast-2a"          # EC2 인스턴스가 생성될 가용 영역. 예: ap-northeast-2a
ami_id            = "ami-XXXXXX"               # 사용할 AMI ID (Ubuntu 22.04 LTS AMI ID)
master_instance_type = "t3.small"              # k8s-master 인스턴스 타입. 예: t3.small
node_instance_type   = "t2.micro"              # k8s-node 인스턴스 타입. 예: t2.micro
ebs_size             = 30                      # EBS 볼륨 크기 (GB). 예: 30GB
key_name             = "your-key-name"         # EC2 인스턴스에 사용할 SSH 키 페어 이름
