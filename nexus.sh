#!/bin/bash

# 컬러 정의
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Nexus 노드 설치를 시작합니다.${NC}"
echo -e "${RED}경고: 이 스크립트는 시스템의 핵심 라이브러리인 GLIBC를 직접 업그레이드합니다."
echo -e "${RED}이 작업은 시스템에 예기치 않은 문제를 일으킬 수 있습니다.${NC}"
read -p "계속 진행하시려면 Enter를 누르세요..."

# 1. GLIBC 2.39 시스템에 직접 설치
echo -e "${YELLOW}GLIBC 2.39 설치를 시작합니다...${NC}"
sudo apt update
sudo apt install -y build-essential manpages-dev wget

# 이전 GLIBC 빌드 시도에서 남은 파일들을 제거합니다.
rm -rf glibc-2.39 glibc-2.39.tar.gz
wget --no-check-certificate http://ftp.gnu.org/gnu/libc/glibc-2.39.tar.gz
tar -xzf glibc-2.39.tar.gz
cd glibc-2.39
mkdir build && cd build

# --prefix=/usr 를 사용하여 시스템 라이브러리 경로에 직접 설치합니다.
../configure --prefix=/usr
make -j$(nproc)
sudo make install

# 2. Nexus 설치 준비
echo -e "${YELLOW}Nexus 설치를 준비합니다...${NC}"
cd $HOME
rm -rf $HOME/.nexus
mkdir -p $HOME/.nexus
cd $HOME/.nexus
wget -O nexus_s3.sh https://raw.githubusercontent.com/kooroot/Node_Executor-Nexus/refs/heads/main/nexus_s3.sh
chmod +x nexus_s3.sh

echo -e "${GREEN}Nexus 노드 설치 스크립트 다운로드 완료${NC}"

# 3. Nexus 노드 실행
echo -e "${YELLOW}Nexus 노드 구동 중...${NC}"
./nexus_s3.sh 
