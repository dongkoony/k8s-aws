# mcp/workflows/slack_approval.py
from dotenv import load_dotenv
import os
import requests
import datetime

load_dotenv()

SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL")

def send_approval_request(user, action, impact):
  message = (
    f"*[승인 요청]*\n"
    f"사용자: {user}\n"
    f"요청 작업: {action}\n"
    f"영향도: {impact}\n"
    f"승인하려면 '승인'이라고 답장하세요."
  )
  requests.post(SLACK_WEBHOOK_URL, json={"text": message})

def send_approval_request_with_button(user, action, impact, resource_type, resource_name, namespace="default"):
  """
  슬랙에 승인 버튼이 포함된 메시지를 전송합니다.
  resource_type: pod, deployment, ec2 등
  resource_name: 리소스 이름 또는 인스턴스 ID
  namespace: 네임스페이스(기본값 default)
  """
  message = {
    "blocks": [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": f"*승인 요청*\n사용자: {user}\n작업: {action}\n영향도: {impact}"
        }
      },
      {
        "type": "actions",
        "elements": [
          {
            "type": "button",
            "text": {"type": "plain_text", "text": "승인"},
            "style": "primary",
            "value": f"{resource_type}|{resource_name}|{namespace}|{action}"
          }
        ]
      }
    ]
  }
  requests.post(SLACK_WEBHOOK_URL, json=message)

def send_action_log(user, action, status):
  log_message = f"{datetime.datetime.now()} | {user} | {action} | {status}"
  # 파일 또는 DB에 로그 저장
  with open("action_log.txt", "a") as f:
    f.write(log_message + "\n")
  # Slack 알림도 보낼 수 있음
  requests.post(SLACK_WEBHOOK_URL, json={"text": f"[작업 로그] {log_message}"})

def send_result_notification(action, admin):
  requests.post(SLACK_WEBHOOK_URL, json={"text": f"{action} 작업이 실행되었습니다. (승인자: {admin})"})