# Kubernetes 1.27 Automated Installation Script

[![EN](https://img.shields.io/badge/lang-en-blue.svg)](README-en.md) 
[![KR](https://img.shields.io/badge/lang-kr-red.svg)](README.md)

A script that automatically builds a Kubernetes 1.27 cluster on AWS EC2 instances(UBUNTU 22.04LTS). It automates system configuration, network setup, Docker installation, Kubernetes installation, and initialization.

## Key Features

- Automated installation of Kubernetes 1.27
- Docker and containerd installation and configuration
- Automatic system timezone setting (Asia/Seoul)
- Enhanced SSH security (port modification)
- Calico CNI network plugin installation
- Master/Worker node automatic configuration

## Environment Variables Guide

To customize the script's behavior for your environment, adjust the following environment variables:

### System Settings
```bash
# Log Settings
LOG_FILE="/home/ubuntu/combined_settings.log"  # Log file location
LOG_PREFIX="[K8S-SETUP]"                      # Log prefix

# Basic System Settings
TIMEZONE="Asia/Seoul"                         # System timezone
SSH_PORT="1717"                               # SSH port number
SSH_CONFIG="/etc/ssh/sshd_config"             # SSH config file location
```

### Kubernetes Settings
```bash
# Network Settings
POD_CIDR="10.244.0.0/16"                     # Pod network CIDR
CNI_VERSION="v3.14"                          # Calico CNI version
CNI_MANIFEST="https://docs.projectcalico.org/v3.14/manifests/calico.yaml"

# Kubernetes Version
K8S_VERSION="1.27.16-1.1"                    # Kubernetes version
```

### System Requirements
```bash
MIN_CPU_CORES=2                              # Minimum CPU cores
MIN_MEMORY_GB=2                              # Minimum memory (GB)
REQUIRED_PORTS=(6443 10250 10251 10252)      # Required ports
```

### Retry Settings
```bash
MAX_RETRIES=3                                # Maximum retry attempts
RETRY_INTERVAL=30                            # Retry interval (seconds)
WAIT_INTERVAL=10                             # Wait interval (seconds)
```

## System Requirements

- Ubuntu operating system
- Minimum 2 CPU cores
- Minimum 2GB RAM
- Internet connectivity
- Root or sudo privileges

## Log Monitoring

Installation progress can be monitored at:
```bash
tail -f /home/ubuntu/combined_settings.log
```

## Important Notes

- Script has been tested on Ubuntu operating system
- Verify system requirements before execution
- Ensure required ports are open in firewall settings

## Troubleshooting

If issues occur during installation, check these log files:
- `/home/ubuntu/combined_settings.log`: Complete installation log
- `/var/log/kubeadm_init.log`: kubeadm initialization log
- `journalctl -xeu kubelet`: kubelet service log

## License

This project is licensed under the [MIT License](https://github.com/dongkoony/k8s-aws/blob/master/LICENSE). See the[ LICENSE](https://github.com/dongkoony/k8s-aws/blob/master/LICENSE) file for details.