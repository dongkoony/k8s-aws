# # mcp/workflows/slack_server.py

# from flask import Flask, request, jsonify
# from tools.kubernetes.pods import delete_pod
# from tools.kubernetes.deployments import delete_deployment
# from tools.aws.ec2 import stop_ec2_instance
# import json

# app = Flask(__name__)

# @app.route("/admin-approve", methods=["POST"])
# def admin_approve():
#   # 슬랙은 payload를 form-urlencoded로 보냄
#   if request.content_type and request.content_type.startswith("application/x-www-form-urlencoded"):
#     payload = json.loads(request.form["payload"])
#   else:
#     payload = request.json

#   # 슬랙에서 온 버튼 value 파싱
#   value = payload["actions"][0]["value"]  # 예: "pod|nginx-test|default|파드 삭제"
#   resource_type, resource_name, namespace, action = value.split("|")
#   result = None

#   if resource_type == "pod":
#     result = delete_pod(namespace=namespace, pod_name=resource_name)
#   elif resource_type == "deployment":
#     result = delete_deployment(namespace=namespace, name=resource_name)
#   elif resource_type == "ec2":
#     result = stop_ec2_instance(instance_id=resource_name)
#   else:
#     result = {"status": "error", "message": "알 수 없는 리소스 타입"}

#   return jsonify(result)

# if __name__ == "__main__":
#   app.run(host="0.0.0.0", port=8081)

from flask import Flask, request, jsonify
from functools import wraps
import hmac
import hashlib
import time
import json
from tools.kubernetes.pods import delete_pod
from tools.kubernetes.deployments import delete_deployment
from tools.aws.ec2 import stop_ec2_instance

app = Flask(__name__)

# Slack 설정
SLACK_SIGNING_SECRET = "YOUR_SLACK_SIGNING_SECRET"  # 환경 변수로 관리 필요

def verify_slack_request(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # 타임스탬프 검증 (5분 이내)
        timestamp = request.headers.get('X-Slack-Request-Timestamp', '')
        if abs(time.time() - float(timestamp)) > 60 * 5:
            return jsonify({"status": "error", "message": "Invalid timestamp"}), 403

        # 서명 검증
        sig_basestring = f"v0:{timestamp}:{request.get_data().decode('utf-8')}"
        my_signature = f"v0={hmac.new(SLACK_SIGNING_SECRET.encode('utf-8'), sig_basestring.encode('utf-8'), hashlib.sha256).hexdigest()}"
        slack_signature = request.headers.get('X-Slack-Signature', '')
        
        if not hmac.compare_digest(my_signature, slack_signature):
            return jsonify({"status": "error", "message": "Invalid signature"}), 403
            
        return f(*args, **kwargs)
    return decorated_function

@app.route("/admin-approve", methods=["POST"])
@verify_slack_request
def admin_approve():
    try:
        # Content-Type 확인 및 payload 파싱
        if request.content_type and request.content_type.startswith("application/x-www-form-urlencoded"):
            payload = json.loads(request.form["payload"])
        else:
            payload = request.json

        # 필수 필드 검증
        if not payload or "actions" not in payload or not payload["actions"]:
            return jsonify({
                "response_type": "ephemeral",
                "text": "Invalid request format"
            }), 400

        # 값 파싱
        try:
            value = payload["actions"][0]["value"]
            resource_type, resource_name, namespace, action = value.split("|")
        except (KeyError, ValueError, IndexError):
            return jsonify({
                "response_type": "ephemeral",
                "text": "Invalid action format"
            }), 400

        # 리소스 처리
        result = None
        if resource_type == "pod":
            result = delete_pod(namespace=namespace, pod_name=resource_name)
        elif resource_type == "deployment":
            result = delete_deployment(namespace=namespace, name=resource_name)
        elif resource_type == "ec2":
            result = stop_ec2_instance(instance_id=resource_name)
        else:
            return jsonify({
                "response_type": "ephemeral",
                "text": f"Unknown resource type: {resource_type}"
            }), 400

        # 결과 응답
        success_message = {
            "response_type": "in_channel",
            "text": f"✅ {action} 완료: {resource_type}/{resource_name}"
        }
        error_message = {
            "response_type": "ephemeral",
            "text": f"❌ {action} 실패: {result.get('message', '알 수 없는 오류')}"
        }

        return jsonify(success_message if result.get('status') == 'success' else error_message)

    except Exception as e:
        app.logger.error(f"Error processing request: {str(e)}")
        return jsonify({
            "response_type": "ephemeral",
            "text": "Internal server error"
        }), 503

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        "response_type": "ephemeral",
        "text": "Internal server error occurred"
    }), 500

@app.errorhandler(403)
def forbidden_error(error):
    return jsonify({
        "response_type": "ephemeral",
        "text": "Request verification failed"
    }), 403

if __name__ == "__main__":
    # 프로덕션에서는 gunicorn 등의 WSGI 서버 사용 권장
    app.run(host="0.0.0.0", port=8081, ssl_context="adhoc")