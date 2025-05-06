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
    echo "  -a, --all             Install and configure everything (firewall and Docker)"
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

# Function to set up everything
setup_all() {
    setup_firewall
    setup_docker
    
    echo -e "${GREEN}All components have been set up successfully.${NC}"
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
        -a|--all)
            setup_all
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