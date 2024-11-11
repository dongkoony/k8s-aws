# ./main.tf

provider "aws" {
  region = var.region
}

# Security Group 설정
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  vpc_id      = aws_vpc.k8s_vpc.id
  description = "Security group for Kubernetes master and nodes"

  # 초기 SSH 연결용 22번 포트
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # 변경된 SSH 포트 22
  ingress {
    from_port   = 22
    to_port     = 22
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

  # 쿠버네티스 내부 통신을 위한 규칙
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
    description = "Allow internal kubernetes traffic"
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    self      = true
    description = "Allow internal kubernetes traffic"
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

# # 마스터 노드 스냅샷
# data "aws_ebs_snapshot" "master_snapshot" {
#   most_recent = true
#   owners      = ["self"]

#   dynamic "filter" {
#     for_each = [local.master_snapshot_filter]
#     content {
#       name   = filter.value.name
#       values = filter.value.values
#     }
#   }
# }

# # 워커 노드1 스냅샷
# data "aws_ebs_snapshot" "node1_snapshot" {
#   most_recent = true
#   owners      = ["self"]

#   dynamic "filter" {
#     for_each = [local.node1_snapshot_filter]
#     content {
#       name   = filter.value.name
#       values = filter.value.values
#     }
#   }
# }

# # 워커 노드2 스냅샷
# data "aws_ebs_snapshot" "node2_snapshot" {
#   most_recent = true
#   owners      = ["self"]

#   dynamic "filter" {
#     for_each = [local.node2_snapshot_filter]
#     content {
#       name   = filter.value.name
#       values = filter.value.values
#     }
#   }
# }

# 마스터 노드 생성
resource "aws_instance" "k8s_master" {
  ami                      = var.ami_id
  instance_type           = var.master_instance_type
  availability_zone       = var.availability_zone
  subnet_id               = aws_subnet.public_subnet.id
  vpc_security_group_ids  = [aws_security_group.k8s_sg.id]
  key_name               = var.key_name
  disable_api_termination = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    tags = {
      Name = "k8s-master-root"
    }
  }

  tags = {
    Name = "k8s-master"
    Role = "master"
  }

  user_data = file("./script/system_settings.sh")

  # SSH 설정을 위한 초기 provisioner
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/ubuntu/Project/k8s-aws.pem")
      host        = self.public_ip
      port        = 22
      timeout     = "5m"
    }

    inline = [
      # SSH 디렉토리 설정
      "mkdir -p ~/.ssh",
      "chmod 700 ~/.ssh",
      "touch ~/.ssh/known_hosts",
      "chmod 600 ~/.ssh/known_hosts",
      
      # 키 파일 복사 및 권한 설정
      "cp /home/ubuntu/k8s-aws.pem ~/.ssh/",
      "chmod 400 ~/.ssh/k8s-aws.pem",
      
      # SSH 설정
      "echo 'StrictHostKeyChecking no' > ~/.ssh/config",
      "chmod 600 ~/.ssh/config",
      
      "echo '시스템 설정 완료'"
    ]
  }

  # 시스템 설정 완료 대기
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/ubuntu/Project/k8s-aws.pem")
      host        = self.public_ip
      port        = 22
      timeout     = "5m"
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
      private_key = file("/home/ubuntu/Project/k8s-aws.pem")
      host        = self.public_ip
      port        = 22
    }

    source      = "./script/combined_settings.sh"
    destination = "/home/ubuntu/combined_settings.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/ubuntu/Project/k8s-aws.pem")
      host        = self.public_ip
      port        = 22
    }

    inline = [
      "chmod +x /home/ubuntu/combined_settings.sh",
      "export NODE_ROLE=master",
      "sudo -E /home/ubuntu/combined_settings.sh",
      "echo 'Kubernetes setup completed'"
    ]
  }
}

