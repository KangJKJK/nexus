#!/bin/bash

# 터미널 출력 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Nexus 노드 설치를 시작합니다...${NC}"

# 1. 기존 파일 정리
sudo rm -f /usr/local/bin/protoc
rm -f protoc-25.1-linux-x86_64.zip*

# 2. 다시 다운로드
wget https://github.com/protocolbuffers/protobuf/releases/download/v25.1/protoc-25.1-linux-x86_64.zip

# 3. unzip 설치 (혹시 없다면)
sudo apt install -y unzip

# 4. 압축 해제 및 설치
sudo unzip protoc-25.1-linux-x86_64.zip -d /usr/local

# 5. 권한 설정
sudo chmod +x /usr/local/bin/protoc

# 6. 버전 확인
protoc --version

# 7. 환경변수 설정
export PROTOC=/usr/local/bin/protoc
export PROTOC_FLAGS="--experimental_allow_proto3_optional"
source ~/.bashrc

#Nexus 설치

mkdir -p $HOME/.nexus
cd $HOME/.nexus
git clone https://github.com/nexus-xyz/network-api
curl https://cli.nexus.xyz/ | sh

# 완료 메시지
echo -e "${GREEN}Nexus 노드 설치 과정이 완료되었습니다.${NC}"
echo -e "${YELLOW}대시보드 사이트는 다음과 같습니다: https://app.nexus.xyz/${NC}"
echo -e "${GREEN}스크립트작성자: https://t.me/kjkresearch${NC}"
