## Worker Node Setup Script (worker_setup.sh)
[![EN](https://img.shields.io/badge/lang-en-blue.svg)](README-worker-en.md) 
[![KR](https://img.shields.io/badge/lang-kr-red.svg)](README-worker-kr.md)

This script (worker_setup.sh) manages the process of automatically configuring Kubernetes worker nodes and connecting them to the cluster.

## Script Structure

### 1. Basic Variable Configuration
```bash
MASTER_IP="$1"                                # Master node IP address
NODE_INDEX="$2"                               # Worker node number
SSH_KEY_PATH="/home/ubuntu/.ssh/example.pem"  # SSH key path
```
- Example of variable modification:
  ```bash
  SSH_KEY_PATH="/your/key/path/your-key.pem"
  ```

### 2. SSH and Security Settings
```bash
sudo chmod 400 ${SSH_KEY_PATH}
chmod +x /home/ubuntu/combined_settings.sh
touch /home/ubuntu/.ssh/known_hosts
echo 'StrictHostKeyChecking no' > /home/ubuntu/.ssh/config
chmod 600 /home/ubuntu/.ssh/config
```
- Automatically configures SSH key permissions and security settings
- Permissions can be manually modified if needed:
  ```bash
  chmod 600 /home/ubuntu/.ssh/config  # Security settings
  ```

### 3. Cluster Join Process
```bash
until ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${MASTER_IP} 'test -f /home/ubuntu/join_command'; do 
    sleep 10
done

JOIN_CMD=$(ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${MASTER_IP} 'cat /home/ubuntu/join_command')
sudo $JOIN_CMD
```
- Automatically fetches and executes the join command from the master node
- For manual joining if needed:
  ```bash
  # On master node
  kubeadm token create --print-join-command > join_command
  # On worker node
  sudo $(cat join_command)
  ```

### 4. Node Label Configuration
```bash
NODE_IP=$(hostname -I | awk '{print $1}')
FORMATTED_IP=$(echo $NODE_IP | tr '.' '-')
ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${MASTER_IP} "kubectl label node ip-${FORMATTED_IP} node-role.kubernetes.io/worker-node${NODE_INDEX}=''"
```
- Example of manual node labeling:
  ```bash
  kubectl label node ip-10-0-2-15 node-role.kubernetes.io/worker-node1=''
  ```

## Usage (For Manual Execution)

1. **Script Preparation**
   ```bash
   # Grant execution permissions to the script
   chmod +x worker_setup.sh
   ```

2. **Script Execution**
   ```bash
   ./worker_setup.sh <master_IP> <node_number>
   # Example
   ./worker_setup.sh 10.0.x.xxx 1
   ```

3. **Verification**
   ```bash
   # Check node status on master node
   kubectl get nodes
   
   # Expected output
   NAME           STATUS   ROLES          AGE   VERSION
   ip-10-0-x-xxx Ready    control-plane  10m   v1.31.0
   ip-10-0-x-xx  Ready    worker-node1   5m    v1.31.0
   ```

## Precautions
- SSH key path must be correctly configured
- Master node must be running
- Proper network connectivity is required
- Sufficient system resources must be available

## Troubleshooting
- SSH connection error: Check SSH key permissions
- Join failure: Verify master node status
- Label setting failure: Check kubeconfig settings

This script is automatically executed through Terraform, so manual intervention is generally not required. However, refer to this guide for troubleshooting or customization needs.