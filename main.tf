provider "aws" {
  region = var.region
}

# Security Group 설정
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes master and nodes"

  # 포트 1717: SSH 포트 (기본 22에서 1717로 변경된 SSH 접근을 위한 포트)
  ingress {
    from_port   = 1717
    to_port     = 1717
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 포트 6443: Kubernetes API 서버 포트 (Kubernetes 클러스터 관리를 위한 포트)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 포트 2376: Docker 데몬이 외부에서 안전하게 접근할 수 있도록 하는 포트 (Docker TLS 포트)
  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 아웃바운드 트래픽을 허용하는 egress 규칙 (모든 외부 통신 허용)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# master 스냅샷이 존재하는 경우만 데이터 조회
data "aws_ebs_snapshot" "master_snapshot" {
  count       = length(try([for snapshot in data.aws_ebs_snapshot.master_snapshot: snapshot.id], [])) > 0 ? 1 : 0
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Name"
    values = ["k8s-master-snapshot"]
  }
}

data "aws_ebs_snapshot" "node1_snapshot" {
  count       = length(try([for snapshot in data.aws_ebs_snapshot.node1_snapshot: snapshot.id], [])) > 0 ? 1 : 0
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Name"
    values = ["k8s-node1-snapshot"]
  }
}

data "aws_ebs_snapshot" "node2_snapshot" {
  count       = length(try([for snapshot in data.aws_ebs_snapshot.node2_snapshot: snapshot.id], [])) > 0 ? 1 : 0
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Name"
    values = ["k8s-node2-snapshot"]
  }
}

locals {
  # 각 스냅샷의 ID를 참조할 수 있는지 확인하고, 없으면 null로 설정
  snapshot_ids = {
    master = length(data.aws_ebs_snapshot.master_snapshot) > 0 ? data.aws_ebs_snapshot.master_snapshot[0].id : null,
    node1  = length(data.aws_ebs_snapshot.node1_snapshot) > 0 ? data.aws_ebs_snapshot.node1_snapshot[0].id : null,
    node2  = length(data.aws_ebs_snapshot.node2_snapshot) > 0 ? data.aws_ebs_snapshot.node2_snapshot[0].id : null
  }
}

# k8s-master, node1, node2 인스턴스 생성
resource "aws_instance" "k8s_instances" {
  for_each = toset(["master", "node1", "node2"])

  ami           = var.ami_id
  instance_type = each.key == "master" ? var.master_instance_type : var.node_instance_type
  key_name      = var.key_name

  tags = {
    Name = "k8s-${each.key}"
  }

  security_groups = [aws_security_group.k8s_sg.name]

  # user_data를 외부 파일로 관리
  user_data = file("./script/combined_settings.sh")
}

# EBS 볼륨 생성 (스냅샷이 있으면 복원, 없으면 새로 생성)
resource "aws_ebs_volume" "k8s_volumes" {
  for_each = toset(["master", "node1", "node2"])

  availability_zone = var.availability_zone
  size              = var.ebs_size

  # 스냅샷이 있는 경우에만 복원, 없으면 null로 설정하여 새로 생성
  snapshot_id = lookup(local.snapshot_ids, each.key, null)

  tags = {
    Name = "k8s-${each.key}-volume"
  }
}

# EBS 볼륨을 인스턴스에 연결
resource "aws_volume_attachment" "k8s_attachments" {
  for_each = toset(["master", "node1", "node2"])

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.k8s_volumes[each.key].id
  instance_id = aws_instance.k8s_instances[each.key].id

  # aws_instance.k8s_instances가 모두 생성된 후에만 EBS 볼륨을 연결하도록 의존성 추가
  depends_on  = [aws_instance.k8s_instances]
}

# 스냅샷 생성 (자동 백업) - 인스턴스와 볼륨이 연결된 후에만 생성
resource "aws_ebs_snapshot" "k8s_snapshots" {
  for_each = toset(["master", "node1", "node2"])

  volume_id = aws_ebs_volume.k8s_volumes[each.key].id
  tags = {
    Name = "k8s-${each.key}-snapshot"
  }

  # 볼륨이 인스턴스에 연결된 후에만 스냅샷을 생성하도록 의존성 설정
  depends_on = [aws_volume_attachment.k8s_attachments]

  # 인프라를 제거하기 전에 스냅샷을 생성
  lifecycle {
    create_before_destroy = true
  }
}
