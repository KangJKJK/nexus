#!/bin/bash

# 컬러 정의
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. 디스크 여유 공간 확인
AVAILABLE_KB=$(df / | tail -1 | awk '{print $4}')
AVAILABLE_MB=$((AVAILABLE_KB / 1024))
SWAP_MB=$((AVAILABLE_MB * 80 / 100))

echo "현재 루트 파티션 여유 공간: ${AVAILABLE_MB}MB"
echo "디스크 용량의 80%인 약 ${SWAP_MB}MB를 스왑으로 사용할 예정입니다."

# 2. 사용자에게 진행 여부 확인
read -p "스왑 설정을 진행하시겠습니까? (y/N): " answer
case "$answer" in
  [Yy]* )
    echo "스왑 설정을 진행합니다."
    ;;
  * )
    echo "스왑 설정을 건너뜁니다."
    exit 0
    ;;
esac

# 3. 스왑파일 존재 여부 확인
if [ -f /swapfile ]; then
  echo "스왑 파일이 이미 존재합니다. 스왑 설정을 건너뜁니다."
  exit 0
fi

# 4. 여유 공간 체크 (최소 1GB)
if [ $SWAP_MB -lt 1024 ]; then
  echo "디스크 여유 공간이 너무 적어 1GB 미만입니다. 스왑 설정을 중단합니다."
  exit 1
fi

echo "스왑 파일 크기: ${SWAP_MB}MB 으로 설정합니다."

# 5. 기존 스왑 해제 및 스왑 파일 삭제
sudo swapoff /swapfile 2>/dev/null
sudo rm -f /swapfile

# 6. 스왑 파일 생성 및 권한 설정
sudo fallocate -l ${SWAP_MB}M /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile

# 7. 스왑 활성화
sudo swapon /swapfile

# 8. 부팅 시 자동 활성화를 위한 fstab 설정
if ! grep -q '/swapfile' /etc/fstab; then
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
fi

echo -e "${Yellow}Nexus 노드를 설치합니다.${NC}"
echo -e "${Yellow}작성자: t.me/kjkresearch${NC}"
echo -e "${RED}스크립트 실행 전에 screen을 필수로 실행하셔야합니다.${NC}"
echo -e "${GREEN}1.설치 및 구동 진행 후 컨트롤 A+D로 스크린을 빠져나오세요.${NC}"
echo -e "${GREEN}2.screen 세션 목록을 불러오신 후 특정 스크린으로 재진입시 현재 상태를 볼 수 있습니다.${NC}"
echo -e "${GREEN}3.중복구동 시 사용중인 VPS의 RAM용량이 초과하지않도록 체크해야합니다.${NC}"
read -p "계속 진행하시려면 Enter를 누르세요..."

# 설치 옵션 선택
echo -e "${YELLOW}설치 환경을 선택하세요:${NC}"
echo -e "${YELLOW}1) Ubuntu 22.04 새 설치${NC}"
echo -e "${YELLOW}2) Ubuntu 24.04 새 설치${NC}"
echo -e "${YELLOW}3) 추가 구동 (22.04)${NC}"
echo -e "${YELLOW}4) 추가 구동 (24.04)${NC}"
read -p "선택하세요 (1, 2, 3, 4): " main_choice

case $main_choice in
      1)
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
        cd ~/glibc-2.39
        mkdir -p ../glibc-build
        cd ../glibc-build
        ../glibc-2.39/configure --prefix=/opt/glibc-2.39
        make -j$(nproc)
        sudo make install

        # 3. Rust 설치
        echo -e "${YELLOW}Rust를 설치합니다...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        rustup target add riscv32i-unknown-none-elf

        # 4. Nexus 설치
        curl https://cli.nexus.xyz/ | sh
        source ~/.bashrc

        # 5. 상세설치

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

        echo -e "${BLUE}진행 옵션을 선택하세요:${NC}"
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
        ;;
        
    2)
        # 1. 필수 패키지 설치
        echo -e "${YELLOW}필수 패키지를 설치합니다...${NC}"
        sudo apt update & sudo apt upgrade -y
        sudo apt install screen curl build-essential pkg-config libssl-dev git-all -y
        sudo apt install protobuf-compiler -y
        sudo apt install -y gawk bison gcc make wget tar
        sudo apt update
            
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
        
    4)
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
