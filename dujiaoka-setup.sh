#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function definitions
install_docker() {
    echo -e "${YELLOW}Checking Docker installation status...${NC}"
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}Docker and Docker Compose are already installed${NC}"
    else
        echo -e "${YELLOW}Installing Docker...${NC}"
        curl -fsSL https://get.docker.com | sh
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        sudo systemctl enable docker
        echo -e "${GREEN}Docker installation complete${NC}"
    fi
    read -p "Press Enter to continue..."
}

check_docker() {
    echo -e "${YELLOW}Checking Docker installation status...${NC}"
    if command -v docker &> /dev/null; then
        docker_version=$(docker --version | awk '{print $3}' | tr -d ',')
        echo -e "${GREEN}Docker version: ${docker_version}${NC}"
    else
        echo -e "${RED}Docker is not installed${NC}"
    fi
    
    if command -v docker-compose &> /dev/null; then
        compose_version=$(docker-compose --version | awk '{print $4}' | tr -d ',')
        echo -e "${GREEN}Docker Compose version: ${compose_version}${NC}"
    else
        echo -e "${RED}Docker Compose is not installed${NC}"
    fi
    read -p "Press Enter to continue..."
}

install_dujiaoka() {
    echo -e "${YELLOW}Installing Dujiaoka...${NC}"
    
    # Download installation script
    if curl -sS -o duka.sh https://raw.githubusercontent.com/woniu336/open_shell/main/duka.sh; then
        chmod +x duka.sh
        echo -e "${GREEN}Installation script downloaded successfully${NC}"
    else
        echo -e "${RED}Failed to download installation script, please check your network connection and try again${NC}"
        read -p "Press Enter to return to the main menu..."
        return
    fi
    
    # Run installation script
    echo -e "${YELLOW}Running installation script, this may take a few minutes...${NC}"
    if ./duka.sh; then
        echo -e "${GREEN}Dujiaoka installation script executed successfully${NC}"
        echo -e "${YELLOW}Please note the database password displayed in the terminal, as you will need it for configuration.${NC}"
    else
        echo -e "${RED}Dujiaoka installation script execution failed${NC}"
        echo -e "${YELLOW}Check the error messages, resolve the issues, and try again${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

configure_dujiaoka() {
    clear
    echo -e "${GREEN}Follow these steps to configure the web interface:${NC}"
    echo -e ""
    echo -e "1. Open your browser and visit ${CYAN}http://your-server-ip:3080${NC}"
    echo -e "2. On the configuration page, set the following:
"
    
    echo -e "   ${PURPLE}● Database settings:${NC}"
    echo -e "     - Database address: ${CYAN}db${NC}"
    echo -e "     - Database username: ${CYAN}dujiaoka${NC}"
    echo -e "     - Database password: ${CYAN}[Use the password displayed in the terminal]${NC}"
    
    echo -e "
   ${PURPLE}● Redis settings:${NC}"
    echo -e "     - Redis address: ${CYAN}redis${NC}"
    
    echo -e "
   ${PURPLE}● Website settings:${NC}"
    echo -e "     - Website name: ${CYAN}[Enter your website name]${NC}"
    echo -e "     - Website URL: ${CYAN}[Enter your full domain, e.g., http://shop.example.com]${NC}"
    
    echo -e "
${GREEN}Note: Admin panel URL is /admin, default username and password are admin${NC}"
    echo -e ""
    read -p "$(echo -e ${YELLOW}"Once configuration is complete, press Enter to continue..."${NC})"
}

disable_install() {
    echo -e "${YELLOW}Disabling installation...${NC}"
    cd /root/dujiao
    sed -i 's/INSTALL=true/INSTALL=false/' docker-compose.yaml
    docker-compose down && docker-compose up -d
    echo -e "${GREEN}Installation disabled${NC}"
    read -p "Press Enter to continue..."
}

enable_https() {
    echo -e "${YELLOW}Enabling HTTPS...${NC}"
    sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/' /root/dujiao/env.conf
    echo -e "${GREEN}HTTPS enabled${NC}"
    echo -e "${YELLOW}Make sure your domain has a valid SSL certificate${NC}"
    read -p "Press Enter to continue..."
}

disable_debug() {
    echo -e "${YELLOW}Disabling debug mode...${NC}"
    sed -i 's/APP_DEBUG=true/APP_DEBUG=false/' /root/dujiao/env.conf
    echo -e "${GREEN}Debug mode disabled${NC}"
    read -p "Press Enter to continue..."
}

remove_dujiaoka() {
    echo -e "${YELLOW}Removing Dujiaoka, this will take a while...${NC}"
    
    # Stop and remove containers
    docker stop faka faka-data faka-redis
    docker rm faka faka-data faka-redis
    
    # Remove images
    docker rmi ghcr.io/apocalypsor/dujiaoka:latest redis:alpine mariadb:focal
    
    # Remove network
    docker network rm dujiao_default
    
    # Delete related files and directories
    rm -rf /root/dujiao
    
    echo -e "${GREEN}Dujiaoka has been completely removed${NC}"
    read -p "Press Enter to continue..."
}

show_menu() {
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}    Dujiaoka Installation & Management Script${NC}"
    echo -e "${CYAN}    Blog: woniu336.github.io${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo "1. Install Docker"
    echo "2. Check Docker Version"
    echo "3. Install Dujiaoka"
    echo "4. Configure Dujiaoka"
    echo "5. Disable Installation"
    echo "6. Enable HTTPS"
    echo "7. Disable Debug Mode"
    echo "8. Completely Remove Dujiaoka"
    echo "0. Exit"
    echo -e "${GREEN}===================================${NC}"
}

while true; do
    clear
    show_menu
    read -p "Choose an option (0-8): " choice
    clear
    case $choice in
        1) install_docker ;;
        2) check_docker ;;
        3) install_dujiaoka ;;
        4) configure_dujiaoka ;;
        5) disable_install ;;
        6) enable_https ;;
        7) disable_debug ;;
        8) remove_dujiaoka ;;
        0) echo "Exiting script"; exit 0 ;;
        *) echo -e "${RED}Invalid choice, please try again${NC}"; read -p "Press Enter to continue..." ;;
    esac
done
