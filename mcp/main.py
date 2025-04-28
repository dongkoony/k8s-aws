# main.py
from fastmcp import FastMCP

# FastMCP 인스턴스 생성
mcp = FastMCP("k8s-aws-copilot")

# Kubernetes 관련 툴 등록
from tools.kubernetes.pods import (
  list_pods,
  describe_pod,
  create_pod,
  apply_yaml,
  delete_pod,
)
for fn in [
  list_pods, 
  describe_pod, 
  create_pod, 
  apply_yaml, 
  delete_pod
]:
    mcp.tool()(fn)

# Deployment 관련 툴 등록
from tools.kubernetes.deployments import (
  list_deployments,
  describe_deployment,
  create_deployment,
  update_deployment,
  delete_deployment,
)
for fn in [
  list_deployments,
  describe_deployment,
  create_deployment,
  update_deployment,
  delete_deployment,
]:
    mcp.tool()(fn)

# Advanced Kubernetes 기능 등록
from tools.kubernetes.advanced import (
    list_hpa,
    create_hpa,
    list_statefulsets,
    create_statefulset,
    create_cronjob,
    create_canary_deployment,
    create_pod_disruption_budget,
)

for fn in [
    list_hpa,
    create_hpa,
    list_statefulsets,
    create_statefulset,
    create_cronjob, 
    create_canary_deployment,
    create_pod_disruption_budget,
]:
    mcp.tool()(fn)

# AWS EC2 관련 툴 등록
from tools.aws.ec2 import (
  list_ec2_instances,
  describe_ec2_instance,
  start_ec2_instance,
  stop_ec2_instance,
)
for fn in [
  list_ec2_instances, 
  describe_ec2_instance, 
  start_ec2_instance, 
  stop_ec2_instance
]:
  mcp.tool()(fn)

# FastMCP SSE 앱 생성
app = mcp.sse_app()

# uvicorn으로 실행
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",  # '파일명:app객체'
        host="0.0.0.0",
        port=8080,
        log_level="info",
    )
