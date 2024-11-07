# ./variables.tf

variable "region" {
  description = "AWS 리전"
}

variable "availability_zone" {
  description = "EC2 인스턴스가 생성될 가용 영역"
}

variable "master_instance_type" {
  description = "k8s-master 인스턴스 타입"
}

variable "node_instance_type" {
  description = "k8s-node 인스턴스 타입"
}

variable "worker_instance_count" {
  description = "Worker_Instance_갯수"
}

variable "ami_id" {
  description = "사용할 AMI ID (Ubuntu 22.04 LTS)"
}

variable "ebs_size" {
  description = "EBS 볼륨 크기 (GB)"
}

variable "key_name" {
  description = "EC2 인스턴스에 사용할 SSH 키 페어 이름"
}

variable "private_key_path" {
  description = "EC2 인스턴스에 사용할 SSH 키 경로"
}