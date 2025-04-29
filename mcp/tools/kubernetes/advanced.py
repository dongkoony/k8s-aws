# tools/kubernetes/advanced.py

from kubernetes import client
from .helpers import load_kube_config

def list_hpa(namespace: str = "default") -> dict:
    """
    지정된 네임스페이스의 HorizontalPodAutoscaler 목록을 조회합니다.
    """
    load_kube_config()
    api = client.AutoscalingV2Api()
    hpas = api.list_namespaced_horizontal_pod_autoscaler(namespace)
    return {
        "status": "success",
        "hpas": [
            {
                "name": hpa.metadata.name,
                "target_kind": hpa.spec.scale_target_ref.kind,
                "target_name": hpa.spec.scale_target_ref.name,
                "min_replicas": hpa.spec.min_replicas,
                "max_replicas": hpa.spec.max_replicas,
                "current_replicas": hpa.status.current_replicas
            }
            for hpa in hpas.items
        ]
    }

def create_hpa(name: str, target_kind: str, target_name: str, 
            namespace: str = "default", min_replicas: int = 1, 
            max_replicas: int = 10, cpu_utilization: int = 70) -> dict: 
    """
    CPU 사용률 기반 HorizontalPodAutoscaler를 생성합니다.
    """
    load_kube_config()
    api = client.AutoscalingV2Api()
    
    target = client.V2CrossVersionObjectReference(
        api_version="apps/v1",
        kind=target_kind,
        name=target_name
    )
    
    metric_spec = client.V2MetricSpec(
        type="Resource",
        resource=client.V2ResourceMetricSource(
            name="cpu",
            target=client.V2MetricTarget(
                type="Utilization",
                average_utilization=cpu_utilization
            )
        )
    )
    
    hpa = client.V2HorizontalPodAutoscaler(
        api_version="autoscaling/v2",
        kind="HorizontalPodAutoscaler",
        metadata=client.V1ObjectMeta(name=name),
        spec=client.V2HorizontalPodAutoscalerSpec(
            scale_target_ref=target,
            min_replicas=min_replicas,
            max_replicas=max_replicas,
            metrics=[metric_spec]
        )
    )
    
    resp = api.create_namespaced_horizontal_pod_autoscaler(
        namespace=namespace, 
        body=hpa
    )
    
    return {
        "status": "success", 
        "hpa": {
            "name": resp.metadata.name,
            "namespace": resp.metadata.namespace,
            "min_replicas": resp.spec.min_replicas,
            "max_replicas": resp.spec.max_replicas
        }
    }

def list_statefulsets(namespace: str = "default") -> dict:
    """
    지정된 네임스페이스의 StatefulSet 목록을 조회합니다.
    """
    load_kube_config()
    api = client.AppsV1Api()
    statefulsets = api.list_namespaced_stateful_set(namespace)
    return {
        "status": "success",
        "statefulsets": [
            {
                "name": ss.metadata.name,
                "ready": ss.status.ready_replicas or 0,
                "current": ss.status.current_replicas or 0,
                "desired": ss.spec.replicas
            }
            for ss in statefulsets.items
        ]
    }

def create_statefulset(name: str, image: str, namespace: str = "default", 
                    replicas: int = 1, storage_size: str = "1Gi") -> dict:
    """
    이름, 이미지, 복제 수, 스토리지 크기를 이용해 StatefulSet을 생성합니다.
    """
    load_kube_config()
    api = client.AppsV1Api()
    
    labels = {"app": name}
    
    container = client.V1Container(
        name=name,
        image=image,
        ports=[client.V1ContainerPort(container_port=80)],
        volume_mounts=[client.V1VolumeMount(
            name="data",
            mount_path="/data"
        )]
    )
    
    pvc_template = client.V1PersistentVolumeClaim(
        metadata=client.V1ObjectMeta(name="data"),
        spec=client.V1PersistentVolumeClaimSpec(
            access_modes=["ReadWriteOnce"],
            resources=client.V1ResourceRequirements(
                requests={"storage": storage_size}
            )
        )
    )
    
    statefulset = client.V1StatefulSet(
        api_version="apps/v1",
        kind="StatefulSet",
        metadata=client.V1ObjectMeta(name=name),
        spec=client.V1StatefulSetSpec(
            service_name=f"{name}-headless",
            replicas=replicas,
            selector=client.V1LabelSelector(
                match_labels=labels
            ),
            template=client.V1PodTemplateSpec(
                metadata=client.V1ObjectMeta(labels=labels),
                spec=client.V1PodSpec(
                    containers=[container]
                )
            ),
            volume_claim_templates=[pvc_template]
        )
    )
    
    resp = api.create_namespaced_stateful_set(
        namespace=namespace,
        body=statefulset
    )
    
    return {
        "status": "success",
        "statefulset": {
            "name": resp.metadata.name,
            "namespace": resp.metadata.namespace,
            "replicas": resp.spec.replicas
        }
    }

