#!/bin/bash

# 로그 파일 위치 설정
LOG_FILE="/home/ubuntu/combined_settings.log"

# 로그 파일 초기화
> $LOG_FILE

######################################################################
# ---------------- ssh port / timectl settings 내용 ------------------
######################################################################

# 시스템 시간대를 서울로 설정
echo "시간대를 Asia/Seoul로 설정 중" | tee -a $LOG_FILE
if sudo timedatectl set-timezone Asia/Seoul >> $LOG_FILE 2>&1; then
    echo "서울(한국) 시간대 설정 완료" | tee -a $LOG_FILE
else
    echo "시간대 설정 실패" | tee -a $LOG_FILE
    exit 1
fi

# SSH 포트 변경
echo "SSH 포트를 1717로 변경 중" | tee -a $LOG_FILE
if sudo sed -i 's/#Port 22/Port 1717/g' /etc/ssh/sshd_config >> $LOG_FILE 2>&1; then
    if sudo systemctl restart sshd >> $LOG_FILE 2>&1; then
        echo "SSH 서비스 재시작 완료" | tee -a $LOG_FILE
    else
        echo "SSH 서비스 재시작 실패" | tee -a $LOG_FILE
        exit 1
    fi
else
    echo "SSH 포트 변경 실패" | tee -a $LOG_FILE
    exit 1
fi

#############################################################
# ---------------- Kubernetes_install 내용 ------------------
#############################################################

# 마스터 노드의 프라이빗 IP 가져오기
MASTER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
if [ -z "$MASTER_IP" ]; then
    echo "마스터 노드 IP 가져오기 실패" | tee -a $LOG_FILE
    exit 1
fi

# EC2 태그에서 Role 값을 가져와서 마스터/워커 노드 구분
NODE_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Role)

# Swap 비활성화
echo "Swap 비활성화 중" | tee -a $LOG_FILE
if sudo swapoff -a >> $LOG_FILE 2>&1 && sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab >> $LOG_FILE 2>&1; then
    echo "Swap 비활성화 완료" | tee -a $LOG_FILE
else
    echo "Swap 비활성화 실패" | tee -a $LOG_FILE
    exit 1
fi

# 네트워크 모듈 로드
echo "네트워크 모듈 로드 중" | tee -a $LOG_FILE
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay >> $LOG_FILE 2>&1 || { echo "overlay 모듈 로드 실패" | tee -a $LOG_FILE; exit 1; }
sudo modprobe br_netfilter >> $LOG_FILE 2>&1 || { echo "br_netfilter 모듈 로드 실패" | tee -a $LOG_FILE; exit 1; }

# sysctl 파라미터 설정
echo "sysctl 파라미터 설정 중" | tee -a $LOG_FILE
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

if sudo sysctl --system >> $LOG_FILE 2>&1; then
    echo "sysctl 파라미터 설정 완료" | tee -a $LOG_FILE
else
    echo "sysctl 파라미터 설정 실패" | tee -a $LOG_FILE
    exit 1
fi

# Docker 설치
echo "Docker 설치 중" | tee -a $LOG_FILE
if sudo apt-get update -y >> $LOG_FILE 2>&1 && sudo apt-get install -y docker.io >> $LOG_FILE 2>&1; then
    echo "Docker 설치 완료" | tee -a $LOG_FILE
else
    echo "Docker 설치 실패" | tee -a $LOG_FILE
    exit 1
fi

# Docker 시작 및 부팅 시 자동 시작 설정
echo "Docker 서비스 시작 중" | tee -a $LOG_FILE
if sudo systemctl enable --now docker >> $LOG_FILE 2>&1; then
    echo "Docker 서비스 설정 완료" | tee -a $LOG_FILE
else
    echo "Docker 서비스 시작 실패" | tee -a $LOG_FILE
    exit 1
fi

# containerd 설치
echo "containerd 설치 중" | tee -a $LOG_FILE
if sudo apt install -y containerd >> $LOG_FILE 2>&1; then
    echo "containerd 설치 완료" | tee -a $LOG_FILE
else
    echo "containerd 설치 실패" | tee -a $LOG_FILE
    exit 1
fi

# containerd 기본 설정 파일 생성 및 SystemdCgroup 설정
echo "containerd 설정 중" | tee -a $LOG_FILE
sudo mkdir -p /etc/containerd
if sudo containerd config default | sudo tee /etc/containerd/config.toml >> $LOG_FILE 2>&1; then
    if sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml >> $LOG_FILE 2>&1 && sudo systemctl restart containerd >> $LOG_FILE 2>&1; then
        echo "containerd 설정 및 재시작 완료" | tee -a $LOG_FILE
    else
        echo "containerd 설정 변경 실패" | tee -a $LOG_FILE
        exit 1
    fi
