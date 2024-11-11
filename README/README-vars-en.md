## Terraform Configuration File (terraform.tfvars)

[![EN](https://img.shields.io/badge/lang-en-blue.svg)](README-vars-en.md) 
[![KR](https://img.shields.io/badge/lang-kr-red.svg)](README-vars-kr.md)

This file defines the essential variables needed for AWS infrastructure configuration.

### Important Notice
- Numeric variables should be entered without quotes ("").
  ```bash
  # Correct examples
  worker_instance_count = 2
  volume_size = 30
  
  # Incorrect examples
  worker_instance_count = "2"    # Do not use quotes
  volume_size = "30"             # Do not use quotes
  ```

### Required Configuration Variables
```bash
region               = "YOUR-REGION"          # AWS Region (ex: ap-northeast-2)
availability_zone    = "YOUR-AZ"              # Availability Zone (ex: ap-northeast-2a)
ami_id               = "YOUR-AMI-ID"          # Ubuntu 22.04 LTS AMI ID
```

### Instance Configuration
```bash
master_instance_type = "YOUR-MASTER-TYPE"     # Master node type (recommended: t3.medium)
node_instance_type   = "YOUR-WORKER-TYPE"     # Worker node type (recommended: t3.medium)
worker_instance_count = YOUR-WORKER-COUNT     # Number of worker nodes (ex: 2)
```

### Storage Configuration
```bash
volume_size         = YOUR-VOLUME-SIZE        # Root volume size(GB) (ex: 30)
volume_type         = "YOUR-VOLUME-TYPE"      # Volume type (recommended: gp3)
```

### SSH Access Configuration
```bash
key_name           = "YOUR-KEY-NAME"          # SSH key pair name
private_key_path   = "YOUR-KEY-PATH"          # Private key path
private_key_name   = "YOUR-KEY-FILE-NAME"     # Private key filename
```

### Ubuntu AMI Information
| Ubuntu Version | AMI ID | Architecture |
|---------------|---------|--------------|
| 22.04 LTS | ami-042e76978adeb8c48 | 64-bit(x86) |
| 20.04 LTS | ami-08b2c3a9f2695e351 | 64-bit(x86) |

**Important Notes**: 
- Kubernetes installation scripts are written based on Ubuntu 22.04 LTS.
- AMI IDs may vary by region, please verify before use.
- Private key path must be specified as an absolute path.

### Usage Example
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

This configuration file is used to automatically deploy a Kubernetes cluster on AWS using Terraform.