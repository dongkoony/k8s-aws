# mcp/main.py (또는 별도 Flask/FastAPI 서버)

from workflows.slack_approval import send_approval_request, send_action_log, send_result_notification

# 예시: 민감 작업 요청 처리
def handle_sensitive_action(user, action):
    impact = "이 작업은 모든 EC2 인스턴스가 중지되어 서비스가 중단될 수 있습니다."
    send_action_log(user, action, "대기(영향도 안내)")
    # 영향도 안내 후 사용자 확인 → 확인되면
    send_approval_request(user, action, impact)
    send_action_log(user, action, "대기(관리자 승인)")

# 예시: 승인 후 실제 작업 실행
def on_admin_approve(user, action, admin):
    # 실제 작업 실행 코드
    send_action_log(user, action, f"실행됨(관리자:{admin})")
    send_result_notification(action, admin)