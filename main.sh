#!/bin/bash
#
# NetPass - Network and Nginx Setup Script
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
    echo -e "${BLUE}NetPass - Network and Nginx Setup Script${NC}"
    echo ""
    echo "Usage: ./main.sh [option]"
    echo ""
    echo "Options:"
    echo "  -f, --firewall        Configure and enable firewall"
    echo "  -n, --nginx           Install and configure Nginx"
    echo "  -d, --docker          Install Docker and Docker Compose"
    echo "  -a, --all             Install and configure everything"
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

# Function to install and configure Nginx
setup_nginx() {
    echo -e "${BLUE}Setting up Nginx...${NC}"
    
    # Update package lists
    echo -e "${YELLOW}Updating package lists...${NC}"
    sudo apt update
    
    # Install Nginx if not already installed
    if ! command -v nginx &> /dev/null; then
        echo -e "${YELLOW}Installing Nginx...${NC}"
        sudo apt install -y nginx
    fi
    
    # Create necessary directories
    echo -e "${YELLOW}Creating necessary directories...${NC}"
    sudo mkdir -p /usr/local/web/bellsmap.com/src
    sudo mkdir -p /usr/local/web/cert
    
    # Copy Nginx configuration
    echo -e "${YELLOW}Copying Nginx configuration...${NC}"
    sudo cp "$(dirname "$0")/nginx.conf" /etc/nginx/nginx.conf
    
    # Create a simple index.html file
    echo -e "${YELLOW}Creating a sample index.html file...${NC}"
    cat > /tmp/index.html << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to NetPass!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            padding: 2em;
            background-color: #f5f5f5;
            color: #333;
        }
        h1 {
            color: #0066cc;
            border-bottom: 1px solid #eee;
            padding-bottom: 0.3em;
        }
        p {
            margin: 1em 0;
        }
        .success {
            background-color: #e6ffe6;
            border-left: 4px solid #00cc00;
            padding: 0.7em;
        }
    </style>
</head>
<body>
    <h1>Welcome to NetPass!</h1>
    <p class="success">If you see this page, the Nginx web server is successfully installed and working.</p>
    <p>This is a test page for the NetPass system.</p>
</body>
</html>
EOL
    sudo mv /tmp/index.html /usr/local/web/bellsmap.com/src/index.html
    
    # Set proper permissions
    echo -e "${YELLOW}Setting proper permissions...${NC}"
    sudo chown -R www-data:www-data /usr/local/web
    
    # Test Nginx configuration
    echo -e "${YELLOW}Testing Nginx configuration...${NC}"
    sudo nginx -t
    
    # Restart Nginx
    echo -e "${YELLOW}Restarting Nginx...${NC}"
    sudo systemctl restart nginx
    
    # Enable Nginx to start at boot
    echo -e "${YELLOW}Enabling Nginx to start at boot...${NC}"
    sudo systemctl enable nginx
    
    echo -e "${GREEN}Nginx setup completed.${NC}"
    echo -e "${YELLOW}You can now access your web server at http://bellsmap.com${NC}"
    echo -e "${YELLOW}Note: Make sure bellsmap.com points to your server's IP address in your DNS or hosts file.${NC}"
}

# Function to install Docker and Docker Compose
setup_docker() {
    echo -e "${BLUE}Setting up Docker...${NC}"
    
    # Update package lists
    echo -e "${YELLOW}Updating package lists...${NC}"
    sudo apt update
    
    # Install dependencies
    echo -e "${YELLOW}Installing dependencies...${NC}"
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    
    # Add Docker's official GPG key
    echo -e "${YELLOW}Adding Docker's GPG key...${NC}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    
    # Add Docker repository
    echo -e "${YELLOW}Adding Docker repository...${NC}"
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    # Update package lists again
    echo -e "${YELLOW}Updating package lists...${NC}"
    sudo apt update
    
    # Install Docker CE
    echo -e "${YELLOW}Installing Docker CE...${NC}"
    sudo apt install -y docker-ce
    
    # Add current user to docker group
    echo -e "${YELLOW}Adding current user to docker group...${NC}"
    sudo usermod -aG docker $USER
    
    # Install Docker Compose
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Start and enable Docker service
    echo -e "${YELLOW}Starting and enabling Docker service...${NC}"
    sudo systemctl start docker
    sudo systemctl enable docker
    
    echo -e "${GREEN}Docker setup completed.${NC}"
    echo -e "${YELLOW}You may need to log out and log back in for docker group changes to take effect.${NC}"
}

# Function to set up everything
setup_all() {
    setup_firewall
    setup_docker
    setup_nginx
    
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
        -n|--nginx)
            setup_nginx
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