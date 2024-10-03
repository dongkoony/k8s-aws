#!/bin/bash

# 로그 파일 위치 설정
LOG_FILE="/home/ubuntu/combined_settings.log"

# 로그 파일 초기화
> $LOG_FILE

######################################################################
# ---------------- ssh port / timectl settings 내용 ------------------
######################################################################

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



#############################################################
# ---------------- Kubernetes_install 내용 ------------------
#############################################################

# Docker 설치
echo "Docker 설치 중" >> $LOG_FILE 2>&1
sudo apt-get update -y >> $LOG_FILE 2>&1
sudo apt-get install -y docker.io >> $LOG_FILE 2>&1

# Docker 시작 및 부팅 시 자동 시작 설정
echo "Docker 서비스 시작 및 부팅 시 자동 시작 설정 중" >> $LOG_FILE 2>&1
sudo systemctl enable docker >> $LOG_FILE 2>&1
sudo systemctl start docker >> $LOG_FILE 2>&1

# Kubernetes 패키지 저장소 추가
echo "Kubernetes 패키지 저장소 추가 중" >> $LOG_FILE 2>&1
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - >> $LOG_FILE 2>&1
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list >> $LOG_FILE 2>&1
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# 패키지 목록 업데이트
echo "패키지 목록 업데이트 중" >> $LOG_FILE 2>&1
sudo apt-get update -y >> $LOG_FILE 2>&1

# Kubernetes 설치
echo "Kubernetes 1.27 설치 중" >> $LOG_FILE 2>&1
sudo apt-get install -y kubelet=1.27.0-00 kubeadm=1.27.0-00 kubectl=1.27.0-00 >> $LOG_FILE 2>&1

# kubelet 자동 시작 설정
echo "kubelet 자동 시작 설정 중" >> $LOG_FILE 2>&1
sudo systemctl enable kubelet >> $LOG_FILE 2>&1

# Swap 비활성화
echo "Swap 비활성화 중" >> $LOG_FILE 2>&1
sudo swapoff -a >> $LOG_FILE 2>&1
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab >> $LOG_FILE 2>&1

# Kubernetes 클러스터 초기화
echo "Kubernetes 클러스터 초기화 중" >> $LOG_FILE 2>&1
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.27.0 >> $LOG_FILE 2>&1

# kubectl 설정
echo "kubectl 설정 중" >> $LOG_FILE 2>&1
mkdir -p $HOME/.kube >> $LOG_FILE 2>&1
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config >> $LOG_FILE 2>&1
sudo chown $(id -u):$(id -g) $HOME/.kube/config >> $LOG_FILE 2>&1

# Flannel 네트워크 플러그인 설치
echo "Flannel 네트워크 플러그인 설치 중" >> $LOG_FILE 2>&1
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml >> $LOG_FILE 2>&1

# 마스터 노드에서 스케줄링 활성화
echo "마스터 노드에서 스케줄링 활성화 중" >> $LOG_FILE 2>&1
kubectl taint nodes --all node-role.kubernetes.io/control-plane- >> $LOG_FILE 2>&1

echo "Kubernetes 1.27 설치 및 설정 완료!" >> $LOG_FILE 2>&1
