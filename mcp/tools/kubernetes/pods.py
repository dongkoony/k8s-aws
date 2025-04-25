# tools/kubernetes/pods.py
from kubernetes import client
import yaml
from .helpers import load_kube_config

def list_pods(namespace: str = "default") -> dict:
    """
    지정된 네임스페이스의 파드 목록을 조회합니다.
    """
    load_kube_config()
    try:
        pods = client.CoreV1Api().list_namespaced_pod(namespace)
        return {
            "status": "success",
            "pods": [
                {
                    "name": p.metadata.name,
                    "status": p.status.phase,
                    "node": p.spec.node_name or "Unknown"
                }
                for p in pods.items
            ]
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

def describe_pod(namespace: str = "default", pod_name: str = "") -> dict:
    """
    특정 네임스페이스의 지정된 파드 상세 정보를 반환합니다.
    """
    load_kube_config()
    try:
        pod = client.CoreV1Api().read_namespaced_pod(pod_name, namespace)
        return {
            "status": "success",
            "pod_info": {
                "name": pod.metadata.name,
                "namespace": pod.metadata.namespace,
                "status": pod.status.phase,
                "node": pod.spec.node_name or "Unknown",
                "ip": pod.status.pod_ip,
                "start_time": pod.status.start_time.isoformat() if pod.status.start_time else None,
                "containers": [
                    {
                        "name": c.name,
                        "image": c.image,
                        "ready": any(s.name == c.name and s.ready for s in (pod.status.container_statuses or []))
                    }
                    for c in pod.spec.containers
                ]
            }
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

def create_pod(name: str, image: str, namespace: str = "default", labels: dict = None) -> dict:
    """
    이름(name)과 이미지(image)를 이용해 새로운 파드를 생성합니다.
    """
    load_kube_config()
    try:
        api = client.CoreV1Api()
        if labels is None:
            labels = {"app": name}
        manifest = client.V1Pod(
            api_version="v1",
            kind="Pod",
            metadata=client.V1ObjectMeta(name=name, labels=labels),
            spec=client.V1PodSpec(containers=[
                client.V1Container(name=name, image=image, ports=[client.V1ContainerPort(container_port=80)])
            ])
        )
        resp = api.create_namespaced_pod(namespace=namespace, body=manifest)
        return {"status": "success", "name": resp.metadata.name, "uid": resp.metadata.uid}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def apply_yaml(yaml_content: str) -> dict:
    """
    YAML 콘텐츠를 파싱해 Pod 오브젝트를 생성합니다.
    """
    load_kube_config()
    try:
        spec = yaml.safe_load(yaml_content)
        if spec.get("kind") != "Pod":
            return {"status": "error", "message": "지원하는 Kind: Pod 만 가능합니다."}
        api = client.CoreV1Api()
        resp = api.create_namespaced_pod(
            namespace=spec.get("metadata", {}).get("namespace", "default"),
            body=spec
        )
        return {"status": "success", "name": resp.metadata.name, "uid": resp.metadata.uid}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def delete_pod(namespace: str = "default", pod_name: str = "") -> dict:
    """
    특정 네임스페이스의 지정된 파드를 삭제합니다.
    """
    load_kube_config()
    try:
        api = client.CoreV1Api()
        api.delete_namespaced_pod(name=pod_name, namespace=namespace, body=client.V1DeleteOptions())
        return {"status": "success", "message": f"Pod {pod_name} deleted"}
    except Exception as e:
        return {"status": "error", "message": str(e)}
