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

# 6. 상세설치

# 실제 설치 경로 찾기
NEXUS_PATH=""
if [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
    NEXUS_PATH="$HOME/.nexus/bin"
elif [[ -f "$HOME/.nexus/nexus-network" ]]; then
    NEXUS_PATH="$HOME/.nexus"
elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
    NEXUS_PATH="/root/.nexus/bin"
fi

# PATH 설정
if [[ -n "$NEXUS_PATH" ]]; then
    export PATH="$NEXUS_PATH:$PATH"
    echo "export PATH=\"$NEXUS_PATH:\$PATH\"" >> ~/.bashrc
    source ~/.bashrc
fi

# 설치 확인
if [[ -n "$NEXUS_PATH" ]] && [[ -f "$NEXUS_PATH/nexus-network" ]]; then
    echo -e "${GREEN}Nexus CLI 설치가 성공적으로 완료되었습니다!${NC}"
    echo -e "${GREEN}Nexus 설치 경로: $NEXUS_PATH${NC}"
    echo "$NEXUS_PATH" > /tmp/nexus_install_path.tmp
else
    echo -e "${RED}오류: Nexus CLI 설치가 실패했을 수 있습니다!${NC}"
    exit 1
fi

# 설치 옵션 선택
echo -e "${BLUE}설치 옵션을 선택하세요:${NC}"
echo -e "${YELLOW}1) 기존 NodeID 사용${NC}"
echo -e "${YELLOW}2) 지갑 주소 사용 (새 노드)${NC}"

read -p "선택하세요 (1 또는 2): " choice

case $choice in
    1)
        read -p "NodeID를 입력하세요: " node_id
        if [[ -z "$node_id" ]]; then
            echo -e "${RED}오류: NodeID는 비워둘 수 없습니다!${NC}"
            exit 1
        fi
        
        # NodeID로 실행
        nexus_path=$(cat /tmp/nexus_install_path.tmp 2>/dev/null || echo "$HOME/.nexus/bin")
        echo -e "${BLUE}NodeID로 Nexus Network를 시작합니다: $node_id${NC}"
        echo -e "${YELLOW}Nexus 경로: $nexus_path${NC}"

        if [[ -f "$nexus_path/nexus-network" ]]; then
        /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "$nexus_path/nexus-network" start --node-id $node_id
        else
            echo -e "${RED}오류: $nexus_path에서 nexus-network를 찾을 수 없습니다${NC}"
            echo -e "${YELLOW}대체 경로를 시도합니다...${NC}"
            if [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "$HOME/.nexus/bin/nexus-network" start --node-id $node_id
            elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "/root/.nexus/bin/nexus-network" start --node-id $node_id
            else
                echo -e "${RED}오류: nexus-network 실행 파일을 찾을 수 없습니다!${NC}"
            fi
        fi
        ;;
        
    2)
        # 지갑 주소로 실행
        nexus_path=$(cat /tmp/nexus_install_path.tmp 2>/dev/null || echo "$HOME/.nexus/bin")
        echo -e "${BLUE}지갑 주소로 Nexus Network를 등록합니다: $wallet_address${NC}"
        echo -e "${YELLOW}Nexus 경로: $nexus_path${NC}"

        echo -e "${YELLOW}1단계: 사용자 등록 중...${NC}"
        if [[ -f "$nexus_path/nexus-network" ]]; then
            /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "$nexus_path/nexus-network" register-user --wallet-address $wallet_address
        elif [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
            /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "$HOME/.nexus/bin/nexus-network" register-user --wallet-address $wallet_address
        elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
            /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "/root/.nexus/bin/nexus-network" register-user --wallet-address $wallet_address
        else
            echo -e "${RED}오류: nexus-network 실행 파일을 찾을 수 없습니다!${NC}"
            exit 1
        fi

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}사용자 등록 성공!${NC}"
            
            echo -e "${YELLOW}2단계: 노드 등록 중...${NC}"
            if [[ -f "$nexus_path/nexus-network" ]]; then
                /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "$nexus_path/nexus-network" register-node
            elif [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "$HOME/.nexus/bin/nexus-network" register-node
            elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "/root/.nexus/bin/nexus-network" register-node
            fi
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}노드 등록 성공!${NC}"
                
                echo -e "${YELLOW}3단계: 노드 시작 중...${NC}"
                if [[ -f "$nexus_path/nexus-network" ]]; then
                    /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "$nexus_path/nexus-network" start
                elif [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                    /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "$HOME/.nexus/bin/nexus-network" start
                elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                    /opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu "/root/.nexus/bin/nexus-network" start
                fi
            else
                echo -e "${RED}오류: 노드 등록에 실패했습니다!${NC}"
            fi
        else
            echo -e "${RED}오류: 사용자 등록에 실패했습니다!${NC}"
        fi
        ;;
        
    *)
        echo -e "${RED}오류: 잘못된 선택입니다! 1 또는 2를 선택하세요.${NC}"
        exit 1
        ;;
esac

# 7. 완료 메시지
echo -e "${GREEN}설치가 성공적으로 완료되었습니다!${NC}"
echo -e "${GREEN}screen 세션 목록: screen -ls${NC}"
echo -e "${YELLOW}screen 세션에서 빠져나오려면 Ctrl+A를 누른 뒤 D를 누르세요.${NC}
