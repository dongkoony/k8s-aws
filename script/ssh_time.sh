#!/bin/bash

# 로그 파일 위치 설정
LOG_FILE="/home/ubuntu/docker_install.log"

# 로그 파일 초기화
> $LOG_FILE

# 시스템 시간대를 서울로 설정
echo "시간대를 Asia/Seoul로 설정 중" >> $LOG_FILE 2>&1
sudo timedatectl set-timezone Asia/Seoul >> $LOG_FILE 2>&1

# 시간대 설정 확인
echo "서울(한국) 시간대 설정 완료" >> $LOG_FILE 2>&1
timedatectl >> $LOG_FILE 2>&1

# SSH 포트 변경
echo "SSH 포트를 1717로 변경 중" >> $LOG_FILE 2>&1
sudo sed -i 's/#Port 22/Port 1717/g' /etc/ssh/sshd_config >> $LOG_FILE 2>&1

# SSH 서비스 재시작
echo "SSH 서비스를 재시작 중" >> $LOG_FILE 2>&1
sudo systemctl restart sshd >> $LOG_FILE 2>&1