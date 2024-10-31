#!/bin/bash

#################################################################
# ---------------- 환경 변수 설정 섹션 ------------------
#################################################################

# 로그 설정
readonly LOG_FILE="/home/ubuntu/combined_settings.log"
readonly LOG_PREFIX="[K8S-SETUP]"

# 네트워크 설정
readonly POD_CIDR="10.244.0.0/16"
readonly CNI_VERSION="v3.14"
readonly CNI_MANIFEST="https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml"
readonly CNI_MANIFEST_CUSTOM="https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml"

# 쿠버네티스 설정
readonly K8S_VERSION="1.27.16-1.1"
readonly PACKAGES=(
    "kubelet=${K8S_VERSION}"
    "kubeadm=${K8S_VERSION}"
    "kubectl=${K8S_VERSION}"
)

# 시스템 요구사항
readonly MIN_CPU_CORES=2
readonly MIN_MEMORY_GB=2
readonly REQUIRED_PORTS=(6443 10250 10251 10252)

# 재시도 설정
readonly MAX_RETRIES=3
readonly RETRY_INTERVAL=30
readonly WAIT_INTERVAL=10

#################################################################
# ---------------- 유틸리티 함수 섹션 ------------------
#################################################################

log() {
    local message="$1"
    echo "${LOG_PREFIX} $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

check_error() {
    if [ $? -ne 0 ]; then
        log "오류: $1"
        exit 1
    fi
}

wait_for_service() {
    local service_name="$1"
    local max_attempts=30
    local attempt=1

    while ! systemctl is-active --quiet "${service_name}"; do
        if [ ${attempt} -ge ${max_attempts} ]; then
            log "${service_name} 서비스 시작 실패"
            return 1
        fi
        log "${service_name} 서비스 대기 중... (${attempt}/${max_attempts})"
        sleep ${WAIT_INTERVAL}
        attempt=$((attempt + 1))
    done
    return 0
}

verify_system_requirements() {
    log "시스템 요구사항 검증 시작"

    # CPU 코어 수 확인
    local cpu_cores=$(nproc)
    if [ ${cpu_cores} -lt ${MIN_CPU_CORES} ]; then
        log "CPU 코어 수 부족: ${cpu_cores} (필요: ${MIN_CPU_CORES})"
        return 1
    fi

    # 메모리 확인
    local memory_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [ ${memory_gb} -lt ${MIN_MEMORY_GB} ]; then
        log "메모리 부족: ${memory_gb}GB (필요: ${MIN_MEMORY_GB}GB)"
        return 1
    fi

    # 포트 확인
    for port in "${REQUIRED_PORTS[@]}"; do
        if netstat -tuln | grep ":${port} " > /dev/null; then
            log "포트 ${port}가 이미 사용 중"
            return 1
        fi
    done

    log "시스템 요구사항 검증 완료"
    return 0
}



#################################################################
# ---------------- 네트워크 설정 섹션 ------------------
#################################################################

setup_network() {
    log "네트워크 설정 시작"

    # 커널 모듈 설정
    local modules=(overlay br_netfilter)
    for module in "${modules[@]}"; do
        modprobe ${module}
        echo ${module} >> /etc/modules-load.d/k8s.conf
    done

    # sysctl 파라미터 설정
    cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    sysctl --system
    check_error "네트워크 설정 실패"

    log "네트워크 설정 완료"
}

#################################################################
# ---------------- Docker 설치 섹션 ------------------
#################################################################

install_docker() {
    log "Docker 설치 시작"
    
    apt-get update -y
    apt-get install -y docker.io
    check_error "Docker 설치 실패"

    systemctl enable --now docker
    check_error "Docker 서비스 활성화 실패"

    # containerd 설치 및 설정
    apt install -y containerd
    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
    systemctl restart containerd
    check_error "containerd 설정 실패"

    log "Docker 설치 완료"
}

#################################################################
# ---------------- 쿠버네티스 설치 섹션 ------------------
#################################################################

install_kubernetes() {
    log "쿠버네티스 설치 시작"

    # 저장소 설정
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

    # 패키지 설치
    apt-get update
    apt-get install -y "${PACKAGES[@]}"
    check_error "쿠버네티스 패키지 설치 실패"

    # 버전 고정
    apt-mark hold kubelet kubeadm kubectl
    check_error "쿠버네티스 버전 고정 실패"

    log "쿠버네티스 설치 완료"
}

#################################################################
# ---------------- 마스터 노드 초기화 섹션 ------------------
#################################################################

initialize_master() {
    log "마스터 노드 초기화 시작"

    local master_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    check_error "마스터 IP 조회 실패"

    local retry_count=0
    while [ ${retry_count} -lt ${MAX_RETRIES} ]; do
        if kubeadm init --apiserver-advertise-address=${master_ip} --pod-network-cidr=${POD_CIDR} > /var/log/kubeadm_init.log 2>&1; then
            log "마스터 노드 초기화 성공"
            break
        fi
        retry_count=$((retry_count + 1))
        log "초기화 실패. ${RETRY_INTERVAL}초 후 재시도... (${retry_count}/${MAX_RETRIES})"
        sleep ${RETRY_INTERVAL}
    done

    if [ ${retry_count} -eq ${MAX_RETRIES} ]; then
        log "마스터 노드 초기화 최대 시도 횟수 초과"
        exit 1
    fi

    # kubeconfig 설정
    mkdir -p /home/ubuntu/.kube
    cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
    chown $(id -u ubuntu):$(id -g ubuntu) /home/ubuntu/.kube/config

    # Calico CNI 설치
    kubectl apply -f ${CNI_MANIFEST}
    kubectl apply -f ${CNI_MANIFEST_CUSTOM}
    check_error "Calico CNI 설치 실패"

    log "마스터 노드 초기화 완료"
}

#################################################################
# ---------------- Join 명령어 생성 섹션 ------------------
#################################################################

generate_join_command() {
    log "Join 명령어 생성 시작"
    
    local join_command=$(kubeadm token create --print-join-command)
    echo "${join_command}" > /home/ubuntu/kubeadm_join_cmd.sh
    check_error "Join 명령어 생성 실패"

    # HTTP 서버 시작
    cd /home/ubuntu
    nohup python3 -m http.server 8080 >> "${LOG_FILE}" 2>&1 &
    sleep 30  # HTTP 서버 시작 대기

    log "Join 명령어 생성 완료"
}

#################################################################
# ---------------- 메인 실행 섹션 ------------------
#################################################################

main() {
    log "설치 스크립트 시작"

    verify_system_requirements
    setup_system
    setup_network
    install_docker
    install_kubernetes

    if [[ "${NODE_ROLE}" == "master" ]]; then
        initialize_master
        generate_join_command
    fi

    log "설치 스크립트 완료"
}

# 스크립트 실행
main