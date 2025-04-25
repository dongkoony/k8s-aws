# tools/kubernetes/deployments.py
from kubernetes import client
from .helpers import load_kube_config

def list_deployments(namespace: str = "default") -> dict:
    """
    지정된 네임스페이스의 Deployment 목록을 조회합니다.
    """
    load_kube_config()
    deps = client.AppsV1Api().list_namespaced_deployment(namespace)
    return {
        "status": "success",
        "deployments": [
            {
                "name": d.metadata.name,
                "ready": d.status.ready_replicas or 0,
                "available": d.status.available_replicas or 0,
                "desired": d.spec.replicas
            }
            for d in deps.items
        ]
    }

def describe_deployment(namespace: str = "default", name: str = "") -> dict:
    """
    특정 네임스페이스의 지정된 Deployment 상세 정보를 반환합니다.
    """
    load_kube_config()
    d = client.AppsV1Api().read_namespaced_deployment(name, namespace)
    return {
        "status": "success",
        "deployment": {
            "name": d.metadata.name,
            "namespace": d.metadata.namespace,
            "replicas": d.spec.replicas,
            "ready": d.status.ready_replicas or 0,
            "available": d.status.available_replicas or 0,
            "labels": d.spec.selector.match_labels,
            "strategy": d.spec.strategy.type
        }
    }

def create_deployment(name: str, image: str, namespace: str = "default", replicas: int = 1, labels: dict = None) -> dict:
    """
    이름(name), 이미지(image), 복제 수(replicas)를 이용해 Deployment를 생성합니다.
    """
    load_kube_config()
    api = client.AppsV1Api()
    if labels is None:
        labels = {"app": name}
    container = client.V1Container(
        name=name,
        image=image,
        ports=[client.V1ContainerPort(container_port=80)]
    )
    template = client.V1PodTemplateSpec(
        metadata=client.V1ObjectMeta(labels=labels),
        spec=client.V1PodSpec(containers=[container])
    )
    spec = client.V1DeploymentSpec(
        replicas=replicas,
        template=template,
        selector=client.V1LabelSelector(match_labels=labels),
        strategy=client.V1DeploymentStrategy(type="RollingUpdate")
    )
    deployment = client.V1Deployment(
        api_version="apps/v1",
        kind="Deployment",
        metadata=client.V1ObjectMeta(name=name),
        spec=spec
    )
    resp = api.create_namespaced_deployment(namespace=namespace, body=deployment)
    return {"status": "success", "name": resp.metadata.name}

def update_deployment(namespace: str = "default", name: str = "", image: str = None, replicas: int = None) -> dict:
    """
    Deployment의 이미지 또는 replicas를 패치(롤링 업데이트)합니다.
    """
    load_kube_config()
    api = client.AppsV1Api()
    body = {"spec": {}}
    if image:
        body["spec"]["template"] = {"spec": {"containers": [{"name": name, "image": image}]}}
    if replicas is not None:
        body["spec"]["replicas"] = replicas
    resp = api.patch_namespaced_deployment(name=name, namespace=namespace, body=body)
    return {"status": "success", "deployment": {"name": resp.metadata.name, "replicas": resp.spec.replicas}}

def delete_deployment(namespace: str = "default", name: str = "") -> dict:
    """
    특정 네임스페이스의 지정된 Deployment를 삭제합니다.
    """
    load_kube_config()
    api = client.AppsV1Api()
    api.delete_namespaced_deployment(name=name, namespace=namespace, body=client.V1DeleteOptions())
    return {"status": "success", "message": f"Deployment {name} deleted"}
