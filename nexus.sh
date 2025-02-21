#!/bin/bash
set -e

# 터미널 출력 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Nexus 노드 설치를 시작합니다...${NC}"

# 기존 protobuf 제거
echo -e "${GREEN}기존 protobuf 제거 중...${NC}"
sudo apt remove -y protobuf-compiler
sudo apt autoremove -y

# 필수패키지 다운로드
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential pkg-config libssl-dev unzip
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

rustc --version
cargo --version
rustup update

# Protobuf 다운
wget https://github.com/protocolbuffers/protobuf/releases/download/v21.12/protoc-21.12-linux-x86_64.zip
unzip protoc-21.12-linux-x86_64.zip -d $HOME/.local
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

cargo install protobuf-codegen
rustup target add riscv32i-unknown-none-elf
rustup component add rust-src

#Nexus 설치

mkdir -p $HOME/.nexus
cd $HOME/.nexus
git clone https://github.com/nexus-xyz/network-api
curl https://cli.nexus.xyz/ | sh

# 완료 메시지
echo -e "${GREEN}Nexus 노드 설치 과정이 완료되었습니다.${NC}"
echo -e "${YELLOW}대시보드 사이트는 다음과 같습니다: https://app.nexus.xyz/${NC}"
echo -e "${GREEN}스크립트작성자: https://t.me/kjkresearch${NC}"
