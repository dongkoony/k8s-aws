# mcp/workflows/slack_server.py

from flask import Flask, request, jsonify
from tools.kubernetes.pods import delete_pod
from tools.kubernetes.deployments import delete_deployment
from tools.aws.ec2 import stop_ec2_instance

app = Flask(__name__)

@app.route("/admin-approve", methods=["POST"])
def admin_approve():
  payload = request.json
  # 슬랙에서 온 버튼 value 파싱
  value = payload["actions"][0]["value"]  # 예: "pod|nginx-test|default|파드 삭제"
  resource_type, resource_name, namespace, action = value.split("|")
  result = None

  if resource_type == "pod":
    result = delete_pod(namespace=namespace, pod_name=resource_name)
  elif resource_type == "deployment":
    result = delete_deployment(namespace=namespace, name=resource_name)
  elif resource_type == "ec2":
    result = stop_ec2_instance(instance_id=resource_name)
  else:
    result = {"status": "error", "message": "알 수 없는 리소스 타입"}

  return jsonify(result)

if __name__ == "__main__":
  app.run(host="0.0.0.0", port=8081)