def create_cronjob(name: str, schedule: str, image: str, 
                command: list = None, namespace: str = "default") -> dict:
    """
    이름, 일정, 이미지, 명령어를 이용해 CronJob을 생성합니다.
    """
    load_kube_config()
    api = client.BatchV1Api()
    
    if command is None:
        command = ["/bin/sh", "-c", "echo Hello from CronJob"]
    
    cronjob = client.V1CronJob(
        api_version="batch/v1",
        kind="CronJob",
        metadata=client.V1ObjectMeta(name=name),
        spec=client.V1CronJobSpec(
            schedule=schedule,
            job_template=client.V1JobTemplateSpec(
                spec=client.V1JobSpec(
                    template=client.V1PodTemplateSpec(
                        spec=client.V1PodSpec(
                            restart_policy="OnFailure",
                            containers=[client.V1Container(
                                name=name,
                                image=image,
                                command=command
                            )]
                        )
                    )
                )
            )
        )
    )
    
    resp = api.create_namespaced_cron_job(
        namespace=namespace,
        body=cronjob
    )
    
    return {
        "status": "success",
        "cronjob": {
            "name": resp.metadata.name,
            "namespace": resp.metadata.namespace,
            "schedule": resp.spec.schedule
        }
    }

def create_canary_deployment(name: str, namespace: str = "default", new_image: str = None,
                        canary_replicas: int = 1, total_replicas: int = 10) -> dict:
    """
    카나리 배포를 생성합니다. 새 버전을 일부 사용자에게만 적용하는 방식입니다.
    """
    load_kube_config()
    api = client.AppsV1Api()
    
    try:
        # 기존 디플로이먼트 정보 가져오기
        current_deploy = api.read_namespaced_deployment(
            name=name, namespace=namespace
        )
        
        # 기존 이미지 사용
        if new_image is None:
            new_image = current_deploy.spec.template.spec.containers[0].image
        
        # 카나리 디플로이먼트 이름
        canary_name = f"{name}-canary"
        
        # 카나리 레이블
        canary_labels = {
            "app": name, 
            "track": "canary"
        }
        
        # 카나리 디플로이먼트 생성
        canary_deploy = client.V1Deployment(
            api_version="apps/v1",
            kind="Deployment",
            metadata=client.V1ObjectMeta(
                name=canary_name,
                labels=canary_labels
            ),
            spec=client.V1DeploymentSpec(
                replicas=canary_replicas,
                selector=client.V1LabelSelector(
                    match_labels=canary_labels
                ),
                template=client.V1PodTemplateSpec(
                    metadata=client.V1ObjectMeta(
                        labels=canary_labels
                    ),
                    spec=client.V1PodSpec(
                        containers=[
                            client.V1Container(
                                name=current_deploy.spec.template.spec.containers[0].name,
                                image=new_image,
                                ports=current_deploy.spec.template.spec.containers[0].ports
                            )
                        ]
                    )
                )
            )
        )
        
        # 기존 디플로이먼트 축소
        api.patch_namespaced_deployment(
            name=name,
            namespace=namespace,
            body={"spec": {"replicas": total_replicas - canary_replicas}}
        )
        
        # 카나리 디플로이먼트 생성
        resp = api.create_namespaced_deployment(
            namespace=namespace,
            body=canary_deploy
        )
        
        return {
            "status": "success",
            "message": f"카나리 배포 시작: {canary_replicas}/{total_replicas}개의 레플리카가 {new_image} 이미지 사용",
            "canary_deployment": canary_name,
            "original_deployment": name
        }
    except client.exceptions.ApiException as e:
        return {
            "status": "error",
            "message": f"카나리 배포 생성 실패: {e}"
        }

def create_pod_disruption_budget(name: str, app_selector: str, min_available: str, 
                                namespace: str = "default") -> dict:
    """
    애플리케이션에 대한 PodDisruptionBudget을 생성하여 워크로드 가용성을 유지합니다.
    """
    load_kube_config()
    api = client.PolicyV1Api()
    
    pdb = client.V1PodDisruptionBudget(
        api_version="policy/v1",
        kind="PodDisruptionBudget",
        metadata=client.V1ObjectMeta(name=name),
        spec=client.V1PodDisruptionBudgetSpec(
            min_available=min_available,
            selector=client.V1LabelSelector(
                match_labels={"app": app_selector}
            )
        )
    )
    
    resp = api.create_namespaced_pod_disruption_budget(
        namespace=namespace,
        body=pdb
    )
    
    return {
        "status": "success",
        "pod_disruption_budget": {
            "name": resp.metadata.name,
            "namespace": resp.metadata.namespace,
            "min_available": resp.spec.min_available
        }
    }