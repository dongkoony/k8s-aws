# K8s-AWS MCP Server

[![Korean](https://img.shields.io/badge/lang-한국어-blue.svg)](README.md) [![English](https://img.shields.io/badge/lang-English-red.svg)](README-en.md)

A production-ready Kubernetes MCP (Model Context Protocol) server that enables natural language control and monitoring of Kubernetes clusters through AI assistants (Claude, Cursor).

## 🚀 Key Features

### Core Features
| Category | Feature | Description |
|----------|---------|-------------|
| Kubernetes Basic | Pod Management | Create/List/Delete/Check Pod Status |
| | Deployment Management | Create/Update/Delete/Scale Deployments |
| | Advanced Features | HPA/StatefulSet/CronJob/Canary Deployment |
| AWS Integration | EC2 Management | List/Start/Stop Instances |
| Approval Workflow | Slack Integration | Sensitive Operation Approval/Notification/Logging |

### Monitoring Features
```
📊 Cluster Metrics
 ├── CPU Usage/Capacity/Utilization
 ├── Memory Usage/Capacity/Utilization
 └── Overall Cluster Status

🔍 Pod Monitoring
 ├── Container Resource Usage
 ├── Namespace Aggregation
 └── Status and Event Tracking

📝 Log Analysis
 ├── Error/Warning/Exception Detection
 ├── Time-based Analysis
 └── Container-specific Analysis
```

## 🛠 Installation

### Prerequisites
- Python 3.11+
- Kubernetes Cluster Access
- AWS Credentials (for EC2 Management)
- Slack Workspace (for Approval Workflow)

### Installation
```bash
# Clone the project
git clone https://github.com/dongkoony/k8s-aws.git
cd k8s-aws/mcp

# Install dependencies
poetry install
```

## ⚙️ Configuration

### 1. Kubernetes Configuration
```bash
# Check kubeconfig settings
kubectl config view

# Set context
kubectl config use-context your-context
```

### 2. Slack Configuration
```python
# Edit workflows/slack_approval.py
SLACK_BOT_TOKEN = "your-bot-token"
SLACK_CHANNEL_ID = "your-channel-id"
```

### 3. AWS Configuration
```bash
# Configure AWS credentials
aws configure
```

## 🚀 Running the Server

### Start Server
```bash
poetry run python main.py
```

### AI Assistant Integration
```json
// ~/.config/claude/mcp.json or ~/.cursor/mcp.json
{
  "mcpServers": {
    "kubernetes": {
      "command": "python",
      "args": ["-m", "k8s_aws_copilot.minimal_wrapper"],
      "env": {
        "KUBECONFIG": "/path/to/your/.kube/config"
      }
    }
  }
}
```

## 📚 Usage Examples

### 1. Pod Management
```python
# List pods
response = await mcp.tools.list_pods(namespace="default")

# Create pod
response = await mcp.tools.create_pod(
    name="nginx",
    image="nginx:latest",
    namespace="default"
)
```

### 2. Monitoring
```python
# Get cluster metrics
metrics = await mcp.tools.get_cluster_metrics()

# Analyze pod logs
logs = await mcp.tools.get_pod_logs_analysis(
    namespace="default",
    pod_name="nginx",
    hours=1
)
```

### 3. Approval Workflow
```python
# Stop EC2 instance (requires approval)
response = await mcp.tools.stop_ec2_instance(
    instance_id="i-1234567890abcdef0",
    user="admin"
)
```

## 🔒 Security Features

- Slack-based Approval Workflow
- Sensitive Operation Logging
- Operation Result Notifications
- AWS Credentials Management

## 📊 Monitoring Dashboard

| Metric | Description | Refresh Rate |
|--------|-------------|--------------|
| Cluster Status | CPU/Memory Usage | Real-time |
| Node Status | Readiness/Pressure States | 1 minute |
| Pod Status | Running/Error/Restart | 30 seconds |
| Events | Warning/Error/Info | Real-time |

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Credits

This project is inspired by [kubectl-mcp-server](https://github.com/rohitg00/kubectl-mcp-server). 