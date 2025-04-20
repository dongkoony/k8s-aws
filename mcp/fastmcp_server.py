from fastmcp import FastMCP
from kubernetes import client, config
import boto3

# FastMCP 서버 초기화
mcp = FastMCP("k8s-aws-copilot")

# Kubernetes 파드 목록 조회 툴
@mcp.tool()
def list_pods(namespace: str = "default") -> list:
    """지정한 네임스페이스의 파드 이름 목록을 반환합니다."""
    config.load_incluster_config()
    v1 = client.CoreV1Api()
    pods = v1.list_namespaced_pod(namespace)
    return [pod.metadata.name for pod in pods.items]

# EC2 인스턴스 상태 조회 툴
@mcp.tool()
def list_ec2_instances() -> dict:
    """EC2 인스턴스 ID와 상태를 딕셔너리 형태로 반환합니다."""
    ec2 = boto3.client("ec2")
    response = ec2.describe_instances()
    instances = {}
    for reservation in response.get("Reservations", []):
        for i in reservation.get("Instances", []):
            instances[i["InstanceId"]] = i["State"]["Name"]
    return instances

if __name__ == "__main__":
    # HTTP/SSE 서버를 기본 포트(8080)로 실행합니다.
    mcp.run()
