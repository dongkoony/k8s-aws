# # mcp/workflows/slack_server.py

from flask import Flask, request, jsonify
from functools import wraps
import hmac
import hashlib
import time
import json
import os
from dotenv import load_dotenv
from tools.kubernetes.pods import delete_pod
from tools.kubernetes.deployments import delete_deployment
from tools.aws.ec2 import stop_ec2_instance

app = Flask(__name__)

# Slack 설정
SLACK_SIGNING_SECRET = os.getenv("SLACK_SIGNING_SECRET")

# 리소스 타입별 이모지 매핑
RESOURCE_EMOJI = {
    "pod": "📦",
    "deployment": "🚀",
    "ec2": "💻"
}

# 상태별 이모지와 스타일
STATUS_STYLE = {
    "success": {
        "emoji": "✨",
        "color": "#36a64f",  # 초록색
        "title_emoji": "🎉"
    },
    "error": {
        "emoji": "❌",
        "color": "#dc3545",  # 빨간색
        "title_emoji": "⚠️"
    },
    "waiting": {
        "emoji": "⏳",
        "color": "#f4c148",  # 노란색
        "title_emoji": "⌛"
    }
}

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

        # 상태에 따른 스타일 선택
        status = "success" if result.get('status') == 'success' else "error"
        style = STATUS_STYLE[status]
        resource_emoji = RESOURCE_EMOJI.get(resource_type, "🔧")

        # 결과 응답
        response = {
            "response_type": "in_channel",
            "attachments": [
                {
                    "color": style["color"],
                    "blocks": [
                        {
                            "type": "header",
                            "text": {
                                "type": "plain_text",
                                "text": f"{style['title_emoji']} 작업 결과 알림"
                            }
                        },
                        {
                            "type": "section",
                            "text": {
                                "type": "mrkdwn",
                                "text": f"*작업:* {action}\n*리소스:* {resource_emoji} {resource_type}/{resource_name}\n*네임스페이스:* {namespace}"
                            }
                        },
                        {
                            "type": "context",
                            "elements": [
                                {
                                    "type": "mrkdwn",
                                    "text": f"{style['emoji']} *상태:* {'성공' if status == 'success' else '실패'}"
                                }
                            ]
                        }
                    ]
                }
            ]
        }

        if status == "error":
            response["attachments"][0]["blocks"].append({
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*에러 메시지:*\n```{result.get('message', '알 수 없는 오류')}```"
                }
            })

        return jsonify(response)

    except Exception as e:
        app.logger.error(f"Error processing request: {str(e)}")
        style = STATUS_STYLE["error"]
        return jsonify({
            "response_type": "ephemeral",
            "attachments": [
                {
                    "color": style["color"],
                    "blocks": [
                        {
                            "type": "header",
                            "text": {
                                "type": "plain_text",
                                "text": f"{style['title_emoji']} 오류 발생"
                            }
                        },
                        {
                            "type": "section",
                            "text": {
                                "type": "mrkdwn",
                                "text": "내부 서버 오류가 발생했습니다."
                            }
                        }
                    ]
                }
            ]
        }), 503

@app.errorhandler(500)
def internal_error(error):
    style = STATUS_STYLE["error"]
    return jsonify({
        "response_type": "ephemeral",
        "attachments": [
            {
                "color": style["color"],
                "blocks": [
                    {
                        "type": "header",
                        "text": {
                            "type": "plain_text",
                            "text": f"{style['title_emoji']} 서버 오류"
                        }
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": "서버에서 오류가 발생했습니다."
                        }
                    }
                ]
            }
        ]
    }), 500

@app.errorhandler(403)
def forbidden_error(error):
    style = STATUS_STYLE["error"]
    return jsonify({
        "response_type": "ephemeral",
        "attachments": [
            {
                "color": style["color"],
                "blocks": [
                    {
                        "type": "header",
                        "text": {
                            "type": "plain_text",
                            "text": f"{style['title_emoji']} 접근 거부"
                        }
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": "요청 검증에 실패했습니다."
                        }
                    }
                ]
            }
        ]
    }), 403

if __name__ == "__main__":
    
    app.run(host="0.0.0.0", port=8081, ssl_context="adhoc")