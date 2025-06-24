#!/bin/bash

# 컬러 정의
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Nexus 노드 설치를 시작합니다...${NC}"

# 1. GLIBC 2.39 설치
sudo apt update
sudo apt install -y build-essential manpages-dev
sudo rm -rf /opt/glibc-2.39
rm -rf glibc-2.39 glibc-2.39.tar.gz
wget http://ftp.gnu.org/gnu/libc/glibc-2.39.tar.gz
tar -xzf glibc-2.39.tar.gz
cd glibc-2.39
mkdir build && cd build
../configure --prefix=/opt/glibc-2.39
make -j$(nproc)
sudo make install

# 2. 기존 Nexus 설치 폴더 제거 및 재설치 준비
rm -rf $HOME/.nexus
mkdir -p $HOME/.nexus
cd $HOME/.nexus
wget -O https://raw.githubusercontent.com/kooroot/Node_Executor-Nexus/refs/heads/main/nexus_s3.sh
chmod +x nexus_s3.sh

# 3. nexus_s3.sh 수정
sed -i 's|LD_LIBRARY_PATH=/opt/glibc-2.39/lib ./nexus-network|/opt/glibc-2.39/lib/ld-2.39.so --library-path /opt/glibc-2.39/lib ./nexus-network|' nexus_s3.sh

echo -e "${GREEN}Nexus 노드 설치 스크립트 다운로드 및 수정 완료${NC}"

# 4. Nexus 노드 실행
echo -e "${YELLOW}Nexus 노드 구동 중...${NC}"
./nexus_s3.sh
