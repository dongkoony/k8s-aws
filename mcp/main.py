from fastmcp import FastMCP

# FastMCP 인스턴스 생성
mcp = FastMCP("k8s-aws-copilot")

# 승인/알림 워크플로우 import
from workflows.slack_approval import (
  send_approval_request_with_button,
  send_action_log,
  send_result_notification
)
import functools

# 승인 워크플로우 데코레이터 (버튼 메시지용)
def approval_required(action_name, impact_message, resource_type_getter, resource_name_getter, namespace_getter=lambda *a, **k: "default"):
  def decorator(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
      user = kwargs.get("user", "unknown")
      resource_type = resource_type_getter(*args, **kwargs)
      resource_name = resource_name_getter(*args, **kwargs)
      namespace = namespace_getter(*args, **kwargs)
      send_approval_request_with_button(
        user=user,
        action=action_name,
        impact=impact_message,
        resource_type=resource_type,
        resource_name=resource_name,
        namespace=namespace
      )
      send_action_log(user, f"{action_name}({resource_name})", "대기(관리자 승인)")
      return {"status": "waiting_for_approval", "message": "관리자 승인 대기 중"}
    return wrapper
  return decorator

# Kubernetes Pods
from tools.kubernetes.pods import (
  list_pods,
  describe_pod,
  create_pod,
  apply_yaml,
  delete_pod as real_delete_pod,
)
for fn in [
  list_pods, 
  describe_pod, 
  create_pod, 
  apply_yaml
]:
  mcp.tool()(fn)

# Kubernetes Deployments
from tools.kubernetes.deployments import (
  list_deployments,
  describe_deployment,
  create_deployment,
  update_deployment,
  delete_deployment as real_delete_deployment,
)
for fn in [
  list_deployments,
  describe_deployment,
  create_deployment,
  update_deployment,
]:
  mcp.tool()(fn)

# Kubernetes Advanced
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

from tools.aws.ec2 import (
  list_ec2_instances,
  describe_ec2_instance,
  start_ec2_instance,
  stop_ec2_instance as real_stop_ec2_instance,
)

# 민감 작업 래핑 (승인 워크플로우 적용, 버튼 메시지)
@approval_required(
  "EC2 인스턴스 중지",
  "이 작업은 모든 EC2 인스턴스가 중지되어 서비스가 중단될 수 있습니다.",
  resource_type_getter=lambda *a, **k: "ec2",
  resource_name_getter=lambda *a, **k: k.get("instance_id", "unknown"),
  namespace_getter=lambda *a, **k: k.get("region", "default")
)
def stop_ec2_instance(*args, **kwargs):
  result = real_stop_ec2_instance(*args, **kwargs)
  user = kwargs.get("user", "unknown")
  instance_id = kwargs.get("instance_id", "unknown")
  send_action_log(user, f"EC2 인스턴스 중지({instance_id})", "실행됨")
  send_result_notification(f"EC2 인스턴스 중지({instance_id})", "관리자")
  return result

@approval_required(
  "파드 삭제",
  "이 작업은 파드가 삭제되어 서비스에 영향이 있을 수 있습니다.",
  resource_type_getter=lambda *a, **k: "pod",
  resource_name_getter=lambda *a, **k: k.get("pod_name", "unknown"),
  namespace_getter=lambda *a, **k: k.get("namespace", "default")
)
def delete_pod(namespace: str = "default", pod_name: str = "", **kwargs):
  result = real_delete_pod(namespace=namespace, pod_name=pod_name)
  user = kwargs.get("user", "unknown")
  send_action_log(user, f"파드 삭제({pod_name})", "실행됨")
  send_result_notification(f"파드 삭제({pod_name})", "관리자")
  return result

@approval_required(
  "디플로이먼트 삭제",
  "이 작업은 디플로이먼트가 삭제되어 서비스에 영향이 있을 수 있습니다.",
  resource_type_getter=lambda *a, **k: "deployment",
  resource_name_getter=lambda *a, **k: k.get("name", "unknown"),
  namespace_getter=lambda *a, **k: k.get("namespace", "default")
)
def delete_deployment(namespace: str = "default", name: str = "", **kwargs):
  result = real_delete_deployment(namespace=namespace, name=name)
  user = kwargs.get("user", "unknown")
  send_action_log(user, f"디플로이먼트 삭제({name})", "실행됨")
  send_result_notification(f"디플로이먼트 삭제({name})", "관리자")
  return result

# 승인 워크플로우가 적용된 민감 작업만 별도로 등록
for fn in [
  stop_ec2_instance,
  delete_pod,
  delete_deployment,
]:
  mcp.tool()(fn)

# 나머지 EC2 툴 등록
for fn in [
  list_ec2_instances, 
  describe_ec2_instance, 
  start_ec2_instance,
]:
  mcp.tool()(fn)

# FastMCP SSE 앱 생성
app = mcp.sse_app()

if __name__ == "__main__":
  import uvicorn
  uvicorn.run(
    "main:app",
    host="0.0.0.0",
    port=8080,
    log_level="info",
  )