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

# 마스터 노드의 프라이빗 IP 가져오기 (AWS 환경에서 자동으로 프라이빗 IP 가져오기)
MASTER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Swap 비활성화
echo "Swap 비활성화 중" >> $LOG_FILE 2>&1
sudo swapoff -a >> $LOG_FILE 2>&1
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab >> $LOG_FILE 2>&1

# 네트워크 모듈 로드
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay >> $LOG_FILE 2>&1
sudo modprobe br_netfilter >> $LOG_FILE 2>&1

# sysctl 파라미터 설정
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# sysctl 파라미터 적용
sudo sysctl --system

# Docker 설치
echo "Docker 설치 중" >> $LOG_FILE 2>&1
sudo apt-get update -y >> $LOG_FILE 2>&1
sudo apt-get install -y docker.io >> $LOG_FILE 2>&1

# Docker 시작 및 부팅 시 자동 시작 설정
echo "Docker 서비스 시작 및 부팅 시 자동 시작 설정 중" >> $LOG_FILE 2>&1
sudo systemctl enable --now docker >> $LOG_FILE 2>&1

# containerd 설치
sudo apt install -y containerd

# containerd 설정 파일 생성 및 수정
sudo mkdir -p /etc/containerd $LOG_FILE 2>&1
sudo containerd config default | sudo tee /etc/containerd/config.toml $LOG_FILE 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml >> $LOG_FILE 2>&1

# containerd 서비스 재시작 & 활성화
sudo systemctl restart containerd.service $LOG_FILE 2>&1
sudo syetemctl enable --now containerd.service $LOG_FILE 2>&1

# Kubernetes 패키지 저장소 추가
echo "Kubernetes 패키지 저장소 추가 중" >> $LOG_FILE 2>&1
sudo apt-get install -y apt-transport-https ca-certificates curl >> $LOG_FILE 2>&1

# 공식 문서에서 권장하는 방식으로 Kubernetes 키 및 저장소 추가
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg >> $LOG_FILE 2>&1

# Ubuntu 22.04 패키지 저장소 추가
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list >> $LOG_FILE 2>&1

# 패키지 목록 업데이트
echo "패키지 목록 업데이트 중" >> $LOG_FILE 2>&1
sudo apt-get update -y >> $LOG_FILE 2>&1

# 설치 가능한 버전 확인
sudo apt-cache madison kubeadm

# Kubernetes 설치
echo "Kubernetes 1.27 설치 중" >> $LOG_FILE 2>&1
sudo apt-get install -y kubelet=1.27.16-1.1 kubeadm=1.27.16-1.1 kubectl=1.27.16-1.1 >> $LOG_FILE 2>&1

# Kubernetes 버전 고정
sudo apt-mark hold kubelet kubeadm kubectl >> $LOG_FILE 2>&1

# kubelet 자동 시작 설정
echo "kubelet 자동 시작 설정 중" >> $LOG_FILE 2>&1
sudo systemctl enable --now kubelet >> $LOG_FILE 2>&1

# Kubernetes 클러스터 초기화
echo "Kubernetes 클러스터 초기화 중" >> $LOG_FILE 2>&1
sudo kubeadm init --apiserver-advertise-address=${MASTER_IP} --pod-network-cidr=10.244.0.0/16 --apiserver-cert-extra-sans=${MASTER_IP} >> $LOG_FILE 2>&1 || {
  echo "Kubeadm 초기화 실패, 다시 시도 중..." >> $LOG_FILE 2>&1
  sleep 5
  sudo kubeadm init --apiserver-advertise-address=${MASTER_IP} --pod-network-cidr=10.244.0.0/16 --apiserver-cert-extra-sans=${MASTER_IP} >> $LOG_FILE 2>&1
}

# kubeconfig 설정
echo "kubectl 설정 중" >> $LOG_FILE 2>&1
mkdir -p $HOME/.kube >> $LOG_FILE 2>&1
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config >> $LOG_FILE 2>&1
sudo chown $(id -u):$(id -g) $HOME/.kube/config >> $LOG_FILE 2>&1

# 환경 변수 설정 (kubectl 사용 가능하도록)
export KUBECONFIG=/etc/kubernetes/admin.conf

# Calico Network Plugin 설치
kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml >> $LOG_FILE 2>&1

# 마스터 노드에서 스케줄링 활성화
echo "마스터 노드에서 스케줄링 활성화 중" >> $LOG_FILE 2>&1
kubectl taint nodes --all node-role.kubernetes.io/control-plane- >> $LOG_FILE 2>&1 || {
  echo "노드 스케줄링 활성화 실패, 다시 시도 중..." >> $LOG_FILE 2>&1
  sleep 5
  kubectl taint nodes --all node-role.kubernetes.io/control-plane- >> $LOG_FILE 2>&1
}

echo "Kubernetes 1.27 설치 및 설정 완료!" >> $LOG_FILE 2>&1
