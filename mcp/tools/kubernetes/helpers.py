# tools/kubernetes/helpers.py
from kubernetes import config

def load_kube_config():
  """
  클러스터 내부에서 실행될 땐 in-cluster 설정을,
  개발 환경 로컬에서 실행될 땐 kubeconfig 파일을 로드합니다.
  """
  try:
    config.load_incluster_config()
  except Exception:
    config.load_kube_config()
