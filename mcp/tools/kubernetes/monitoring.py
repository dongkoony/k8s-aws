from kubernetes import client, config
from typing import Dict, List, Any, Optional
import time
from datetime import datetime, timedelta

def get_cluster_metrics() -> Dict[str, Any]:
    """
    클러스터 전반적인 메트릭 수집
    """
    try:
        v1 = client.CoreV1Api()
        custom = client.CustomObjectsApi()
        
        # 노드 메트릭 수집
        nodes = v1.list_node()
        node_metrics = custom.list_cluster_custom_object(
            group="metrics.k8s.io",
            version="v1beta1",
            plural="nodes"
        )
        
        # 전체 클러스터 리소스 사용량 계산
        total_cpu_capacity = 0
        total_memory_capacity = 0
        total_cpu_usage = 0
        total_memory_usage = 0
        
        for node in nodes.items:
            cpu = int(node.status.capacity['cpu'])
            memory = int(node.status.capacity['memory'].replace('Ki', ''))
            total_cpu_capacity += cpu
            total_memory_capacity += memory
            
        for metric in node_metrics['items']:
            cpu_usage = int(metric['usage']['cpu'].replace('n', '')) / 1000000000
            memory_usage = int(metric['usage']['memory'].replace('Ki', ''))
            total_cpu_usage += cpu_usage
            total_memory_usage += memory_usage
            
        return {
            "cluster_metrics": {
                "cpu": {
                    "capacity": total_cpu_capacity,
                    "usage": total_cpu_usage,
                    "usage_percentage": (total_cpu_usage / total_cpu_capacity) * 100
                },
                "memory": {
                    "capacity": total_memory_capacity,
                    "usage": total_memory_usage,
                    "usage_percentage": (total_memory_usage / total_memory_capacity) * 100
                }
            }
        }
    except Exception as e:
        return {"error": f"Failed to get cluster metrics: {str(e)}"}

def get_pod_metrics(namespace: str = "default") -> Dict[str, Any]:
    """
    네임스페이스별 파드 메트릭 수집
    """
    try:
        custom = client.CustomObjectsApi()
        pod_metrics = custom.list_namespaced_custom_object(
            group="metrics.k8s.io",
            version="v1beta1",
            namespace=namespace,
            plural="pods"
        )
        
        metrics_by_pod = {}
        for pod in pod_metrics['items']:
            pod_name = pod['metadata']['name']
            containers = pod['containers']
            
            total_cpu = 0
            total_memory = 0
            container_metrics = {}
            
            for container in containers:
                cpu_usage = int(container['usage']['cpu'].replace('n', '')) / 1000000000
                memory_usage = int(container['usage']['memory'].replace('Ki', ''))
                total_cpu += cpu_usage
                total_memory += memory_usage
                
                container_metrics[container['name']] = {
                    "cpu_usage": cpu_usage,
                    "memory_usage": memory_usage
                }
            
            metrics_by_pod[pod_name] = {
                "total": {
                    "cpu_usage": total_cpu,
                    "memory_usage": total_memory
                },
                "containers": container_metrics
            }
            
        return metrics_by_pod
    except Exception as e:
        return {"error": f"Failed to get pod metrics: {str(e)}"}

def get_node_health() -> Dict[str, Any]:
    """
    노드 상태 및 health check
    """
    try:
        v1 = client.CoreV1Api()
        nodes = v1.list_node()
        
        node_health = {}
        for node in nodes.items:
            conditions = {cond.type: cond.status for cond in node.status.conditions}
            ready_status = conditions.get('Ready', 'Unknown')
            
            # 디스크 압박, 메모리 압박, PID 압박 상태 확인
            pressure_statuses = {
                'DiskPressure': conditions.get('DiskPressure', 'Unknown'),
                'MemoryPressure': conditions.get('MemoryPressure', 'Unknown'),
                'PIDPressure': conditions.get('PIDPressure', 'Unknown')
            }
            
            node_health[node.metadata.name] = {
                "ready": ready_status == "True",
                "conditions": pressure_statuses,
                "allocatable": {
                    "cpu": node.status.allocatable['cpu'],
                    "memory": node.status.allocatable['memory'],
                    "pods": node.status.allocatable['pods']
                }
            }
            
        return node_health
    except Exception as e:
        return {"error": f"Failed to get node health: {str(e)}"}

