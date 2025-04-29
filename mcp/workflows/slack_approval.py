# mcp/workflows/slack_approval.py
from dotenv import load_dotenv
import os
import requests
import datetime

load_dotenv()

SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL")

def send_approval_request_with_button(user, action, impact, resource_type, resource_name, namespace="default"):
  """
  resource_type: pod, deployment, ec2 등
  resource_name: 리소스 이름 또는 인스턴스 ID
  namespace: 네임스페이스(기본값 default)
  """
  current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
  
  # 리소스 타입에 따른 이모지 매핑
  resource_emoji = {
    "pod": "🐳",
    "deployment": "🚀",
    "ec2": "💻",
    "unknown": "❓"
  }
  
  emoji = resource_emoji.get(resource_type.lower(), resource_emoji["unknown"])
  
  message = {
    "blocks": [
      {
        "type": "header",
        "text": {
          "type": "plain_text",
          "text": f"🔔 새로운 승인 요청",
          "emoji": True
        }
      },
      {
        "type": "divider"
      },
      {
        "type": "section",
        "fields": [
          {
            "type": "mrkdwn",
            "text": f"*👤 요청자:*\n{user}"
          },
          {
            "type": "mrkdwn",
            "text": f"*⏰ 요청 시간:*\n{current_time}"
          }
        ]
      },
      {
        "type": "section",
        "fields": [
          {
            "type": "mrkdwn",
            "text": f"*{emoji} 리소스:*\n{resource_type}/{resource_name}"
          },
          {
            "type": "mrkdwn",
            "text": f"*🎯 네임스페이스:*\n{namespace}"
          }
        ]
      },
      {
        "type": "section",
        "fields": [
          {
            "type": "mrkdwn",
            "text": f"*⚡ 작업:*\n{action}"
          },
          {
            "type": "mrkdwn",
            "text": f"*⚠️ 영향도:*\n{impact}"
          }
        ]
      },
      {
        "type": "divider"
      },
      {
        "type": "actions",
        "elements": [
          {
            "type": "button",
            "text": {
              "type": "plain_text",
              "text": "✅ 승인",
              "emoji": True
            },
            "style": "primary",
            "value": f"{resource_type}|{resource_name}|{namespace}|{action}",
            "confirm": {
              "title": {
                "type": "plain_text",
                "text": "승인 확인"
              },
              "text": {
                "type": "plain_text",
                "text": "이 작업을 승인하시겠습니까?"
              },
              "confirm": {
                "type": "plain_text",
                "text": "승인"
              },
              "deny": {
                "type": "plain_text",
                "text": "취소"
              }
            }
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
  message = {
    "blocks": [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": f"✅ *작업 완료 알림*\n\n🔸 *작업:* {action}\n🔸 *승인자:* {admin}\n🔸 *완료 시간:* {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        }
      }
    ]
  }
  requests.post(SLACK_WEBHOOK_URL, json=message)