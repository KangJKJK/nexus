#!/bin/bash

# 컬러 정의
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Nexus 노드 설치를 시작합니다...${NC}"

# 1. GLIBC 2.39 설치
if [ ! -d /opt/glibc-2.39 ]; then
  echo -e "${YELLOW}GLIBC 2.39 설치 중... (시간 다소 소요)${NC}"
  wget http://ftp.gnu.org/gnu/libc/glibc-2.39.tar.gz
  tar -xzf glibc-2.39.tar.gz
  cd glibc-2.39
  mkdir build && cd build
  ../configure --prefix=/opt/glibc-2.39
  make -j$(nproc)
  sudo make install
  cd ../../
  rm -rf glibc-2.39 glibc-2.39.tar.gz
else
  echo -e "${GREEN}GLIBC 2.39가 이미 설치되어 있습니다.${NC}"
fi

# 2. 기존 Nexus 설치 폴더 제거 및 재설치 준비
rm -rf $HOME/.nexus
mkdir -p $HOME/.nexus
cd $HOME/.nexus

# 3. nexus_s3.sh 다운로드 및 권한 부여
wget https://raw.githubusercontent.com/kooroot/Node_Executor-Nexus/refs/heads/main/nexus_s3.sh
chmod +x nexus_s3.sh

echo -e "${GREEN}Nexus 노드 설치 스크립트 다운로드 완료${NC}"

# 4. Nexus 노드 실행 (GLIBC 라이브러리 경로 지정)
echo -e "${YELLOW}Nexus 노드 구동 중...${NC}"
LD_LIBRARY_PATH=/opt/glibc-2.39/lib ./nexus_s3.sh

# 완료 메시지
echo -e "${GREEN}Nexus 노드 설치 과정이 완료되었습니다.${NC}"
echo -e "${YELLOW}대시보드 사이트는 다음과 같습니다: https://app.nexus.xyz/${NC}"
echo -e "${GREEN}스크립트작성자: https://t.me/kjkresearch${NC}"
