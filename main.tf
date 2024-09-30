provider "aws" {
  region = var.region
}

# Security Group 설정
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes master and nodes"

  # # SSH 22 포트 열기
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # SSH 1717 포트 열기
  ingress {
    from_port   = 1717
    to_port     = 1717
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API 포트 (6443)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Docker 포트 (2376 for secure Docker daemon)
  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 기본 아웃바운드 규칙 (모든 트래픽 허용)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 스냅샷 생성 리소스 (백업 로직)
resource "aws_ebs_snapshot" "master_snapshot" {
  volume_id = aws_ebs_volume.master_volume.id
  tags = {
    Name = "k8s-master-snapshot"
  }
}

resource "aws_ebs_snapshot" "node1_snapshot" {
  volume_id = aws_ebs_volume.node1_volume.id
  tags = {
    Name = "k8s-node1-snapshot"
  }
}

resource "aws_ebs_snapshot" "node2_snapshot" {
  volume_id = aws_ebs_volume.node2_volume.id
  tags = {
    Name = "k8s-node2-snapshot"
  }
}

# EBS 볼륨 생성 (복구 시 스냅샷에서 복원)
resource "aws_ebs_volume" "master_volume" {
  availability_zone = var.availability_zone
  size              = var.ebs_size
  snapshot_id       = aws_ebs_snapshot.master_snapshot.id
  tags = {
    Name = "k8s-master-volume"
  }
}

resource "aws_ebs_volume" "node1_volume" {
  availability_zone = var.availability_zone
  size              = var.ebs_size
  snapshot_id       = aws_ebs_snapshot.node1_snapshot.id
  tags = {
    Name = "k8s-node1-volume"
  }
}

resource "aws_ebs_volume" "node2_volume" {
  availability_zone = var.availability_zone
  size              = var.ebs_size
  snapshot_id       = aws_ebs_snapshot.node2_snapshot.id
  tags = {
    Name = "k8s-node2-volume"
  }
}

# k8s-master 인스턴스
resource "aws_instance" "k8s_master" {
  ami           = var.ami_id
  instance_type = var.master_instance_type
  key_name      = var.key_name

  tags = {
    Name = "k8s-master"
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_id   = aws_ebs_volume.master_volume.id
  }

  security_groups = [aws_security_group.k8s_sg.name]

  # user_data를 외부 파일로 관리
  user_data = file("./script/ssh_time.sh")
}

# k8s-node1 인스턴스
resource "aws_instance" "k8s_node1" {
  ami           = var.ami_id
  instance_type = var.node_instance_type
  key_name      = var.key_name

  tags = {
    Name = "k8s-node1"
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_id   = aws_ebs_volume.node1_volume.id
  }

  security_groups = [aws_security_group.k8s_sg.name]

  user_data = file("./script/ssh_time.sh")
}

# k8s-node2 인스턴스
resource "aws_instance" "k8s_node2" {
  ami           = var.ami_id
  instance_type = var.node_instance_type
  key_name      = var.key_name

  tags = {
    Name = "k8s-node2"
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_id   = aws_ebs_volume.node2_volume.id
  }

  security_groups = [aws_security_group.k8s_sg.name]

  user_data = file("./script/ssh_time.sh")
}
