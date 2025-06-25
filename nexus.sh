#!/bin/bashAdd commentMore actions

# 컬러 정의
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${Yellow}Nexus 노드를 설치합니다.${NC}"
echo -e "${RED}스크립트 실행 전에 screen을 필수로 실행하셔야합니다.${NC}"
read -p "계속 진행하시려면 Enter를 누르세요..."

# 1. 필수 패키지 설치
echo -e "${YELLOW}필수 패키지를 설치합니다...${NC}"
sudo apt update & sudo apt upgrade -y
sudo apt install screen curl build-essential pkg-config libssl-dev git-all -y
sudo apt install protobuf-compiler -y
sudo apt install -y gawk bison gcc make wget tar
sudo apt update

# 2. GLIBC 2.39 설치
echo -e "${YELLOW}GLIBC 2.39를 설치합니다...${NC}"
wget -c https://ftp.gnu.org/gnu/glibc/glibc-2.39.tar.gz
tar -zxvf glibc-2.39.tar.gz
mkdir glibc-build
cd glibc-build
../configure --prefix=/opt/glibc-2.39
make -j$(nproc)
sudo make install

# 3. 사용자로부터 Node ID를 입력받습니다.
read -p "NODE ID를 입력하세요: " NODE_ID

if [[ -z "$NODE_ID" ]]; then
    echo -e "${RED}오류: NODE ID는 비워둘 수 없습니다. 스크립트를 다시 실행하여 올바르게 입력해주세요.${NC}"
    exit 1
fi

# 4. Rust 설치
echo -e "${YELLOW}Rust를 설치합니다...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup target add riscv32i-unknown-none-elf

# 5. Nexus 설치
curl https://cli.nexus.xyz/ | sh
source ~/.bashrc
/opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu /root/.nexus/bin/nexus-network start --node-id $NODE_ID

# 6. 완료 메시지
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Nexus 노드 설정이 완료되었습니다.${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "${YELLOW}아래 명령어로 노드 로그를 확인할 수 있습니다:${NC}"
echo -e "screen -r nexus_node"
echo -e "${YELLOW}screen 세션에서 빠져나오려면 Ctrl+A를 누른 뒤 D를 누르세요.${NC}
