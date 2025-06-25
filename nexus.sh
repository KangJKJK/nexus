#!/bin/bash

# 컬러 정의
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${Yellow}Nexus 노드를 설치합니다.${NC}"
echo -e "${RED}스크립트 실행 전에 screen을 필수로 실행하셔야합니다.${NC}"
read -p "계속 진행하시려면 Enter를 누르세요..."

# 설치 옵션 선택
echo -e "${YELLOW}설치 환경을 선택하세요:${NC}"
echo -e "${YELLOW}1) Ubuntu 22.04 새 설치${NC}"
echo -e "${YELLOW}2) Ubuntu 24.04 새 설치${NC}"
echo -e "${YELLOW}3) 추가 구동 (이미 설치된 환경에서 실행)${NC}"
read -p "선택하세요 (1, 2, 3): " main_choice

case $main_choice in
    1)
        # 1. 필수 패키지 설치
        echo -e "${YELLOW}필수 패키지를 설치합니다...${NC}"
        sudo apt update & sudo apt upgrade -y
        sudo apt install screen curl build-essential pkg-config libssl-dev git-all -y
        sudo apt install protobuf-compiler -y
        sudo apt install -y gawk bison gcc make wget tar
        sudo apt update

        # 1. Rust 설치
        echo -e "${YELLOW}Rust를 설치합니다...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        rustup target add riscv32i-unknown-none-elf

        # 2. Nexus 설치
        curl https://cli.nexus.xyz/ | sh
        source ~/.bashrc

        # 3. 상세설치

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
                    "$nexus_path/nexus-network" start --node-id $node_id
                else
                    echo -e "${RED}오류: $nexus_path에서 nexus-network를 찾을 수 없습니다${NC}"
                    echo -e "${YELLOW}대체 경로를 시도합니다...${NC}"
                    if [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                        "$HOME/.nexus/bin/nexus-network" start --node-id $node_id
                    elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                        "/root/.nexus/bin/nexus-network" start --node-id $node_id
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
                    "$nexus_path/nexus-network" register-user --wallet-address $wallet_address
                elif [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                    "$HOME/.nexus/bin/nexus-network" register-user --wallet-address $wallet_address
                elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                    "/root/.nexus/bin/nexus-network" register-user --wallet-address $wallet_address
                else
                    echo -e "${RED}오류: nexus-network 실행 파일을 찾을 수 없습니다!${NC}"
                    exit 1
                fi

                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}사용자 등록 성공!${NC}"
                    
                    echo -e "${YELLOW}2단계: 노드 등록 중...${NC}"
                    if [[ -f "$nexus_path/nexus-network" ]]; then
                        "$nexus_path/nexus-network" register-node
                    elif [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                        "$HOME/.nexus/bin/nexus-network" register-node
                    elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                        "/root/.nexus/bin/nexus-network" register-node
                    fi
                    
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}노드 등록 성공!${NC}"
                        
                        echo -e "${YELLOW}3단계: 노드 시작 중...${NC}"
                        if [[ -f "$nexus_path/nexus-network" ]]; then
                            "$nexus_path/nexus-network" start
                        elif [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                            "$HOME/.nexus/bin/nexus-network" start
                        elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                            "/root/.nexus/bin/nexus-network" start
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
        ;;
        
    2)
        # 1. 필수 패키지 설치
        echo -e "${YELLOW}필수 패키지를 설치합니다...${NC}"
        sudo apt update & sudo apt upgrade -y
        sudo apt install screen curl build-essential pkg-config libssl-dev git-all -y
        sudo apt install protobuf-compiler -y
        sudo apt install -y gawk bison gcc make wget tar
        sudo apt update

        # 1. GLIBC 2.39 설치
        echo -e "${YELLOW}GLIBC 2.39를 설치합니다...${NC}"
        wget -c https://ftp.gnu.org/gnu/glibc/glibc-2.39.tar.gz
        tar -zxvf glibc-2.39.tar.gz
        cd ~/glibc-2.39
        mkdir -p ../glibc-build
        cd ../glibc-build
        ../glibc-2.39/configure --prefix=/opt/glibc-2.39
        make -j$(nproc)
        sudo make install
            
        # 2. Rust 설치
        echo -e "${YELLOW}Rust를 설치합니다...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        rustup target add riscv32i-unknown-none-elf

        # 3. Nexus 설치
        curl https://cli.nexus.xyz/ | sh
        source ~/.bashrc

        # 4. 상세설치

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
                    "$nexus_path/nexus-network" start --node-id $node_id
                else
                    echo -e "${RED}오류: $nexus_path에서 nexus-network를 찾을 수 없습니다${NC}"
                    echo -e "${YELLOW}대체 경로를 시도합니다...${NC}"
                    if [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                        "$HOME/.nexus/bin/nexus-network" start --node-id $node_id
                    elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                        "/root/.nexus/bin/nexus-network" start --node-id $node_id
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
                    "$nexus_path/nexus-network" register-user --wallet-address $wallet_address
                elif [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                    "$HOME/.nexus/bin/nexus-network" register-user --wallet-address $wallet_address
                elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                    "/root/.nexus/bin/nexus-network" register-user --wallet-address $wallet_address
                else
                    echo -e "${RED}오류: nexus-network 실행 파일을 찾을 수 없습니다!${NC}"
                    exit 1
                fi

                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}사용자 등록 성공!${NC}"
                    
                    echo -e "${YELLOW}2단계: 노드 등록 중...${NC}"
                    if [[ -f "$nexus_path/nexus-network" ]]; then
                        "$nexus_path/nexus-network" register-node
                    elif [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                        "$HOME/.nexus/bin/nexus-network" register-node
                    elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                        "/root/.nexus/bin/nexus-network" register-node
                    fi
                    
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}노드 등록 성공!${NC}"
                        
                        echo -e "${YELLOW}3단계: 노드 시작 중...${NC}"
                        if [[ -f "$nexus_path/nexus-network" ]]; then
                            "$nexus_path/nexus-network" start
                        elif [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                            "$HOME/.nexus/bin/nexus-network" start
                        elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                            "/root/.nexus/bin/nexus-network" start
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
        ;;
        
    3)
        echo -e "${YELLOW}기존에 구동중인 스크린과 다른 스크린을 실행해야만합니다.${NC}"
        echo -e "${YELLOW}구동중인 노드id가 아닌 다른 id를 입력하셔야합니다..${NC}"
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
                "$nexus_path/nexus-network" start --node-id $node_id
            else
                echo -e "${RED}오류: $nexus_path에서 nexus-network를 찾을 수 없습니다${NC}"
                echo -e "${YELLOW}대체 경로를 시도합니다...${NC}"
                if [[ -f "$HOME/.nexus/bin/nexus-network" ]]; then
                    "$HOME/.nexus/bin/nexus-network" start --node-id $node_id
                elif [[ -f "/root/.nexus/bin/nexus-network" ]]; then
                    "/root/.nexus/bin/nexus-network" start --node-id $node_id
                else
                    echo -e "${RED}오류: nexus-network 실행 파일을 찾을 수 없습니다!${NC}"
                fi
            fi
            ;;
        esac
        ;;

    *)
        echo -e "${RED}오류: 잘못된 선택입니다! 1, 2, 3 중에서 선택하세요.${NC}"
        exit 1
        ;;
esac

# 6. 완료 메시지
echo -e "${GREEN}설치가 성공적으로 완료되었습니다!${NC}"
echo -e "${GREEN}screen 세션 목록: screen -ls${NC}"
echo -e "${YELLOW}screen 세션에서 빠져나오려면 Ctrl+A를 누른 뒤 D를 누르세요.${NC}"
