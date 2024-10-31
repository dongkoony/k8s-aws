provider "aws" {
  region = var.region
}

# Security Group 설정
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes master and nodes"

  # 초기 SSH 연결용 22번 포트
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 변경된 SSH 포트 1717
  ingress {
    from_port   = 1717
    to_port     = 1717
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API 서버
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Docker 데몬
  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Calico CNI
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    self        = true
    description = "Calico BGP"
  }

  # 내부 통신
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 스냅샷 데이터 조회
data "aws_ebs_snapshot" "master_snapshot" {
  count       = length(try([for snapshot in data.aws_ebs_snapshot.master_snapshot : snapshot.id], [])) > 0 ? 1 : 0
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Name"
    values = ["k8s-master-snapshot"]
  }
}

data "aws_ebs_snapshot" "node1_snapshot" {
  count       = length(try([for snapshot in data.aws_ebs_snapshot.node1_snapshot : snapshot.id], [])) > 0 ? 1 : 0
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Name"
    values = ["k8s-node1-snapshot"]
  }
}

data "aws_ebs_snapshot" "node2_snapshot" {
  count       = length(try([for snapshot in data.aws_ebs_snapshot.node2_snapshot : snapshot.id], [])) > 0 ? 1 : 0
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Name"
    values = ["k8s-node2-snapshot"]
  }
}

locals {
  snapshot_ids = {
    master = length(data.aws_ebs_snapshot.master_snapshot) > 0 ? data.aws_ebs_snapshot.master_snapshot[0].id : null,
    node1  = length(data.aws_ebs_snapshot.node1_snapshot) > 0 ? data.aws_ebs_snapshot.node1_snapshot[0].id : null,
    node2  = length(data.aws_ebs_snapshot.node2_snapshot) > 0 ? data.aws_ebs_snapshot.node2_snapshot[0].id : null
  }
}

# 마스터 노드 생성
resource "aws_instance" "k8s_master" {
  ami               = var.ami_id
  instance_type     = var.master_instance_type
  availability_zone = var.availability_zone
  key_name          = var.key_name

  tags = {
    Name = "k8s-master"
    Role = "master"
  }

  security_groups = [aws_security_group.k8s_sg.name]
  user_data      = file("./script/system_settings.sh")

  # 시스템 설정 완료 대기
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      port        = 22
      timeout     = "10m"
    }

    inline = [
      "while [ ! -f /home/ubuntu/.system_settings_complete ]; do sleep 10; done",
      "echo '시스템 설정 완료'"
    ]
  }

  # 쿠버네티스 설치
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      port        = 1717
    }

    source      = "./script/combined_settings.sh"
    destination = "/home/ubuntu/combined_settings.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      port        = 1717
    }

    inline = [
      "chmod +x /home/ubuntu/combined_settings.sh",
      "export NODE_ROLE=master",
      "sudo -E /home/ubuntu/combined_settings.sh",
      "while [ ! -f /etc/kubernetes/admin.conf ]; do sleep 10; done",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      # Calico CNI 설치 명령
      "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml",
      "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml",
      # Join 토큰 생성
      "sudo kubeadm token create --print-join-command > /home/ubuntu/join_command"
    ]
  }
}

# 워커 노드 생성
resource "aws_instance" "k8s_workers" {
  count             = 2
  ami               = var.ami_id
  instance_type     = var.node_instance_type
  availability_zone = var.availability_zone
  key_name          = var.key_name

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }

  security_groups = [aws_security_group.k8s_sg.name]
  user_data      = file("./script/system_settings.sh")

  # 시스템 설정 완료 대기
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      port        = 22
      timeout     = "10m"
    }

    inline = [
      "while [ ! -f /home/ubuntu/.system_settings_complete ]; do sleep 10; done",
      "echo '시스템 설정 완료'"
    ]
  }

  # 쿠버네티스 설치 및 조인
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      port        = 1717
    }

    source      = "./script/combined_settings.sh"
    destination = "/home/ubuntu/combined_settings.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      port        = 1717
    }

    inline = [
      "chmod +x /home/ubuntu/combined_settings.sh",
      "export NODE_ROLE=worker",
      "sudo -E /home/ubuntu/combined_settings.sh",
      "until ssh -p 1717 -o StrictHostKeyChecking=no -i ${var.private_key_path} ubuntu@${aws_instance.k8s_master.private_ip} 'test -f /home/ubuntu/join_command'; do sleep 10; done",
      "JOIN_CMD=$(ssh -p 1717 -o StrictHostKeyChecking=no -i ${var.private_key_path} ubuntu@${aws_instance.k8s_master.private_ip} 'cat /home/ubuntu/join_command')",
      "sudo $JOIN_CMD"
    ]
  }

  depends_on = [aws_instance.k8s_master]
}

# EBS 볼륨 생성
resource "aws_ebs_volume" "k8s_volumes" {
  for_each = toset(["master", "node1", "node2"])

  availability_zone = var.availability_zone
  size             = var.ebs_size
  snapshot_id      = lookup(local.snapshot_ids, each.key, null)

  tags = {
    Name = "k8s-${each.key}-volume"
  }
}

# 마스터 노드 EBS 볼륨 연결
resource "aws_volume_attachment" "master_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.k8s_volumes["master"].id
  instance_id = aws_instance.k8s_master.id

  depends_on = [aws_instance.k8s_master]
}

# 워커 노드 EBS 볼륨 연결
resource "aws_volume_attachment" "worker_attachments" {
  count       = 2
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.k8s_volumes["node${count.index + 1}"].id
  instance_id = aws_instance.k8s_workers[count.index].id

  depends_on = [aws_instance.k8s_workers]
}

# 마스터 노드 스냅샷
resource "aws_ebs_snapshot" "master_snapshot" {
  volume_id = aws_ebs_volume.k8s_volumes["master"].id
  
  tags = {
    Name = "k8s-master-snapshot"
  }

  depends_on = [aws_volume_attachment.master_attachment]

  lifecycle {
    create_before_destroy = true
  }
}

# 워커 노드 스냅샷
resource "aws_ebs_snapshot" "worker_snapshots" {
  count     = 2
  volume_id = aws_ebs_volume.k8s_volumes["node${count.index + 1}"].id
  
  tags = {
    Name = "k8s-node${count.index + 1}-snapshot"
  }

  depends_on = [aws_volume_attachment.worker_attachments]

  lifecycle {
    create_before_destroy = true
  }
}