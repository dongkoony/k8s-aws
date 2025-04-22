from fastmcp import FastMCP
from kubernetes import client, config
import boto3
from fastapi import FastAPI
import os
import json

# 1) MCP 서버 인스턴스 생성
mcp = FastMCP("k8s-aws-copilot")

# 2) 쿠버네티스 관련 도구 정의
@mcp.tool()
def list_pods(namespace: str = "default") -> dict:
    """
    지정된 네임스페이스의 쿠버네티스 파드 목록을 반환합니다.
    """
    try:
        # 환경에 따라 쿠버네티스 설정 로드
        try:
            config.load_incluster_config()  # 클러스터 내부 실행 시
        except:
            config.load_kube_config()       # 로컬 개발 환경 실행 시
        
        # 파드 목록 조회
        pods = client.CoreV1Api().list_namespaced_pod(namespace)
        return {
            "status": "success",
            "pods": [
                {
                    "name": p.metadata.name,
                    "status": p.status.phase,
                    "node": p.spec.node_name if p.spec.node_name else "Unknown"
                }
                for p in pods.items
            ]
        }
    except Exception as e:
        return {"status": "error", "message": f"Failed to list pods: {str(e)}"}

@mcp.tool()
def describe_pod(namespace: str = "default", pod_name: str = "") -> dict:
    """
    특정 파드의 상세 정보를 반환합니다.
    """
    try:
        # 환경에 따라 쿠버네티스 설정 로드
        try:
            config.load_incluster_config()
        except:
            config.load_kube_config()
        
        # 파드 정보 조회
        pod = client.CoreV1Api().read_namespaced_pod(pod_name, namespace)
        return {
            "status": "success",
            "pod_info": {
                "name": pod.metadata.name,
                "namespace": pod.metadata.namespace,
                "status": pod.status.phase,
                "node": pod.spec.node_name if pod.spec.node_name else "Unknown",
                "ip": pod.status.pod_ip,
                "start_time": pod.status.start_time.isoformat() if pod.status.start_time else None,
                "containers": [
                    {
                        "name": container.name,
                        "image": container.image,
                        "ready": any(status.name == container.name and status.ready 
                                    for status in pod.status.container_statuses if status)
                                  if pod.status.container_statuses else False
                    }
                    for container in pod.spec.containers
                ]
            }
        }
    except Exception as e:
        return {"status": "error", "message": f"Failed to describe pod: {str(e)}"}

@mcp.tool()
def delete_pod(namespace: str = "default", pod_name: str = "") -> dict:
    """
    특정 파드를 삭제합니다.
    """
    try:
        # 환경에 따라 쿠버네티스 설정 로드
        try:
            config.load_incluster_config()
        except:
            config.load_kube_config()
        
        # 파드 삭제
        api_response = client.CoreV1Api().delete_namespaced_pod(
            name=pod_name,
            namespace=namespace,
            body=client.V1DeleteOptions()
        )
        return {"status": "success", "message": f"Pod {pod_name} deleted"}
    except Exception as e:
        return {"status": "error", "message": f"Failed to delete pod: {str(e)}"}

# 3) AWS 관련 도구 정의
@mcp.tool()
def list_ec2_instances(region: str = None) -> dict:
    """
    AWS EC2 인스턴스 목록과 상태를 반환합니다.
    """
    try:
        ec2 = boto3.client("ec2", region_name=region) if region else boto3.client("ec2")
        instances_data = []
        
        for r in ec2.describe_instances().get("Reservations", []):
            for i in r.get("Instances", []):
                # 태그에서 Name 추출
                name = "Unnamed"
                for tag in i.get("Tags", []):
                    if tag["Key"] == "Name":
                        name = tag["Value"]
                        break
                
                instances_data.append({
                    "instance_id": i["InstanceId"],
                    "name": name,
                    "state": i["State"]["Name"],
                    "instance_type": i.get("InstanceType", "Unknown"),
                    "private_ip": i.get("PrivateIpAddress", ""),
                    "public_ip": i.get("PublicIpAddress", "")
                })
        
        return {
            "status": "success",
            "instances": instances_data
        }
    except Exception as e:
        return {"status": "error", "message": f"Failed to list EC2 instances: {str(e)}"}

@mcp.tool()
def describe_ec2_instance(instance_id: str, region: str = None) -> dict:
    """
    특정 EC2 인스턴스의 상세 정보를 반환합니다.
    """
    try:
        ec2 = boto3.client("ec2", region_name=region) if region else boto3.client("ec2")
        response = ec2.describe_instances(InstanceIds=[instance_id])
        
        if not response.get("Reservations") or not response["Reservations"][0].get("Instances"):
            return {"status": "error", "message": f"Instance {instance_id} not found"}
        
        instance = response["Reservations"][0]["Instances"][0]
        
        # 태그에서 Name 추출
        name = "Unnamed"
        for tag in instance.get("Tags", []):
            if tag["Key"] == "Name":
                name = tag["Value"]
                break
        
        return {
            "status": "success",
            "instance_details": {
                "instance_id": instance["InstanceId"],
                "name": name,
                "state": instance["State"]["Name"],
                "instance_type": instance.get("InstanceType", "Unknown"),
                "launch_time": instance.get("LaunchTime", "").isoformat() if "LaunchTime" in instance else "",
                "private_ip": instance.get("PrivateIpAddress", ""),
                "public_ip": instance.get("PublicIpAddress", ""),
                "vpc_id": instance.get("VpcId", ""),
                "subnet_id": instance.get("SubnetId", ""),
                "security_groups": [sg["GroupName"] for sg in instance.get("SecurityGroups", [])]
            }
        }
    except Exception as e:
        return {"status": "error", "message": f"Failed to describe EC2 instance: {str(e)}"}

@mcp.tool()
def start_ec2_instance(instance_id: str, region: str = None) -> dict:
    """
    특정 EC2 인스턴스를 시작합니다.
    """
    try:
        ec2 = boto3.client("ec2", region_name=region) if region else boto3.client("ec2")
        response = ec2.start_instances(InstanceIds=[instance_id])
        return {
            "status": "success",
            "message": f"Starting instance {instance_id}",
            "previous_state": response["StartingInstances"][0]["PreviousState"]["Name"],
            "current_state": response["StartingInstances"][0]["CurrentState"]["Name"]
        }
    except Exception as e:
        return {"status": "error", "message": f"Failed to start EC2 instance: {str(e)}"}

@mcp.tool()
def stop_ec2_instance(instance_id: str, region: str = None) -> dict:
    """
    특정 EC2 인스턴스를 중지합니다.
    """
    try:
        ec2 = boto3.client("ec2", region_name=region) if region else boto3.client("ec2")
        response = ec2.stop_instances(InstanceIds=[instance_id])
        return {
            "status": "success",
            "message": f"Stopping instance {instance_id}",
            "previous_state": response["StoppingInstances"][0]["PreviousState"]["Name"],
            "current_state": response["StoppingInstances"][0]["CurrentState"]["Name"]
        }
    except Exception as e:
        return {"status": "error", "message": f"Failed to stop EC2 instance: {str(e)}"}

# 4) FastMCP SSE 앱 생성
app = mcp.sse_app()
# app = FastAPI(openapi_url="/openapi.json")  # 명시적 OpenAPI URL 설정 (테스트용)

# 5) uvicorn으로 실행
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "fastmcp_server:app",  # '파일명:app객체'
        host="0.0.0.0",
        port=8080,
        log_level="info",
    )