def get_deployment_health(namespace: str = "default") -> Dict[str, Any]:
    """
    디플로이먼트 상태 및 health check
    """
    try:
        apps_v1 = client.AppsV1Api()
        deployments = apps_v1.list_namespaced_deployment(namespace)
        
        deployment_health = {}
        for dep in deployments.items:
            name = dep.metadata.name
            spec_replicas = dep.spec.replicas
            available_replicas = dep.status.available_replicas or 0
            
            # 업데이트 상태 확인
            update_status = "Stable"
            if dep.status.conditions:
                for condition in dep.status.conditions:
                    if condition.type == "Progressing" and condition.status == "True":
                        update_status = "Updating"
                    elif condition.type == "Available" and condition.status != "True":
                        update_status = "NotAvailable"
            
            deployment_health[name] = {
                "desired_replicas": spec_replicas,
                "available_replicas": available_replicas,
                "health_percentage": (available_replicas / spec_replicas * 100) if spec_replicas > 0 else 0,
                "update_status": update_status
            }
            
        return deployment_health
    except Exception as e:
        return {"error": f"Failed to get deployment health: {str(e)}"}

def get_pod_logs_analysis(namespace: str = "default", pod_name: str = None, 
                        container_name: str = None, hours: int = 1) -> Dict[str, Any]:
    """
    파드 로그 분석
    """
    try:
        v1 = client.CoreV1Api()
        
        # 시간 범위 설정
        since_seconds = int(timedelta(hours=hours).total_seconds())
        
        if pod_name:
            pods = [v1.read_namespaced_pod(pod_name, namespace)]
        else:
            pods = v1.list_namespaced_pod(namespace).items
            
        log_analysis = {}
        for pod in pods:
            pod_name = pod.metadata.name
            containers = pod.spec.containers
            
            container_logs = {}
            for container in containers:
                if container_name and container.name != container_name:
                    continue
                    
                try:
                    logs = v1.read_namespaced_pod_log(
                        pod_name,
                        namespace,
                        container=container.name,
                        since_seconds=since_seconds
                    )
                    
                    # 에러 패턴 분석
                    error_count = logs.lower().count('error')
                    warning_count = logs.lower().count('warn')
                    exception_count = logs.lower().count('exception')
                    
                    container_logs[container.name] = {
                        "error_count": error_count,
                        "warning_count": warning_count,
                        "exception_count": exception_count,
                        "total_issues": error_count + warning_count + exception_count
                    }
                except Exception as e:
                    container_logs[container.name] = {"error": f"Failed to get logs: {str(e)}"}
                    
            log_analysis[pod_name] = container_logs
            
        return log_analysis
    except Exception as e:
        return {"error": f"Failed to analyze pod logs: {str(e)}"}

def get_resource_events(namespace: str = "default", resource_type: str = None, 
                    resource_name: str = None) -> Dict[str, Any]:
    """
    리소스 이벤트 수집 및 분석
    """
    try:
        v1 = client.CoreV1Api()
        events = v1.list_namespaced_event(namespace)
        
        filtered_events = []
        for event in events.items:
            if resource_type and event.involved_object.kind.lower() != resource_type.lower():
                continue
            if resource_name and event.involved_object.name != resource_name:
                continue
                
            filtered_events.append({
                "type": event.type,
                "reason": event.reason,
                "message": event.message,
                "count": event.count,
                "first_timestamp": event.first_timestamp.strftime("%Y-%m-%d %H:%M:%S") if event.first_timestamp else None,
                "last_timestamp": event.last_timestamp.strftime("%Y-%m-%d %H:%M:%S") if event.last_timestamp else None,
                "involved_object": {
                    "kind": event.involved_object.kind,
                    "name": event.involved_object.name
                }
            })
            
        return {
            "events": filtered_events,
            "total_count": len(filtered_events),
            "warning_count": sum(1 for e in filtered_events if e["type"] == "Warning"),
            "normal_count": sum(1 for e in filtered_events if e["type"] == "Normal")
        }
    except Exception as e:
        return {"error": f"Failed to get resource events: {str(e)}"} 