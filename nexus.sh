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
#!/bin/bash
set -e

# 컬러 정의
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 메시지 출력 함수
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# OS 감지
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            echo "ubuntu"
        else
            echo "unsupported"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unsupported"
    fi
}

# 메인 스크립트 시작
print_message "$BLUE" "========================================="
print_message "$BLUE" "  Nexus Node Auto-Installation Script"
print_message "$BLUE" "========================================="

# OS 감지
OS=$(detect_os)

if [[ $OS == "unsupported" ]]; then
    print_message "$RED" "오류: 지원하지 않는 운영체제입니다!"
    print_message "$RED" "이 스크립트는 Ubuntu (apt)와 MacOS (brew)만 지원합니다."
    exit 1
fi

print_message "$GREEN" "감지된 OS: $OS"

# 시스템 업데이트
print_message "$BLUE" "========================================="
print_message "$BLUE" "시스템 패키지를 업데이트하고 업그레이드합니다..."
print_message "$BLUE" "========================================="

if [[ $OS == "ubuntu" ]]; then
    sudo apt update && sudo apt upgrade -y
elif [[ $OS == "macos" ]]; then
    brew update && brew upgrade
fi

print_message "$GREEN" "시스템 업데이트 완료!"

# Screen 설치
if ! command -v screen &> /dev/null; then
    print_message "$YELLOW" "Screen이 설치되지 않았습니다. 설치 중..."
    if [[ $OS == "ubuntu" ]]; then
        sudo apt install -y screen
    elif [[ $OS == "macos" ]]; then
        brew install screen
    fi
else
    print_message "$GREEN" "Screen이 이미 설치되어 있습니다."
fi

# Nexus CLI 설치
print_message "$BLUE" "========================================="
print_message "$BLUE" "Nexus Network CLI를 설치합니다..."
print_message "$BLUE" "========================================="

# 기존 nexus 프로세스 종료
pkill -f nexus-network 2>/dev/null || true

# 기존 설치 제거
rm -rf ~/.nexus/bin/nexus-network 2>/dev/null || true

# Nexus CLI 설치
curl -sSL https://cli.nexus.xyz/ | sh

# 설치 완료 대기
sleep 3

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
    if [[ $OS == "ubuntu" ]]; then
        echo "export PATH=\"$NEXUS_PATH:\$PATH\"" >> ~/.bashrc
        source ~/.bashrc
    elif [[ $OS == "macos" ]]; then
        if [[ -f ~/.zshrc ]]; then
            echo "export PATH=\"$NEXUS_PATH:\$PATH\"" >> ~/.zshrc
            source ~/.zshrc
        else
            echo "export PATH=\"$NEXUS_PATH:\$PATH\"" >> ~/.bash_profile
            source ~/.bash_profile
        fi
    fi
fi

# 설치 확인
if [[ -n "$NEXUS_PATH" ]] && [[ -f "$NEXUS_PATH/nexus-network" ]]; then
    print_message "$GREEN" "Nexus CLI 설치가 성공적으로 완료되었습니다!"
    print_message "$GREEN" "Nexus 설치 경로: $NEXUS_PATH"
    echo "$NEXUS_PATH" > /tmp/nexus_install_path.tmp
else
    print_message "$RED" "오류: Nexus CLI 설치가 실패했을 수 있습니다!"
    exit 1
fi

# 설치 옵션 선택
print_message "$BLUE" "========================================="
print_message "$BLUE" "설치 옵션을 선택하세요:"
print_message "$YELLOW" "1) 기존 NodeID 사용"
print_message "$YELLOW" "2) 지갑 주소 사용 (새 노드)"
print_message "$BLUE" "========================================="

read -p "선택하세요 (1 또는 2): " choice

