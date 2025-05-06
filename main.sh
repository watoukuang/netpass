#!/bin/bash
#
# NetPass - Network and Docker Setup Script
# Date: 2025-05-06
# Version: 1.0

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display script usage
show_help() {
    echo -e "${BLUE}NetPass - Network and Docker Setup Script${NC}"
    echo ""
    echo "Usage: ./main.sh [option]"
    echo ""
    echo "Options:"
    echo "  -f, --firewall        Configure and enable firewall"
    echo "  -d, --docker          Install Docker and Docker Compose"
    echo "  -n, --nginx           Setup Nginx with Docker"
    echo "  -t, --trojan          Install and configure Trojan"
    echo "  -h, --help            Show this help message"
}

# Function to set up firewall
setup_firewall() {
    echo -e "${BLUE}Setting up firewall...${NC}"
    
    # Update package lists
    echo -e "${YELLOW}Updating package lists...${NC}"
    sudo apt update
    
    # Install UFW if not already installed
    if ! command -v ufw &> /dev/null; then
        echo -e "${YELLOW}Installing UFW...${NC}"
        sudo apt install -y ufw
    fi
    
    # Configure UFW
    echo -e "${YELLOW}Configuring UFW...${NC}"
    
    # Allow SSH (port 22) to prevent lockout
    sudo ufw allow ssh
    
    # Allow specific ports
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Enable UFW if not already enabled
    if ! sudo ufw status | grep -q "Status: active"; then
        echo -e "${YELLOW}Enabling UFW...${NC}"
        echo "y" | sudo ufw enable
    fi
    
    # Show status
    echo -e "${YELLOW}Firewall status:${NC}"
    sudo ufw status
    
    echo -e "${GREEN}Firewall setup completed.${NC}"
}

# Function to install Docker and Docker Compose
setup_docker() {
    echo -e "${BLUE}Installing Docker...${NC}"
    
    # Update existing packages
    echo -e "${YELLOW}Updating existing packages...${NC}"
    sudo apt update
    sudo apt upgrade -y
    
    # Install necessary dependencies
    echo -e "${YELLOW}Installing necessary dependencies...${NC}"
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    
    # Add Docker's official GPG key
    echo -e "${YELLOW}Adding Docker's official GPG key...${NC}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    
    # Add Docker repository
    echo -e "${YELLOW}Adding Docker repository...${NC}"
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    # Update APT package index
    echo -e "${YELLOW}Updating APT package index...${NC}"
    sudo apt update
    
    # Install Docker
    echo -e "${YELLOW}Installing Docker...${NC}"
    sudo apt install -y docker-ce
    
    # Start Docker and enable autostart
    echo -e "${YELLOW}Starting Docker and enabling autostart...${NC}"
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Verify Docker installation
    echo -e "${YELLOW}Verifying Docker installation...${NC}"
    sudo docker --version
    
    # Add current user to docker group to run docker without sudo
    echo -e "${YELLOW}Adding current user to docker group...${NC}"
    sudo usermod -aG docker $USER
    echo -e "${YELLOW}Note: You may need to log out and log back in for the group changes to take effect.${NC}"
    
    echo -e "${GREEN}Docker installation completed successfully.${NC}"
}

# Function to setup Nginx with Docker
setup_nginx() {
    echo -e "${BLUE}Setting up Nginx with Docker...${NC}"
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker is not installed. Installing Docker first...${NC}"
        setup_docker
    fi
    
    # Pull Nginx image
    echo -e "${YELLOW}Pulling Nginx Docker image...${NC}"
    docker pull nginx
    
    # Run Nginx container
    echo -e "${YELLOW}Running Nginx container...${NC}"
    docker run --name nginx-container -d -p 80:80 nginx
    
    # Check if Nginx container is running
    if docker ps | grep -q nginx-container; then
        echo -e "${GREEN}Nginx is now running. You can access it at http://localhost${NC}"
    else
        echo -e "${RED}Failed to start Nginx container. Please check Docker logs.${NC}"
        docker logs nginx-container
    fi
    
    echo -e "${GREEN}Nginx setup completed.${NC}"
}

setup_trojan(){
  echo -e "${BLUE}Setting up Trojan-Go...${NC}"
  
  # 创建目标目录
  TROJAN_DIR="trojan"
  mkdir -p $TROJAN_DIR
  
  # 检查并安装必要的工具
  echo -e "${YELLOW}Checking for required tools...${NC}"
  if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}Installing unzip...${NC}"
    sudo apt update
    sudo apt install -y unzip
  fi
  
  # 下载 Trojan-Go
  echo -e "${YELLOW}Downloading Trojan-Go...${NC}"
  if [ "$(uname)" == "Darwin" ]; then
    # macOS
    sudo wget -q https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-darwin-amd64.zip -O trojan-go.zip || \
    sudo curl -L https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-darwin-amd64.zip -o trojan-go.zip
  else
    # Linux
    sudo wget -q https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip -O trojan-go.zip || \
    sudo curl -L https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip -o trojan-go.zip
  fi
  
  # 检查下载是否成功
  if [ ! -f "trojan-go.zip" ]; then
    echo -e "${RED}Failed to download Trojan-Go. Please check your internet connection.${NC}"
    return 1
  fi
  
  # 解压文件到trojan目录
  echo -e "${YELLOW}Extracting Trojan-Go...${NC}"
  sudo unzip -o trojan-go.zip -d $TROJAN_DIR
  
  # 检查解压是否成功
  if [ ! -f "$TROJAN_DIR/trojan-go" ]; then
    echo -e "${RED}Failed to extract Trojan-Go. The archive may be corrupted.${NC}"
    return 1
  fi
  
  # 复制配置文件
  echo -e "${YELLOW}Creating configuration file...${NC}"
  if [ -f "server.json" ]; then
    sudo cp server.json $TROJAN_DIR/
    echo -e "${GREEN}Configuration file copied successfully.${NC}"
  else
    echo -e "${YELLOW}server.json not found. Creating a default configuration...${NC}"
    cat > $TROJAN_DIR/server.json << 'EOF'
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 443,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "password": [
    "your_password_here"
  ],
  "ssl": {
    "cert": "server.crt",
    "key": "server.key"
  }
}
EOF
    echo -e "${GREEN}Default configuration created. Please edit $TROJAN_DIR/server.json to set your password and SSL certificates.${NC}"
  fi
  
  # 设置权限
  sudo chmod +x $TROJAN_DIR/trojan-go
  
  # 删除下载的zip文件
  sudo rm -f trojan-go.zip
  
  echo -e "${GREEN}Trojan-Go has been set up in $TROJAN_DIR directory.${NC}"
  echo -e "${YELLOW}To start Trojan-Go, run: cd $TROJAN_DIR && ./trojan-go -config server.json${NC}"
  echo -e "${YELLOW}Note: Before running Trojan-Go, make sure to configure your SSL certificates in server.json.${NC}"
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    case "$1" in
        -f|--firewall)
            setup_firewall
            ;;
        -d|--docker)
            setup_docker
            ;;
        -n|--nginx)
            setup_nginx
            ;;
        -t|--trojan)
            setup_trojan
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"