# 워커 노드 생성
resource "aws_instance" "k8s_workers" {
  count                  = var.worker_instance_count
  ami                    = var.ami_id
  instance_type          = var.node_instance_type
  availability_zone      = var.availability_zone
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = var.key_name
  disable_api_termination = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    tags = {
      Name = "k8s-worker-${count.index + 1}-root"
    }
  }

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }

  user_data = file("./script/system_settings.sh")

  # 시스템 설정 완료 대기 및 SSH 디렉토리 설정
  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file("/home/ubuntu/Project/k8s-aws.pem")  # 절대 경로 사용
      host                = self.private_ip
      port                = 22
      bastion_host        = aws_instance.k8s_master.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("/home/ubuntu/Project/k8s-aws.pem")  # 절대 경로 사용
      bastion_port        = 22
      timeout             = "5m"
    }

    inline = [
      "sudo mkdir -p /home/ubuntu/.ssh",
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh",
      "sudo chmod 700 /home/ubuntu/.ssh",
      "while [ ! -f /home/ubuntu/.system_settings_complete ]; do sleep 10; done",
      "echo '시스템 설정 완료'"
    ]
  }

  # SSH 키 파일 복사
  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file("/home/ubuntu/Project/k8s-aws.pem")
      host                = self.private_ip
      port                = 22
      bastion_host        = aws_instance.k8s_master.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("/home/ubuntu/Project/k8s-aws.pem")
      bastion_port        = 22
    }

    source      = "/home/ubuntu/Project/k8s-aws.pem"
    destination = "/home/ubuntu/.ssh/k8s-aws.pem"
  }

  # 3. 쿠버네티스 설치 스크립트 전송
  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file("/home/ubuntu/Project/k8s-aws.pem")
      host                = self.private_ip
      port                = 22
      bastion_host        = aws_instance.k8s_master.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("/home/ubuntu/Project/k8s-aws.pem")
      bastion_port        = 22
    }

    source      = "./script/combined_settings.sh"
    destination = "/home/ubuntu/combined_settings.sh"
  }

  # 4. 쿠버네티스 설치 및 클러스터 조인
  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file("/home/ubuntu/Project/k8s-aws.pem")
      host                = self.private_ip
      port                = 22
      bastion_host        = aws_instance.k8s_master.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("/home/ubuntu/Project/k8s-aws.pem")
      bastion_port        = 22
    }

    inline = [
      "sudo chmod 400 /home/ubuntu/.ssh/k8s-aws.pem",
      "chmod +x /home/ubuntu/combined_settings.sh",
      "export NODE_ROLE=worker",
      "export MASTER_PRIVATE_IP=${aws_instance.k8s_master.private_ip}",
      "sudo -E /home/ubuntu/combined_settings.sh",
      "touch /home/ubuntu/.ssh/known_hosts",
      "echo 'StrictHostKeyChecking no' > /home/ubuntu/.ssh/config",
      "chmod 600 /home/ubuntu/.ssh/config",
      "ssh-keyscan -p 22 ${aws_instance.k8s_master.public_ip} 2>/dev/null >> /home/ubuntu/.ssh/known_hosts",
      "ssh-keyscan -p 22 ${aws_instance.k8s_master.private_ip} 2>/dev/null >> /home/ubuntu/.ssh/known_hosts",
      "until ssh -i /home/ubuntu/.ssh/k8s-aws.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.k8s_master.private_ip} 'test -f /home/ubuntu/join_command'; do sleep 10; done",
      "JOIN_CMD=$(ssh -i /home/ubuntu/.ssh/k8s-aws.pem -o StrictHostKeyChecking=no ubuntu@${aws_instance.k8s_master.private_ip} 'cat /home/ubuntu/join_command')",
      "sudo $JOIN_CMD"
    ]
  }

  depends_on = [aws_instance.k8s_master]
}

# # EBS 볼륨 생성
# resource "aws_ebs_volume" "k8s_volumes" {
#   for_each = toset(["master", "node1", "node2"])

#   availability_zone = var.availability_zone
#   size             = var.ebs_size
#   snapshot_id      = lookup(local.snapshot_ids, each.key, null)

#   tags = {
#     Name = "k8s-${each.key}-volume"
#   }
# }

# # 마스터 노드 EBS 볼륨 연결
# resource "aws_volume_attachment" "master_attachment" {
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.k8s_volumes["master"].id
#   instance_id = aws_instance.k8s_master.id

#   depends_on = [aws_instance.k8s_master]
# }

# # 워커 노드 EBS 볼륨 연결
# resource "aws_volume_attachment" "worker_attachments" {
#   count       = 2
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.k8s_volumes["node${count.index + 1}"].id
#   instance_id = aws_instance.k8s_workers[count.index].id

#   depends_on = [aws_instance.k8s_workers]
# }

# # 마스터 노드 스냅샷
# resource "aws_ebs_snapshot" "master_snapshot" {
#   volume_id = aws_ebs_volume.k8s_volumes["master"].id
  
#   tags = {
#     Name = "k8s-master-snapshot"
#   }

#   depends_on = [aws_volume_attachment.master_attachment]

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # 워커 노드 스냅샷
# resource "aws_ebs_snapshot" "worker_snapshots" {
#   count     = 2
#   volume_id = aws_ebs_volume.k8s_volumes["node${count.index + 1}"].id
  
#   tags = {
#     Name = "k8s-node${count.index + 1}-snapshot"
#   }

#   depends_on = [aws_volume_attachment.worker_attachments]

#   lifecycle {
#     create_before_destroy = true
#   }
# }