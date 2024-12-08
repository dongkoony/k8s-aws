# Kubernetes on AWS with Terraform

[![EN](https://img.shields.io/badge/lang-en-blue.svg)](README-en.md) 
[![KR](https://img.shields.io/badge/lang-kr-red.svg)](README.md)

[![IaC](https://img.shields.io/badge/IaC-Terraform_1.8+-623ce4?logo=terraform&logoColor=white)](#)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-326ce5?logo=kubernetes&logoColor=white)](#)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](#)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Installer-326ce5?logo=kubernetes&logoColor=white)](#)
[![CNI](https://img.shields.io/badge/CNI-Calico_v3.28.0-fb8c00?logo=linux&logoColor=white)](#)
[![OS](https://img.shields.io/badge/OS-Ubuntu_22.04_LTS-e95420?logo=ubuntu&logoColor=white)](#)
[![Cloud](https://img.shields.io/badge/Cloud-AWS-232f3e?logo=amazonaws&logoColor=white)](#)

## Overview
This repository contains infrastructure code designed to easily deploy **Kubernetes v1.31 cluster with Calico CNI v3.28.0** on **AWS EC2 instances (Ubuntu 22.04 LTS)** using **Terraform**. The infrastructure is automatically configured through Terraform's **apply** command, installing Kubernetes on EC2 instances.

## Tech Stack
- **Kubernetes**: v1.31
- **CNI**: Calico v3.28.0
- **OS**: Ubuntu 22.04 LTS
- **Cloud**: AWS
- **IaC**: Terraform 1.8+

## System Requirements
- **Master Node**: Minimum t3.medium (2 vCPU, 4GB RAM)
- **Worker Node**: Minimum t3.medium (2 vCPU, 4GB RAM)
- **Storage**: Minimum 30GB gp3 EBS volume
- **Network**: Private subnet within VPC

## Key Features
- Automatic Kubernetes v1.31 cluster configuration
- Automatic Calico CNI v3.28.0 installation and configuration
- Enhanced SSH security (port modification)
- Automatic Seoul timezone setting
- Automatic worker node joining

## Architecture
- **Master Node**: Runs control plane components
- **Worker Nodes**: Runs application workloads
- **Networking**: Pod network configuration via Calico CNI
- **Storage**: Persistent storage through gp3 EBS volumes

## Purpose
The purpose of this project is to build an environment that easily deploys and manages **Kubernetes clusters** within AWS infrastructure using **Terraform**. Users can automatically create and manage Kubernetes clusters through Terraform's **apply** command.

## Goals
- Automate **Kubernetes v1.31** cluster deployment on AWS infrastructure using **Terraform**
- Configure **SSH port** changes and **Seoul timezone (Asia/Seoul)** during EC2 instance creation
- Automate infrastructure deployment and management for **Master node** and **Worker nodes**
- Simplify infrastructure maintenance through **Terraform variable files**

## How to Use

### 1. Environment Setup
First, you need [**Terraform**](https://developer.hashicorp.com/terraform/install#darwin) installed. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) is also required, along with properly configured **AWS credentials**.
```bash
aws configure    # Register AWS credentials
aws configure list    # List AWS credentials
```

### 2. Clone the Repository
```bash
git clone https://github.com/dongkoony/k8s-aws
cd k8s-aws
```

### 3. Modify Variable Configuration File
Modify the [`terraform.tfvars`](terraform.tfvars) file according to your environment. Refer to the [variable configuration guide](https://github.com/dongkoony/k8s-aws/blob/master/README/README-vars-en.md) for detailed settings.

```bash
region               = "YOUR-REGION"                # AAWS Region. ex: ap-northeast-2 (Seoul)
availability_zone    = "YOUR-AZ"                    # Availability Zone. ex: ap-northeast-2a
ami_id               = "YOUR-AMI-ID"                # AMI ID (k8s installation script based on Ubuntu 22.04 LTS)
master_instance_type = "YOUR-MASTER-TYPE"           # Master node instance type. ex: t3.medium
node_instance_type   = "YOUR-WORKER-TYPE"           # Worker node instance type. ex: t3.medium
worker_instance_count= "YOUR-WORKER-COUNT"          # Number of worker nodes. ex: 2
volume_size          = "YOUR-VOLUME-SIZE"           # Root volume size(GB). ex: 30
volume_type          = "YOUR-VOLUME-TYPE"           # Volume type. ex: gp3
key_name             = "YOUR-KEY-NAME"              # SSH key pair name
private_key_path     = "YOUR-KEY-PATH"              # Private key path. ex: /home/ubuntu/your-key.pem
private_key_name     = "YOUR-KEY-FILE-NAME"         # Private key filename. ex: your-key.pem
```

### 4. Execute Terraform Commands
```bash
terraform init    # Initialize
terraform plan    # Check execution plan
terraform apply --auto-approve    # Deploy infrastructure
terraform destroy --auto-approve    # Remove infrastructure
```

## Precautions
- Optimized for Kubernetes v1.31 and Calico v3.28.0
- Tested only on Ubuntu 22.04 LTS
- Recommended instance type: t3.medium or higher
- Recommended volume type: gp3

## Troubleshooting
Check the following when issues occur:
- Verify AWS credentials are properly configured
- Confirm required AWS permissions are in place
- Ensure instance type and volume size meet requirements
- Verify network settings are correct

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

For additional inquiries or contributions, please create an issue or submit a pull request.