else
    echo "containerd 설정 파일 생성 실패" | tee -a $LOG_FILE
    exit 1
fi

# Kubernetes 설치
echo "Kubernetes 1.27 패키지 설치 중" | tee -a $LOG_FILE
if sudo apt-get install -y apt-transport-https ca-certificates curl >> $LOG_FILE 2>&1 &&
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg &&
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list >> $LOG_FILE 2>&1 &&
    sudo apt-get update -y >> $LOG_FILE 2>&1 &&
    sudo apt-get install -y kubelet=1.27.16-1.1 kubeadm=1.27.16-1.1 kubectl=1.27.16-1.1 >> $LOG_FILE 2>&1; then
    echo "Kubernetes 설치 완료" | tee -a $LOG_FILE
else
    echo "Kubernetes 설치 실패" | tee -a $LOG_FILE
    exit 1
fi

# Kubernetes 버전 고정
sudo apt-mark hold kubelet kubeadm kubectl >> $LOG_FILE 2>&1 || { echo "Kubernetes 버전 고정 실패" | tee -a $LOG_FILE; exit 1; }

# 마스터 노드 초기화 및 Join 명령어 제공
if [[ "$NODE_ROLE" == "master" ]]; then
    echo "Kubernetes 클러스터 초기화 중 (마스터)" | tee -a $LOG_FILE
    sudo kubeadm init --apiserver-advertise-address=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --pod-network-cidr=10.244.0.0/16 | tee -a $LOG_FILE
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "Kubernetes 클러스터 초기화 완료" | tee -a $LOG_FILE
    else
        echo "Kubernetes 클러스터 초기화 실패" | tee -a $LOG_FILE
        exit 1
    fi

    # kubeconfig 설정
    echo "kubectl 설정 중" | tee -a $LOG_FILE
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    if [ $? -ne 0 ]; then
        echo "kubectl 설정 실패" | tee -a $LOG_FILE
        exit 1
    fi

    # Join 명령어 저장
    echo "Join 명령어 생성 중..." | tee -a $LOG_FILE
    JOIN_CMD=$(sudo kubeadm token create --print-join-command)

    if [ $? -eq 0 ]; then
        echo "$JOIN_CMD" > /home/ubuntu/kubeadm_join_cmd.sh
        echo "Join 명령어가 /home/ubuntu/kubeadm_join_cmd.sh 파일에 저장되었습니다." | tee -a $LOG_FILE
    else
        echo "Join 명령어 생성 실패" | tee -a $LOG_FILE
        cat $LOG_FILE
        exit 1
    fi

    # HTTP 서버로 Join 명령어 제공 (포트 8080)
    HTTP_INTERVAL=30

    echo "HTTP 서버를 통해 Join 명령어 제공 중" | tee -a $LOG_FILE
    cd /home/ubuntu
    nohup python3 -m http.server 8080 &
    sleep $HTTP_INTERVAL  # 서버가 완전히 실행될 때까지 대기

    # Calico 네트워크 플러그인 설치
    echo "Calico 네트워크 플러그인 설치 중" | tee -a $LOG_FILE
    if kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml >> $LOG_FILE 2>&1; then
        echo "Calico 네트워크 플러그인 설치 완료!" | tee -a $LOG_FILE
    else
        echo "Calico 설치 실패" | tee -a $LOG_FILE
        exit 1
    fi

else
    # 워커 노드 Join
    echo "Kubernetes 워커 노드로 Join 중" | tee -a $LOG_FILE
    MAX_RETRIES=5
    RETRY_INTERVAL=10
    
    for i in $(seq 1 $MAX_RETRIES); do
        if curl -o /home/ubuntu/kubeadm_join_cmd.sh http://$MASTER_IP:8080/kubeadm_join_cmd.sh; then
            echo "Join 명령어 파일 다운로드 성공" | tee -a $LOG_FILE
            break
        fi
        echo "Join 명령어 파일 다운로드 실패. 재시도 중... ($i/$MAX_RETRIES)" | tee -a $LOG_FILE
        sleep $RETRY_INTERVAL
    done

    if [ -f "/home/ubuntu/kubeadm_join_cmd.sh" ]; then
        sudo bash /home/ubuntu/kubeadm_join_cmd.sh | tee -a $LOG_FILE
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo "워커 노드 Join 성공" | tee -a $LOG_FILE
        else
            echo "워커 노드 Join 실패" | tee -a $LOG_FILE
            exit 1
        fi
    else
        echo "kubeadm Join 명령어 파일이 없습니다." | tee -a $LOG_FILE
        exit 1
    fi
fi

echo "Kubernetes 설치 및 설정 완료!" | tee -a $LOG_FILE
