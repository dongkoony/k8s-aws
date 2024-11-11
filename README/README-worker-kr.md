## 워커 노드 설정 스크립트 (Worker Node Setup Script) worker_setup.sh
[![EN](https://img.shields.io/badge/lang-en-blue.svg)](README-worker-en.md) 
[![KR](https://img.shields.io/badge/lang-kr-red.svg)](README-worker-kr.md)

이 스크립트(worker_setup.sh)는 쿠버네티스 워커 노드를 자동으로 설정하고 클러스터에 연결하는 프로세스를 관리합니다.

## 스크립트 구조 설명

### 1. 기본 변수 설정
```bash
MASTER_IP="$1"                                # 마스터 노드 IP 주소
NODE_INDEX="$2"                               # 워커 노드 번호
SSH_KEY_PATH="/home/ubuntu/.ssh/example.pem"  # SSH 키 경로
```
- 변수 수정 예시:
  ```bash
  SSH_KEY_PATH="/your/key/path/your-key.pem"
  ```

### 2. SSH 및 보안 설정
```bash
sudo chmod 400 ${SSH_KEY_PATH}
chmod +x /home/ubuntu/combined_settings.sh
touch /home/ubuntu/.ssh/known_hosts
echo 'StrictHostKeyChecking no' > /home/ubuntu/.ssh/config
chmod 600 /home/ubuntu/.ssh/config
```
- SSH 키 권한 및 보안 설정을 자동으로 구성합니다
- 필요한 경우 권한을 수동으로 변경할 수 있습니다:
  ```bash
  chmod 600 /home/ubuntu/.ssh/config  # 보안 설정
  ```

### 3. 클러스터 조인 프로세스
```bash
until ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${MASTER_IP} 'test -f /home/ubuntu/join_command'; do 
    sleep 10
done

JOIN_CMD=$(ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${MASTER_IP} 'cat /home/ubuntu/join_command')
sudo $JOIN_CMD
```
- 마스터 노드의 조인 명령어를 자동으로 가져와 실행합니다
- 수동 조인이 필요한 경우:
  ```bash
  # 마스터 노드에서
  kubeadm token create --print-join-command > join_command
  # 워커 노드에서
  sudo $(cat join_command)
  ```

### 4. 노드 레이블 설정
```bash
NODE_IP=$(hostname -I | awk '{print $1}')
FORMATTED_IP=$(echo $NODE_IP | tr '.' '-')
ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${MASTER_IP} "kubectl label node ip-${FORMATTED_IP} node-role.kubernetes.io/worker-node${NODE_INDEX}=''"
```
- 노드 레이블 수동 설정 예시:
  ```bash
  kubectl label node ip-10-0-2-15 node-role.kubernetes.io/worker-node1=''
  ```

## 사용 방법 (수동 실행 시)

1. **스크립트 준비**
   ```bash
   # 스크립트에 실행 권한 부여
   chmod +x worker_setup.sh
   ```

2. **스크립트 실행**
   ```bash
   ./worker_setup.sh <마스터_IP> <노드_번호>
   # 예시
   ./worker_setup.sh 10.0.x.xxx 1
   ```

3. **설정 확인**
   ```bash
   # 마스터 노드에서 노드 상태 확인
   kubectl get nodes
   
   # 예상 출력
   NAME           STATUS   ROLES          AGE   VERSION
   ip-10-0-x-xxx Ready    control-plane  10m   v1.31.0
   ip-10-0-x-xx  Ready    worker-node1   5m    v1.31.0
   ```

## 주의사항
- SSH 키 경로가 올바르게 설정되어 있어야 합니다
- 마스터 노드가 실행 중이어야 합니다
- 적절한 네트워크 연결이 필요합니다
- 충분한 시스템 리소스가 있어야 합니다

## 문제 해결
- SSH 연결 오류: SSH 키 권한 확인
- 조인 실패: 마스터 노드 상태 확인
- 레이블 설정 실패: kubeconfig 설정 확인

이 스크립트는 Terraform을 통해 자동으로 실행되므로, 일반적으로 수동 개입이 필요하지 않습니다. 하지만 문제 해결이나 커스터마이징이 필요한 경우 위 가이드를 참고하시면 됩니다.