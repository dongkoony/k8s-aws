# main.py
from fastmcp import FastMCP

# 1) FastMCP 인스턴스 생성
mcp = FastMCP("k8s-aws-copilot")

# 2) Kubernetes 관련 툴 등록
from tools.kubernetes.pods import (
  list_pods,
  describe_pod,
  create_pod,
  apply_yaml,
  delete_pod,
)
for fn in [list_pods, describe_pod, create_pod, apply_yaml, delete_pod]:
    mcp.tool()(fn)

# 3) AWS EC2 관련 툴 등록
from tools.aws.ec2 import (
  list_ec2_instances,
  describe_ec2_instance,
  start_ec2_instance,
  stop_ec2_instance,
)
for fn in [list_ec2_instances, describe_ec2_instance, start_ec2_instance, stop_ec2_instance]:
  mcp.tool()(fn)

# # 4) SSE 앱 생성 및 실행
# app = mcp.sse_app()

# if __name__ == "__main__":
#   import uvicorn
#   uvicorn.run("main:app", host="0.0.0.0", port=8080, log_level="info")

# 4) FastMCP SSE 앱 생성
app = mcp.sse_app()
# app = FastAPI(openapi_url="/openapi.json")  # 명시적 OpenAPI URL 설정 (테스트용)

# 5) uvicorn으로 실행
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",  # '파일명:app객체'
        host="0.0.0.0",
        port=8080,
        log_level="info",
    )