case $choice in
    1)
        read -p "NodeID를 입력하세요: " node_id
        if [[ -z "$node_id" ]]; then
            print_message "$RED" "오류: NodeID는 비워둘 수 없습니다!"
            exit 1
        fi
        
        # NodeID로 실행
        nexus_path=$(cat /tmp/nexus_install_path.tmp 2>/dev/null || echo "$HOME/.nexus/bin")
        print_message "$BLUE" "NodeID로 Nexus Network를 시작합니다: $node_id"
        print_message "$YELLOW" "Nexus 경로: $nexus_path"
        
        if [[ $OS == "ubuntu" ]]; then
            screen -dmS nexus_node bash -c "
                echo '환경 설정 중...'
                source ~/.bashrc 2>/dev/null || true
                export PATH=\"$nexus_path:\$PATH\"
                
                echo 'NodeID로 Nexus Network를 시작합니다: $node_id'
                echo 'Nexus 경로: $nexus_path/nexus-network'
                
                if [[ -f \"$nexus_path/nexus-network\" ]]; then
                    \"$nexus_path/nexus-network\" start --node-id $node_id
                else
                    echo '오류: $nexus_path에서 nexus-network를 찾을 수 없습니다'
                    echo '대체 경로를 시도합니다...'
                    if [[ -f \"\$HOME/.nexus/bin/nexus-network\" ]]; then
                        \"\$HOME/.nexus/bin/nexus-network\" start --node-id $node_id
                    elif [[ -f \"/root/.nexus/bin/nexus-network\" ]]; then
                        \"/root/.nexus/bin/nexus-network\" start --node-id $node_id
                    else
                        echo '오류: nexus-network 실행 파일을 찾을 수 없습니다!'
                    fi
                fi
                
                echo '종료하려면 Enter를 누르세요...'
                read
            "
        elif [[ $OS == "macos" ]]; then
            screen -dmS nexus_node zsh -c "
                echo '환경 설정 중...'
                source ~/.zshrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || true
                export PATH=\"$nexus_path:\$PATH\"
                
                echo 'NodeID로 Nexus Network를 시작합니다: $node_id'
                echo 'Nexus 경로: $nexus_path/nexus-network'
                
                if [[ -f \"$nexus_path/nexus-network\" ]]; then
                    \"$nexus_path/nexus-network\" start --node-id $node_id
                else
                    echo '오류: $nexus_path에서 nexus-network를 찾을 수 없습니다'
                    echo '대체 경로를 시도합니다...'
                    if [[ -f \"\$HOME/.nexus/bin/nexus-network\" ]]; then
                        \"\$HOME/.nexus/bin/nexus-network\" start --node-id $node_id
                    elif [[ -f \"/root/.nexus/bin/nexus-network\" ]]; then
                        \"/root/.nexus/bin/nexus-network\" start --node-id $node_id
                    else
                        echo '오류: nexus-network 실행 파일을 찾을 수 없습니다!'
                    fi
                fi
                
                echo '종료하려면 Enter를 누르세요...'
                read
            "
        fi
        
        sleep 2
        print_message "$GREEN" "Nexus 노드가 'nexus_node' screen 세션에서 시작되었습니다"
        print_message "$YELLOW" "세션에 연결하려면: screen -r nexus_node"
        print_message "$YELLOW" "screen에서 빠져나오려면: Ctrl+A, 그 다음 D"
        print_message "$BLUE" "노드 실행 상태를 확인합니다..."
        
        if screen -list | grep -q "nexus_node"; then
            print_message "$GREEN" "Screen 세션이 활성화되어 있습니다!"
        else
            print_message "$RED" "경고: Screen 세션이 종료되었을 수 있습니다. 로그를 확인하세요: screen -r nexus_node"
        fi
        ;;
        
    2)
        read -p "지갑 주소를 입력하세요: " wallet_address
        if [[ -z "$wallet_address" ]]; then
            print_message "$RED" "오류: 지갑 주소는 비워둘 수 없습니다!"
            exit 1
        fi
        
        # 지갑 주소로 실행
        nexus_path=$(cat /tmp/nexus_install_path.tmp 2>/dev/null || echo "$HOME/.nexus/bin")
        print_message "$BLUE" "지갑 주소로 Nexus Network를 등록합니다: $wallet_address"
        print_message "$YELLOW" "Nexus 경로: $nexus_path"
        
        if [[ $OS == "ubuntu" ]]; then
            screen -dmS nexus_node bash -c "
                echo '환경 설정 중...'
                source ~/.bashrc 2>/dev/null || true
                export PATH=\"$nexus_path:\$PATH\"
                
                echo '지갑 주소로 Nexus Network를 등록합니다: $wallet_address'
                echo 'Nexus 경로: $nexus_path/nexus-network'
                
                run_nexus() {
                    local cmd=\$1
                    shift
                    if [[ -f \"$nexus_path/nexus-network\" ]]; then
                        \"$nexus_path/nexus-network\" \$cmd \"\$@\"
                    elif [[ -f \"\$HOME/.nexus/bin/nexus-network\" ]]; then
                        \"\$HOME/.nexus/bin/nexus-network\" \$cmd \"\$@\"
                    elif [[ -f \"/root/.nexus/bin/nexus-network\" ]]; then
                        \"/root/.nexus/bin/nexus-network\" \$cmd \"\$@\"
                    else
                        echo '오류: nexus-network 실행 파일을 찾을 수 없습니다!'
                        return 1
                    fi
                }
                
                echo '1단계: 사용자 등록 중...'
                if run_nexus register-user --wallet-address $wallet_address; then
                    echo '사용자 등록 성공!'
                    
                    echo '2단계: 노드 등록 중...'
                    if run_nexus register-node; then
                        echo '노드 등록 성공!'
                        
                        echo '3단계: 노드 시작 중...'
                        run_nexus start
                    else
                        echo '오류: 노드 등록에 실패했습니다!'
                    fi
                else
                    echo '오류: 사용자 등록에 실패했습니다!'
                fi
                
                echo '종료하려면 Enter를 누르세요...'
                read
            "
        elif [[ $OS == "macos" ]]; then
            screen -dmS nexus_node zsh -c "
                echo '환경 설정 중...'
                source ~/.zshrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || true
                export PATH=\"$nexus_path:\$PATH\"
                
                echo '지갑 주소로 Nexus Network를 등록합니다: $wallet_address'
                echo 'Nexus 경로: $nexus_path/nexus-network'
                
                run_nexus() {
                    local cmd=\$1
                    shift
                    if [[ -f \"$nexus_path/nexus-network\" ]]; then
                        \"$nexus_path/nexus-network\" \$cmd \"\$@\"
                    elif [[ -f \"\$HOME/.nexus/bin/nexus-network\" ]]; then
                        \"\$HOME/.nexus/bin/nexus-network\" \$cmd \"\$@\"
                    elif [[ -f \"/root/.nexus/bin/nexus-network\" ]]; then
                        \"/root/.nexus/bin/nexus-network\" \$cmd \"\$@\"
                    else
                        echo '오류: nexus-network 실행 파일을 찾을 수 없습니다!'
                        return 1
                    fi
                }
                
                echo '1단계: 사용자 등록 중...'
                if run_nexus register-user --wallet-address $wallet_address; then
                    echo '사용자 등록 성공!'
                    
                    echo '2단계: 노드 등록 중...'
                    if run_nexus register-node; then
                        echo '노드 등록 성공!'
                        
                        echo '3단계: 노드 시작 중...'
                        run_nexus start
                    else
                        echo '오류: 노드 등록에 실패했습니다!'
                    fi
                else
                    echo '오류: 사용자 등록에 실패했습니다!'
                fi
                
                echo '종료하려면 Enter를 누르세요...'
                read
            "
        fi
        
        sleep 2
        print_message "$GREEN" "Nexus 노드 등록이 'nexus_node' screen 세션에서 시작되었습니다"
        print_message "$YELLOW" "세션에 연결하려면: screen -r nexus_node"
        print_message "$YELLOW" "screen에서 빠져나오려면: Ctrl+A, 그 다음 D"
        print_message "$BLUE" "노드 실행 상태를 확인합니다..."
        
        if screen -list | grep -q "nexus_node"; then
            print_message "$GREEN" "Screen 세션이 활성화되어 있습니다!"
        else
            print_message "$RED" "경고: Screen 세션이 종료되었을 수 있습니다. 로그를 확인하세요: screen -r nexus_node"
        fi
        ;;
        
    *)
        print_message "$RED" "오류: 잘못된 선택입니다! 1 또는 2를 선택하세요."
        exit 1
        ;;
esac

print_message "$GREEN" "========================================="
print_message "$GREEN" "설치가 성공적으로 완료되었습니다!"
print_message "$GREEN" "========================================="
print_message "$YELLOW" "유용한 명령어:"
print_message "$YELLOW" "- screen 세션 목록: screen -ls"
print_message "$YELLOW" "- 세션에 연결: screen -r nexus_node"
print_message "$YELLOW" "- 세션에서 빠져나오기: Ctrl+A, 그 다음 D"
print_message "$YELLOW" "- 세션 종료: screen -X -S nexus_node quit"

# 임시 파일 정리
rm -f /tmp/nexus_install_path.tmp 2>/dev/null || true

# 7. 실행    
/opt/glibc-2.39/lib/ld-linux-x86-64.so.2 --library-path /opt/glibc-2.39/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu /root/.nexus/bin/nexus-network start --node-id $NODE_ID

# 6. 완료 메시지
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Nexus 노드 설정이 완료되었습니다.${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "${YELLOW}아래 명령어로 노드 로그를 확인할 수 있습니다:${NC}"
echo -e "screen -r nexus_node"
echo -e "${YELLOW}screen 세션에서 빠져나오려면 Ctrl+A를 누른 뒤 D를 누르세요.${NC}
