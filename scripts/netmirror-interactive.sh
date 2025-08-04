#!/bin/bash

# NetMirror Interactive Deployment & Management Script
# Based on ServerStatus-Rust menu design pattern
# Usage: ./netmirror-interactive.sh [--cn]

set -e

# Parse language flag
LANG_CN=false
for arg in "$@"; do
    case $arg in
        --cn)
            LANG_CN=true
            shift
            ;;
        -h|--help)
            echo "NetMirror Interactive Deployment Script"
            echo "Usage: $0 [--cn]"
            echo "  --cn    Use Chinese language interface"
            echo "  --help  Show this help message"
            exit 0
            ;;
    esac
done

# Configuration
REPO_URL="https://raw.githubusercontent.com/catcat-blog/NetMirror/main/.env.example"
IMAGE="soyorins/netmirror:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DEPLOY_BASE="/opt/netmirror"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Language-aware text function
text() {
    local key="$1"
    if [[ "$LANG_CN" == "true" ]]; then
        case "$key" in
            "script_title") echo "NetMirror 部署管理脚本" ;;
            "basic_tools") echo "基础工具" ;;
            "master_management") echo "主节点管理" ;;
            "child_management") echo "子节点管理" ;;
            "check_docker") echo "Docker安装" ;;
            "edit_config") echo "编辑配置" ;;
            "install_master") echo "安装主节点" ;;
            "restart_master") echo "重启主节点" ;;
            "status_master") echo "主节点状态" ;;
            "remove_master") echo "删除主节点" ;;
            "install_child") echo "安装子节点" ;;
            "restart_child") echo "重启子节点" ;;
            "status_child") echo "子节点状态" ;;
            "remove_child") echo "删除子节点" ;;
            "show_all") echo "所有容器" ;;
            "exit_program") echo "退出程序" ;;
            "select_option") echo "请选择操作" ;;
            "press_enter") echo "按 Enter 键继续..." ;;
            "invalid_choice") echo "无效选择，请输入 0-11" ;;
            "thanks") echo "感谢使用 NetMirror 部署脚本!" ;;
            "need_root") echo "此脚本需要 root 权限运行" ;;
            "use_sudo") echo "请使用: sudo $0" ;;
            "need_interactive") echo "此脚本需要在交互式终端中运行" ;;
            "docker_installed") echo "Docker 已安装" ;;
            "docker_not_found") echo "未发现 Docker，开始安装..." ;;
            "docker_installing") echo "正在检查 Docker 安装状态..." ;;
            "docker_complete") echo "Docker 安装完成!" ;;
            "docker_ready") echo "Docker 已就绪" ;;
            "relogin_required") echo "请重新登录或运行 'newgrp docker' 以使用 Docker" ;;
            "docker_test_success") echo "Docker 测试成功" ;;
            "docker_test_failed") echo "Docker 测试失败，请检查安装" ;;
            "config_edit") echo "配置文件编辑" ;;
            "install_node_first") echo "请先安装节点后再编辑配置" ;;
            "found_config_dirs") echo "发现以下配置目录：" ;;
            "unknown_node") echo "未知节点" ;;
            "unknown_port") echo "未知端口" ;;
            "port_label") echo "端口" ;;
            "return_main_menu") echo "返回主菜单" ;;
            "select_config_file") echo "请选择要编辑的配置文件" ;;
            "editing_config") echo "编辑配置文件" ;;
            "no_text_editor") echo "未找到文本编辑器 (nano, vim, vi)" ;;
            "config_edited") echo "配置文件已编辑" ;;
            "restart_container_prompt") echo "是否重启对应的容器以应用更改? [y/N]" ;;
            "restarting_container") echo "重启容器" ;;
            "container_restart_success") echo "容器重启成功" ;;
            "container_restart_failed") echo "容器重启失败" ;;
            "invalid_selection") echo "无效选择" ;;
            "install_master_title") echo "安装主节点" ;;
            "node_name_prompt") echo "节点名称 (例: 主节点)" ;;
            "node_location_prompt") echo "节点位置 (例: 北京, 中国)" ;;
            "http_port_prompt") echo "HTTP 端口 [3000]" ;;
            "custom_url_prompt") echo "自定义访问URL (可选，用于反向代理)" ;;
            "generating_api_key") echo "为主节点生成管理 API 密钥..." ;;
            "api_key_label") echo "API 密钥" ;;
            "save_api_key") echo "请妥善保存此密钥，子节点连接时需要使用" ;;
            "creating_deploy_dir") echo "创建部署目录" ;;
            "creating_config") echo "创建配置文件..." ;;
            "starting_container") echo "启动容器..." ;;
            "master_install_success") echo "主节点安装成功!" ;;
            "node_info") echo "节点信息:" ;;
            "name_label") echo "名称" ;;
            "location_label") echo "位置" ;;
            "access_url") echo "访问地址" ;;
            "admin_panel") echo "管理面板: 点击右下角设置图标 (⚙️)" ;;
            "deploy_path") echo "部署路径" ;;
            "admin_api_key") echo "管理员 API 密钥:" ;;
            "child_connect_info") echo "子节点连接信息:" ;;
            "master_address") echo "主节点地址" ;;
            "container_start_failed") echo "容器启动失败" ;;
            "check_logs") echo "检查日志" ;;
            "install_child_title") echo "安装子节点" ;;
            "master_connect_info") echo "主节点连接信息" ;;
            "master_url_prompt") echo "主节点 URL (例: http://master-ip:3000)" ;;
            "admin_api_key_prompt") echo "管理员 API 密钥" ;;
            "verifying_master") echo "验证主节点连接..." ;;
            "cannot_connect_master") echo "无法连接到主节点" ;;
            "verifying_api_key") echo "验证 API 密钥..." ;;
            "api_key_valid") echo "API 密钥验证成功" ;;
            "api_key_invalid") echo "API 密钥无效" ;;
            "connection_failed") echo "连接失败" ;;
            "api_verification_continue") echo "API 验证返回 HTTP $response，继续安装..." ;;
            "child_config") echo "子节点配置" ;;
            "child_node_name_prompt") echo "节点名称 (例: 上海节点)" ;;
            "child_node_location_prompt") echo "节点位置 (例: 上海, 中国)" ;;
            "child_port_prompt") echo "HTTP 端口 [3001]" ;;
            "child_install_success") echo "子节点安装成功!" ;;
            "registering_to_master") echo "尝试向主节点注册..." ;;
            "register_success") echo "已成功注册到主节点" ;;
            "node_exists") echo "节点已存在于主节点中" ;;
            "register_failed") echo "自动注册失败 (HTTP $register_response)，请手动添加" ;;
            "master_node_label") echo "主节点" ;;
            "restart_node_title") echo "重启" ;;
            "node_label") echo "节点" ;;
            "no_running_containers") echo "未找到运行中的" ;;
            "found_containers") echo "发现以下" ;;
            "containers_label") echo "节点容器：" ;;
            "unknown_status") echo "未知" ;;
            "select_container_restart") echo "请选择要重启的容器" ;;
            "restarting_container_name") echo "重启容器" ;;
            "node_status_title") echo "节点状态" ;;
            "no_containers_found") echo "未找到" ;;
            "container_label") echo "容器" ;;
            "status_label") echo "状态" ;;
            "node_name_label") echo "节点名" ;;
            "created_time") echo "创建时间" ;;
            "management_commands") echo "管理命令：" ;;
            "view_logs") echo "查看日志: sudo docker logs -f <容器名>" ;;
            "enter_container") echo "进入容器: sudo docker exec -it <容器名> /bin/sh" ;;
            "remove_node_title") echo "卸载" ;;
            "select_container_remove") echo "请选择要卸载的容器" ;;
            "removing_container") echo "即将卸载容器" ;;
            "confirm_delete") echo "确认删除? 此操作不可恢复 [y/N]" ;;
            "stopping_removing") echo "停止并删除容器" ;;
            "delete_deploy_dir") echo "是否删除部署目录" ;;
            "deploy_dir_deleted") echo "部署目录已删除" ;;
            "container_removed") echo "容器已卸载" ;;
            "operation_cancelled") echo "取消卸载操作" ;;
            "all_containers_title") echo "所有 NetMirror 容器" ;;
            "no_netmirror_containers") echo "未找到 NetMirror 容器" ;;
            "container_name") echo "容器名" ;;
            "quick_commands") echo "快速管理命令：" ;;
            "restart_container_cmd") echo "重启容器: sudo docker restart <容器名>" ;;
            "stop_container_cmd") echo "停止容器: sudo docker stop <容器名>" ;;
            "remove_container_cmd") echo "删除容器: sudo docker rm <容器名>" ;;
            "system_management") echo "系统管理" ;;
            *) echo "$key" ;;
        esac
    else
        case "$key" in
            "script_title") echo "NetMirror Deployment Script" ;;
            "basic_tools") echo "Basic Tools" ;;
            "master_management") echo "Master Node Management" ;;
            "child_management") echo "Child Node Management" ;;
            "check_docker") echo "Docker Setup" ;;
            "edit_config") echo "Edit Config" ;;
            "install_master") echo "Install Master" ;;
            "restart_master") echo "Restart Master" ;;
            "status_master") echo "Master Status" ;;
            "remove_master") echo "Remove Master" ;;
            "install_child") echo "Install Child" ;;
            "restart_child") echo "Restart Child" ;;
            "status_child") echo "Child Status" ;;
            "remove_child") echo "Remove Child" ;;
            "show_all") echo "All Containers" ;;
            "exit_program") echo "Exit Program" ;;
            "select_option") echo "Please select an option" ;;
            "press_enter") echo "Press Enter to continue..." ;;
            "invalid_choice") echo "Invalid choice, please enter 0-11" ;;
            "thanks") echo "Thank you for using NetMirror deployment script!" ;;
            "need_root") echo "This script requires root privileges" ;;
            "use_sudo") echo "Please use: sudo $0" ;;
            "need_interactive") echo "This script needs to run in an interactive terminal" ;;
            "docker_installed") echo "Docker is installed" ;;
            "docker_not_found") echo "Docker not found. Installing Docker..." ;;
            "docker_installing") echo "Checking Docker installation status..." ;;
            "docker_complete") echo "Docker installation complete!" ;;
            "docker_ready") echo "Docker is ready" ;;
            "relogin_required") echo "Please logout and login again, or run: newgrp docker" ;;
            "docker_test_success") echo "Docker test successful" ;;
            "docker_test_failed") echo "Docker test failed, please check installation" ;;
            "config_edit") echo "Configuration File Editor" ;;
            "install_node_first") echo "Please install a node first before editing configuration" ;;
            "found_config_dirs") echo "Found the following configuration directories:" ;;
            "unknown_node") echo "Unknown node" ;;
            "unknown_port") echo "Unknown port" ;;
            "port_label") echo "Port" ;;
            "return_main_menu") echo "Return to main menu" ;;
            "select_config_file") echo "Please select a configuration file to edit" ;;
            "editing_config") echo "Editing configuration file" ;;
            "no_text_editor") echo "No text editor found (nano, vim, vi)" ;;
            "config_edited") echo "Configuration file has been edited" ;;
            "restart_container_prompt") echo "Restart the corresponding container to apply changes? [y/N]" ;;
            "restarting_container") echo "Restarting container" ;;
            "container_restart_success") echo "Container restarted successfully" ;;
            "container_restart_failed") echo "Container restart failed" ;;
            "invalid_selection") echo "Invalid selection" ;;
            "install_master_title") echo "Install Master Node" ;;
            "node_name_prompt") echo "Node name (e.g., Master Node)" ;;
            "node_location_prompt") echo "Node location (e.g., Beijing, China)" ;;
            "http_port_prompt") echo "HTTP port [3000]" ;;
            "custom_url_prompt") echo "Custom access URL (optional, for reverse proxy)" ;;
            "generating_api_key") echo "Generating management API key for master node..." ;;
            "api_key_label") echo "API Key" ;;
            "save_api_key") echo "Please save this key safely, child nodes will need it for connection" ;;
            "creating_deploy_dir") echo "Creating deployment directory" ;;
            "creating_config") echo "Creating configuration file..." ;;
            "starting_container") echo "Starting container..." ;;
            "master_install_success") echo "Master node installed successfully!" ;;
            "node_info") echo "Node Information:" ;;
            "name_label") echo "Name" ;;
            "location_label") echo "Location" ;;
            "access_url") echo "Access URL" ;;
            "admin_panel") echo "Admin Panel: Click the settings icon in bottom right (⚙️)" ;;
            "deploy_path") echo "Deployment Path" ;;
            "admin_api_key") echo "Administrator API Key:" ;;
            "child_connect_info") echo "Child Node Connection Info:" ;;
            "master_address") echo "Master Node Address" ;;
            "container_start_failed") echo "Container startup failed" ;;
            "check_logs") echo "Check logs" ;;
            "install_child_title") echo "Install Child Node" ;;
            "master_connect_info") echo "Master Node Connection Information" ;;
            "master_url_prompt") echo "Master node URL (e.g., http://master-ip:3000)" ;;
            "admin_api_key_prompt") echo "Administrator API key" ;;
            "verifying_master") echo "Verifying master node connection..." ;;
            "cannot_connect_master") echo "Cannot connect to master node" ;;
            "verifying_api_key") echo "Verifying API key..." ;;
            "api_key_valid") echo "API key verification successful" ;;
            "api_key_invalid") echo "API key is invalid" ;;
            "connection_failed") echo "Connection failed" ;;
            "api_verification_continue") echo "API verification returned HTTP $response, continuing installation..." ;;
            "child_config") echo "Child Node Configuration" ;;
            "child_node_name_prompt") echo "Node name (e.g., Shanghai Node)" ;;
            "child_node_location_prompt") echo "Node location (e.g., Shanghai, China)" ;;
            "child_port_prompt") echo "HTTP port [3001]" ;;
            "child_install_success") echo "Child node installed successfully!" ;;
            "registering_to_master") echo "Attempting to register with master node..." ;;
            "register_success") echo "Successfully registered with master node" ;;
            "node_exists") echo "Node already exists in master node" ;;
            "register_failed") echo "Automatic registration failed (HTTP $register_response), please add manually" ;;
            "master_node_label") echo "Master Node" ;;
            "restart_node_title") echo "Restart" ;;
            "node_label") echo "Node" ;;
            "no_running_containers") echo "No running" ;;
            "found_containers") echo "Found the following" ;;
            "containers_label") echo "node containers:" ;;
            "unknown_status") echo "unknown" ;;
            "select_container_restart") echo "Please select a container to restart" ;;
            "restarting_container_name") echo "Restarting container" ;;
            "node_status_title") echo "Node Status" ;;
            "no_containers_found") echo "No" ;;
            "container_label") echo "Container" ;;
            "status_label") echo "Status" ;;
            "node_name_label") echo "Node Name" ;;
            "created_time") echo "Created Time" ;;
            "management_commands") echo "Management Commands:" ;;
            "view_logs") echo "View logs: sudo docker logs -f <container_name>" ;;
            "enter_container") echo "Enter container: sudo docker exec -it <container_name> /bin/sh" ;;
            "remove_node_title") echo "Remove" ;;
            "select_container_remove") echo "Please select a container to remove" ;;
            "removing_container") echo "About to remove container" ;;
            "confirm_delete") echo "Confirm deletion? This operation cannot be undone [y/N]" ;;
            "stopping_removing") echo "Stopping and removing container" ;;
            "delete_deploy_dir") echo "Delete deployment directory" ;;
            "deploy_dir_deleted") echo "Deployment directory deleted" ;;
            "container_removed") echo "Container has been removed" ;;
            "operation_cancelled") echo "Operation cancelled" ;;
            "all_containers_title") echo "All NetMirror Containers" ;;
            "no_netmirror_containers") echo "No NetMirror containers found" ;;
            "container_name") echo "Container Name" ;;
            "quick_commands") echo "Quick Management Commands:" ;;
            "restart_container_cmd") echo "Restart container: sudo docker restart <container_name>" ;;
            "stop_container_cmd") echo "Stop container: sudo docker stop <container_name>" ;;
            "remove_container_cmd") echo "Remove container: sudo docker rm <container_name>" ;;
            "system_management") echo "System Management" ;;
            *) echo "$key" ;;
        esac
    fi
}

# Logging functions
log() { 
    if [[ "$LANG_CN" == "true" ]]; then
        echo -e "${BLUE}[信息]${NC} $1"
    else
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

success() { 
    if [[ "$LANG_CN" == "true" ]]; then
        echo -e "${GREEN}[成功]${NC} $1"
    else
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    fi
}

warn() { 
    if [[ "$LANG_CN" == "true" ]]; then
        echo -e "${YELLOW}[警告]${NC} $1"
    else
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}

error() { 
    if [[ "$LANG_CN" == "true" ]]; then
        echo -e "${RED}[错误]${NC} $1"
    else
        echo -e "${RED}[ERROR]${NC} $1"
    fi
}

# Generate secure random API key
generate_api_key() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 32
    elif command -v head &> /dev/null && [[ -r /dev/urandom ]]; then
        head -c 32 /dev/urandom | xxd -p -c 32
    else
        echo "netmirror-$(date +%s)-$(hostname | head -c 8)" | tr -d '\n'
    fi
}

# Clear screen and show header
show_header() {
    clear
    
    # Modern clean header
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                    🌐 $(text "script_title")${NC}"
    echo -e "${YELLOW}                   github.com/catcat-blog/NetMirror${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    # Language-aware formatting
    if [[ "$LANG_CN" == "true" ]]; then
        # Chinese layout with adjusted spacing for CJK characters
        echo -e "${GREEN}┌─ 🔧 $(text "basic_tools") ─────────────────────────────────────────────────────┐${NC}"
        printf "${GREEN}│${NC}  ${WHITE}[1]${NC} %-12s            ${WHITE}[2]${NC} %-12s            ${GREEN}│${NC}\n" "$(text "check_docker")" "$(text "edit_config")"
        echo -e "${GREEN}└──────────────────────────────────────────────────────────────────────┘${NC}"
        echo

        echo -e "${PURPLE}┌─ 🌟 $(text "master_management") ────────────────────────────────────────────┐${NC}"
        printf "${PURPLE}│${NC}  ${WHITE}[3]${NC} %-12s            ${WHITE}[4]${NC} %-12s            ${PURPLE}│${NC}\n" "$(text "install_master")" "$(text "restart_master")"
        printf "${PURPLE}│${NC}  ${WHITE}[5]${NC} %-12s            ${WHITE}[6]${NC} %-12s            ${PURPLE}│${NC}\n" "$(text "status_master")" "$(text "remove_master")"
        echo -e "${PURPLE}└──────────────────────────────────────────────────────────────────────┘${NC}"
        echo

        echo -e "${CYAN}┌─ 🔗 $(text "child_management") ─────────────────────────────────────────────┐${NC}"
        printf "${CYAN}│${NC}  ${WHITE}[7]${NC} %-12s            ${WHITE}[8]${NC} %-12s            ${CYAN}│${NC}\n" "$(text "install_child")" "$(text "restart_child")"
        printf "${CYAN}│${NC}  ${WHITE}[9]${NC} %-12s            ${WHITE}[10]${NC} %-11s            ${CYAN}│${NC}\n" "$(text "status_child")" "$(text "remove_child")"
        echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────┘${NC}"
        echo

        echo -e "${YELLOW}┌─ 📋 $(text "system_management") ────────────────────────────────────────────────┐${NC}"
        printf "${YELLOW}│${NC}  ${WHITE}[11]${NC} %-11s            ${WHITE}[0]${NC} %-13s            ${YELLOW}│${NC}\n" "$(text "show_all")" "$(text "exit_program")"
        echo -e "${YELLOW}└──────────────────────────────────────────────────────────────────────┘${NC}"
    else
        # English layout
        echo -e "${GREEN}┌─ 🔧 $(text "basic_tools") ─────────────────────────────────────────────────────┐${NC}"
        printf "${GREEN}│${NC}  ${WHITE}[1]${NC} %-18s      ${WHITE}[2]${NC} %-18s      ${GREEN}│${NC}\n" "$(text "check_docker")" "$(text "edit_config")"
        echo -e "${GREEN}└──────────────────────────────────────────────────────────────────────┘${NC}"
        echo

        echo -e "${PURPLE}┌─ 🌟 $(text "master_management") ────────────────────────────────────────────┐${NC}"
        printf "${PURPLE}│${NC}  ${WHITE}[3]${NC} %-18s      ${WHITE}[4]${NC} %-18s      ${PURPLE}│${NC}\n" "$(text "install_master")" "$(text "restart_master")"
        printf "${PURPLE}│${NC}  ${WHITE}[5]${NC} %-18s      ${WHITE}[6]${NC} %-18s      ${PURPLE}│${NC}\n" "$(text "status_master")" "$(text "remove_master")"
        echo -e "${PURPLE}└──────────────────────────────────────────────────────────────────────┘${NC}"
        echo

        echo -e "${CYAN}┌─ 🔗 $(text "child_management") ─────────────────────────────────────────────┐${NC}"
        printf "${CYAN}│${NC}  ${WHITE}[7]${NC} %-18s      ${WHITE}[8]${NC} %-18s      ${CYAN}│${NC}\n" "$(text "install_child")" "$(text "restart_child")"
        printf "${CYAN}│${NC}  ${WHITE}[9]${NC} %-18s      ${WHITE}[10]${NC} %-17s      ${CYAN}│${NC}\n" "$(text "status_child")" "$(text "remove_child")"
        echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────┘${NC}"
        echo

        echo -e "${YELLOW}┌─ 📋 $(text "system_management") ────────────────────────────────────────────────┐${NC}"
        printf "${YELLOW}│${NC}  ${WHITE}[11]${NC} %-17s      ${WHITE}[0]${NC} %-18s      ${YELLOW}│${NC}\n" "$(text "show_all")" "$(text "exit_program")"
        echo -e "${YELLOW}└──────────────────────────────────────────────────────────────────────┘${NC}"
    fi
    
    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Pause function
pause() {
    echo
    read -p "$(text "press_enter")" -r
}

# Check if Docker is installed
check_docker_installed() {
    if command -v docker &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Install Docker
install_docker() {
    echo -e "${YELLOW}$(text "docker_installing")${NC}"
    
    if check_docker_installed; then
        success "$(text "docker_installed")"
        docker --version
        return 0
    fi
    
    warn "$(text "docker_not_found")"
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        if [[ "$LANG_CN" == "true" ]]; then
            error "无法检测操作系统"
        else
            error "Cannot detect operating system"
        fi
        return 1
    fi
    
    case "$OS" in
        ubuntu|debian)
            if [[ "$LANG_CN" == "true" ]]; then
                log "检测到 Ubuntu/Debian 系统，使用 apt 安装..."
            else
                log "Detected Ubuntu/Debian system, installing with apt..."
            fi
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Set up repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        centos|rhel|rocky|almalinux)
            if [[ "$LANG_CN" == "true" ]]; then
                log "检测到 CentOS/RHEL 系统，使用 yum/dnf 安装..."
            else
                log "Detected CentOS/RHEL system, installing with yum/dnf..."
            fi
            if command -v dnf &> /dev/null; then
                sudo dnf install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            else
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            fi
            ;;
        *)
            if [[ "$LANG_CN" == "true" ]]; then
                warn "未识别的系统，尝试使用官方安装脚本..."
            else
                warn "Unrecognized system, trying official installation script..."
            fi
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            rm get-docker.sh
            ;;
    esac
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    success "$(text "docker_complete")"
    warn "$(text "relogin_required")"
    
    # Test Docker
    if sudo docker run --rm hello-world &> /dev/null; then
        success "$(text "docker_test_success")"
    else
        warn "$(text "docker_test_failed")"
    fi
}

# Edit configuration files
edit_config() {
    echo -e "${YELLOW}$(text "config_edit")${NC}"
    echo
    
    # List available config files
    config_dirs=()
    if [[ -d "$DEPLOY_BASE" ]]; then
        for dir in "$DEPLOY_BASE"/*; do
            if [[ -d "$dir" && -f "$dir/.env" ]]; then
                config_dirs+=("$dir")
            fi
        done
    fi
    
    if [[ ${#config_dirs[@]} -eq 0 ]]; then
        warn "$(text "install_node_first")"
        return 1
    fi
    
    echo "$(text "found_config_dirs")"
    for i in "${!config_dirs[@]}"; do
        dir="${config_dirs[$i]}"
        node_name=$(grep "^LG_CURRENT_NAME=" "$dir/.env" 2>/dev/null | cut -d'=' -f2 || echo "$(text "unknown_node")")
        port=$(grep "^HTTP_PORT=" "$dir/.env" 2>/dev/null | cut -d'=' -f2 || echo "$(text "unknown_port")")
        echo "  [$((i+1))] $node_name ($(text "port_label"): $port) - $dir"
    done
    echo "  [0] $(text "return_main_menu")"
    echo
    
    read -p "$(text "select_config_file"): " choice
    
    if [[ "$choice" == "0" ]]; then
        return 0
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -gt 0 ]] && [[ "$choice" -le ${#config_dirs[@]} ]]; then
        config_dir="${config_dirs[$((choice-1))]}"
        config_file="$config_dir/.env"
        
        log "$(text "editing_config"): $config_file"
        
        # Choose editor
        if command -v nano &> /dev/null; then
            nano "$config_file"
        elif command -v vim &> /dev/null; then
            vim "$config_file"
        elif command -v vi &> /dev/null; then
            vi "$config_file"
        else
            error "$(text "no_text_editor")"
            return 1
        fi
        
        success "$(text "config_edited")"
        
        # Ask if restart container
        echo
        read -p "$(text "restart_container_prompt"): " restart_choice
        if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
            container_name=$(basename "$config_dir")
            log "$(text "restarting_container"): $container_name"
            if docker restart "$container_name" &> /dev/null; then
                success "$(text "container_restart_success")"
            else
                error "$(text "container_restart_failed")"
            fi
        fi
    else
        error "$(text "invalid_selection")"
    fi
}

# Install master node
install_master_node() {
    echo -e "${YELLOW}$(text "install_master_title")${NC}"
    echo
    
    # Get node information
    read -p "$(text "node_name_prompt"): " node_name
    read -p "$(text "node_location_prompt"): " node_location
    read -p "$(text "http_port_prompt"): " port
    port=${port:-3000}
    
    read -p "$(text "custom_url_prompt"): " custom_url
    
    # Generate API key
    echo
    echo "$(text "generating_api_key")"
    api_key=$(generate_api_key)
    success "$(text "api_key_label"): $api_key"
    echo
    warn "$(text "save_api_key")"
    
    # Create deployment directory
    deploy_dir="$DEPLOY_BASE/master-$port"
    container_name="netmirror-master-$port"
    
    log "$(text "creating_deploy_dir"): $deploy_dir"
    sudo mkdir -p "$deploy_dir/data"
    
    # Download and create .env file
    log "$(text "creating_config")"
    
    # Get local IP
    local_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    # Create .env file
    sudo tee "$deploy_dir/.env" > /dev/null << EOF
# NetMirror 主节点配置
# 生成时间: $(date)

# 基础配置
LISTEN_IP=0.0.0.0
HTTP_PORT=$port
LOCATION=$node_location
LG_CURRENT_NAME=$node_name
LG_CURRENT_LOCATION=$node_location
LG_CURRENT_URL=${custom_url:-http://$local_ip:$port}

# 功能配置
DISPLAY_TRAFFIC=true
ENABLE_SPEEDTEST=true
UTILITIES_PING=true
UTILITIES_MTR=true
UTILITIES_TRACEROUTE=true
UTILITIES_SPEEDTESTDOTNET=true
UTILITIES_FAKESHELL=true
UTILITIES_IPERF3=true
SPEEDTEST_FILE_LIST=100MB 1GB 10GB
UTILITIES_IPERF3_PORT_MIN=30000
UTILITIES_IPERF3_PORT_MAX=31000

# 管理员 API 配置
ADMIN_API_KEY=$api_key
DATA_DIR=/data

# 清空默认节点配置
LG_NODES=
EOF
    
    # Create docker-compose.yml
    sudo tee "$deploy_dir/docker-compose.yml" > /dev/null << EOF
version: '3.3'

services:
  netmirror:
    image: $IMAGE
    container_name: $container_name
    restart: always
    network_mode: host
    env_file:
      - .env
    volumes:
      - ./data:/data
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:$port/"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF
    
    # Start container
    log "$(text "starting_container")"
    cd "$deploy_dir"
    
    # Pull latest image
    sudo docker pull "$IMAGE"
    
    # Start with docker compose
    if command -v docker &> /dev/null && sudo docker compose version &> /dev/null; then
        sudo docker compose up -d
    elif command -v docker-compose &> /dev/null; then
        sudo docker-compose up -d
    else
        # Fallback to docker run
        sudo docker run -d \
            --name "$container_name" \
            --restart always \
            --network host \
            --env-file .env \
            -v "$(pwd)/data:/data" \
            --health-cmd="wget --quiet --tries=1 --spider http://localhost:$port/" \
            --health-interval=30s \
            --health-timeout=10s \
            --health-retries=3 \
            --log-driver json-file \
            --log-opt max-size=10m \
            --log-opt max-file=3 \
            "$IMAGE"
    fi
    
    # Wait for startup
    sleep 5
    
    if sudo docker ps | grep -q "$container_name"; then
        success "$(text "master_install_success")"
        echo
        echo -e "${GREEN}$(text "node_info")${NC}"
        echo "  $(text "name_label"): $node_name"
        echo "  $(text "location_label"): $node_location"
        echo "  $(text "access_url"): http://localhost:$port"
        echo "  $(text "admin_panel")"
        echo "  $(text "deploy_path"): $deploy_dir"
        echo
        echo -e "${YELLOW}$(text "admin_api_key")${NC}"
        echo "  $api_key"
        echo
        echo -e "${BLUE}$(text "child_connect_info")${NC}"
        echo "  $(text "master_address"): ${custom_url:-http://$local_ip:$port}"
        echo "  $(text "api_key_label"): $api_key"
    else
        error "$(text "container_start_failed")"
        log "$(text "check_logs"): sudo docker logs $container_name"
    fi
}

# Install child node
install_child_node() {
    echo -e "${YELLOW}$(text "install_child_title")${NC}"
    echo
    
    # Get master node information
    echo -e "${CYAN}$(text "master_connect_info")${NC}"
    read -p "$(text "master_url_prompt"): " master_url
    read -p "$(text "admin_api_key_prompt"): " admin_key
    
    # Verify master node
    echo
    log "$(text "verifying_master")"
    if ! curl -s --connect-timeout 10 "$master_url/" >/dev/null 2>&1; then
        error "$(text "cannot_connect_master"): $master_url"
        return 1
    fi
    
    # Verify API key
    log "$(text "verifying_api_key")"
    admin_key=$(echo "$admin_key" | tr -d '\r\n\t ')
    response=$(curl -s -w "%{http_code}" -o /dev/null "$master_url/api/admin/nodes/add?api_key=$admin_key" 2>/dev/null || echo "000")
    
    if [[ "$response" == "400" ]]; then
        success "$(text "api_key_valid")"
    elif [[ "$response" == "401" ]]; then
        error "$(text "api_key_invalid")"
        return 1
    elif [[ "$response" == "000" ]]; then
        error "$(text "connection_failed")"
        return 1
    else
        if [[ "$LANG_CN" == "true" ]]; then
            warn "API 验证返回 HTTP $response，继续安装..."
        else
            warn "API verification returned HTTP $response, continuing installation..."
        fi
    fi
    
    echo
    echo -e "${CYAN}$(text "child_config")${NC}"
    read -p "$(text "child_node_name_prompt"): " node_name
    read -p "$(text "child_node_location_prompt"): " node_location
    read -p "$(text "child_port_prompt"): " port
    port=${port:-3001}
    
    read -p "$(text "custom_url_prompt"): " custom_url
    
    # Create deployment directory
    deploy_dir="$DEPLOY_BASE/child-$port"
    container_name="netmirror-child-$port"
    
    log "$(text "creating_deploy_dir"): $deploy_dir"
    sudo mkdir -p "$deploy_dir/data"
    
    # Get local IP
    local_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    # Create .env file
    sudo tee "$deploy_dir/.env" > /dev/null << EOF
# NetMirror 子节点配置
# 生成时间: $(date)

# 基础配置
LISTEN_IP=0.0.0.0
HTTP_PORT=$port
LOCATION=$node_location
LG_CURRENT_NAME=$node_name
LG_CURRENT_LOCATION=$node_location
LG_CURRENT_URL=${custom_url:-http://$local_ip:$port}

# 功能配置
DISPLAY_TRAFFIC=true
ENABLE_SPEEDTEST=true
UTILITIES_PING=true
UTILITIES_MTR=true
UTILITIES_TRACEROUTE=true
UTILITIES_SPEEDTESTDOTNET=true
UTILITIES_FAKESHELL=true
UTILITIES_IPERF3=true
SPEEDTEST_FILE_LIST=100MB 1GB 10GB
UTILITIES_IPERF3_PORT_MIN=30000
UTILITIES_IPERF3_PORT_MAX=31000

# 主节点集成
MASTER_NODE_URL=$master_url
NODE_AUTO_REGISTER=true
ADMIN_API_KEY=$admin_key
DATA_DIR=/data

# 清空默认节点配置
LG_NODES=
EOF
    
    # Create docker-compose.yml
    sudo tee "$deploy_dir/docker-compose.yml" > /dev/null << EOF
version: '3.3'

services:
  netmirror:
    image: $IMAGE
    container_name: $container_name
    restart: always
    network_mode: host
    env_file:
      - .env
    volumes:
      - ./data:/data
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:$port/"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF
    
    # Start container
    log "$(text "starting_container")"
    cd "$deploy_dir"
    
    # Pull latest image
    sudo docker pull "$IMAGE"
    
    # Start with docker compose
    if command -v docker &> /dev/null && sudo docker compose version &> /dev/null; then
        sudo docker compose up -d
    elif command -v docker-compose &> /dev/null; then
        sudo docker-compose up -d
    else
        # Fallback to docker run
        sudo docker run -d \
            --name "$container_name" \
            --restart always \
            --network host \
            --env-file .env \
            -v "$(pwd)/data:/data" \
            --health-cmd="wget --quiet --tries=1 --spider http://localhost:$port/" \
            --health-interval=30s \
            --health-timeout=10s \
            --health-retries=3 \
            --log-driver json-file \
            --log-opt max-size=10m \
            --log-opt max-file=3 \
            "$IMAGE"
    fi
    
    # Wait for startup
    sleep 5
    
    if sudo docker ps | grep -q "$container_name"; then
        success "$(text "child_install_success")"
        
        # Try to register with master node
        echo
        log "$(text "registering_to_master")"
        
        node_url="${custom_url:-http://$local_ip:$port}"
        encoded_name=$(printf '%s' "$node_name" | sed 's/ /+/g')
        encoded_location=$(printf '%s' "$node_location" | sed 's/ /+/g')
        
        register_response=$(curl -s -w "%{http_code}" -o /tmp/register_response \
            "$master_url/api/admin/nodes/add?api_key=$admin_key&name=$encoded_name&location=$encoded_location&url=$node_url" 2>/dev/null || echo "000")
        
        if [[ "$register_response" == "201" ]] || [[ "$register_response" == "200" ]]; then
            success "$(text "register_success")"
        elif [[ "$register_response" == "409" ]]; then
            warn "$(text "node_exists")"
        else
            if [[ "$LANG_CN" == "true" ]]; then
                warn "自动注册失败 (HTTP $register_response)，请手动添加"
            else
                warn "Automatic registration failed (HTTP $register_response), please add manually"
            fi
        fi
        
        rm -f /tmp/register_response
        
        echo
        echo -e "${GREEN}$(text "node_info")${NC}"
        echo "  $(text "name_label"): $node_name"
        echo "  $(text "location_label"): $node_location"
        echo "  $(text "access_url"): http://localhost:$port"
        echo "  $(text "master_node_label"): $master_url"
        echo "  $(text "deploy_path"): $deploy_dir"
    else
        error "$(text "container_start_failed")"
        log "$(text "check_logs"): sudo docker logs $container_name"
    fi
}

# Restart node
restart_node() {
    local node_type="$1"
    echo -e "${YELLOW}$(text "restart_node_title") ${node_type} $(text "node_label")${NC}"
    echo
    
    # List running containers
    containers=($(sudo docker ps --format "{{.Names}}" | grep "netmirror-$node_type" | sort))
    
    if [[ ${#containers[@]} -eq 0 ]]; then
        warn "$(text "no_running_containers") ${node_type} $(text "node_label") $(text "container_label")"
        return 1
    fi
    
    echo "$(text "found_containers") ${node_type} $(text "containers_label")"
    for i in "${!containers[@]}"; do
        container="${containers[$i]}"
        port=$(sudo docker inspect "$container" --format '{{range .NetworkSettings.Ports}}{{range .}}{{.HostPort}}{{end}}{{end}}' 2>/dev/null || echo "$(text "unknown_status")")
        echo "  [$((i+1))] $container ($(text "port_label"): $port)"
    done
    echo "  [0] $(text "return_main_menu")"
    echo
    
    read -p "$(text "select_container_restart"): " choice
    
    if [[ "$choice" == "0" ]]; then
        return 0
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -gt 0 ]] && [[ "$choice" -le ${#containers[@]} ]]; then
        container="${containers[$((choice-1))]}"
        log "$(text "restarting_container_name"): $container"
        
        if sudo docker restart "$container" &> /dev/null; then
            success "$(text "container_restart_success")"
        else
            error "$(text "container_restart_failed")"
        fi
    else
        error "$(text "invalid_selection")"
    fi
}

# Show node status
show_node_status() {
    local node_type="$1"
    echo -e "${YELLOW}${node_type} $(text "node_status_title")${NC}"
    echo
    
    # List containers
    containers=($(sudo docker ps -a --format "{{.Names}}" | grep "netmirror-$node_type" | sort))
    
    if [[ ${#containers[@]} -eq 0 ]]; then
        warn "$(text "no_containers_found") ${node_type} $(text "node_label") $(text "container_label")"
        return 1
    fi
    
    for container in "${containers[@]}"; do
        echo -e "${CYAN}$(text "container_label"): $container${NC}"
        
        # Get container info
        status=$(sudo docker inspect "$container" --format '{{.State.Status}}' 2>/dev/null || echo "$(text "unknown_status")")
        created=$(sudo docker inspect "$container" --format '{{.Created}}' 2>/dev/null | cut -d'T' -f1 || echo "$(text "unknown_status")")
        
        # Get port from environment
        port=$(sudo docker inspect "$container" --format '{{range .Config.Env}}{{if eq (index (split . "=") 0) "HTTP_PORT"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null || echo "$(text "unknown_status")")
        
        # Get node name from environment
        node_name=$(sudo docker inspect "$container" --format '{{range .Config.Env}}{{if eq (index (split . "=") 0) "LG_CURRENT_NAME"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null || echo "$(text "unknown_status")")
        
        echo "  $(text "status_label"): $status"
        echo "  $(text "port_label"): $port"
        echo "  $(text "node_name_label"): $node_name"
        echo "  $(text "created_time"): $created"
        
        if [[ "$status" == "running" ]]; then
            echo -e "  $(text "access_url"): ${GREEN}http://localhost:$port${NC}"
        fi
        
        echo
    done
    
    echo "$(text "management_commands")"
    echo "  $(text "view_logs")"
    echo "  $(text "enter_container")"
    echo
}

# Remove node
remove_node() {
    local node_type="$1"
    echo -e "${YELLOW}$(text "remove_node_title") ${node_type} $(text "node_label")${NC}"
    echo
    
    # List containers
    containers=($(sudo docker ps -a --format "{{.Names}}" | grep "netmirror-$node_type" | sort))
    
    if [[ ${#containers[@]} -eq 0 ]]; then
        warn "$(text "no_containers_found") ${node_type} $(text "node_label") $(text "container_label")"
        return 1
    fi
    
    echo "$(text "found_containers") ${node_type} $(text "containers_label")"
    for i in "${!containers[@]}"; do
        container="${containers[$i]}"
        status=$(sudo docker inspect "$container" --format '{{.State.Status}}' 2>/dev/null || echo "$(text "unknown_status")")
        port=$(sudo docker inspect "$container" --format '{{range .Config.Env}}{{if eq (index (split . "=") 0) "HTTP_PORT"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null || echo "$(text "unknown_status")")
        echo "  [$((i+1))] $container ($(text "status_label"): $status, $(text "port_label"): $port)"
    done
    echo "  [0] $(text "return_main_menu")"
    echo
    
    read -p "$(text "select_container_remove"): " choice
    
    if [[ "$choice" == "0" ]]; then
        return 0
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -gt 0 ]] && [[ "$choice" -le ${#containers[@]} ]]; then
        container="${containers[$((choice-1))]}"
        
        echo
        warn "$(text "removing_container"): $container"
        read -p "$(text "confirm_delete"): " confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log "$(text "stopping_removing"): $container"
            
            # Stop and remove container
            sudo docker stop "$container" &> /dev/null || true
            sudo docker rm "$container" &> /dev/null
            
            # Find and remove deployment directory
            deploy_dir=""
            if [[ "$node_type" == "master" ]]; then
                deploy_dir="$DEPLOY_BASE/master-*"
            else
                deploy_dir="$DEPLOY_BASE/child-*"
            fi
            
            for dir in $deploy_dir; do
                if [[ -d "$dir" ]] && grep -q "container_name: $container" "$dir/docker-compose.yml" 2>/dev/null; then
                    echo
                    read -p "$(text "delete_deploy_dir") $dir? [y/N]: " delete_dir
                    if [[ "$delete_dir" =~ ^[Yy]$ ]]; then
                        sudo rm -rf "$dir"
                        success "$(text "deploy_dir_deleted")"
                    fi
                    break
                fi
            done
            
            success "$(text "container_removed")"
        else
            log "$(text "operation_cancelled")"
        fi
    else
        error "$(text "invalid_selection")"
    fi
}

# Show all containers
show_all_containers() {
    echo -e "${YELLOW}$(text "all_containers_title")${NC}"
    echo
    
    containers=($(sudo docker ps -a --format "{{.Names}}" | grep "netmirror" | sort))
    
    if [[ ${#containers[@]} -eq 0 ]]; then
        warn "$(text "no_netmirror_containers")"
        return 1
    fi
    
    if [[ "$LANG_CN" == "true" ]]; then
        printf "%-25s %-12s %-8s %-15s %-20s\n" "容器名" "状态" "端口" "节点名" "创建时间"
    else
        printf "%-25s %-12s %-8s %-15s %-20s\n" "Container Name" "Status" "Port" "Node Name" "Created Time"
    fi
    echo "--------------------------------------------------------------------------------------------------------"
    
    for container in "${containers[@]}"; do
        status=$(sudo docker inspect "$container" --format '{{.State.Status}}' 2>/dev/null || echo "$(text "unknown_status")")
        port=$(sudo docker inspect "$container" --format '{{range .Config.Env}}{{if eq (index (split . "=") 0) "HTTP_PORT"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null || echo "$(text "unknown_status")")
        node_name=$(sudo docker inspect "$container" --format '{{range .Config.Env}}{{if eq (index (split . "=") 0) "LG_CURRENT_NAME"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null || echo "$(text "unknown_status")")
        created=$(sudo docker inspect "$container" --format '{{.Created}}' 2>/dev/null | cut -d'T' -f1 || echo "$(text "unknown_status")")
        
        # Truncate long names
        if [[ ${#node_name} -gt 15 ]]; then
            node_name="${node_name:0:12}..."
        fi
        
        printf "%-25s %-12s %-8s %-15s %-20s\n" "$container" "$status" "$port" "$node_name" "$created"
    done
    
    echo
    echo "$(text "quick_commands")"
    echo "  $(text "view_logs")"
    echo "  $(text "restart_container_cmd")"
    echo "  $(text "stop_container_cmd")"
    echo "  $(text "remove_container_cmd")"
}

# Main menu loop
main_menu() {
    while true; do
        show_header
        
        read -p "$(text "select_option") [0-11]: " choice
        
        case $choice in
            1)
                clear
                echo -e "${CYAN}=== $(text "check_docker") ===${NC}"
                install_docker
                pause
                ;;
            2)
                clear
                echo -e "${CYAN}=== $(text "edit_config") ===${NC}"
                edit_config
                pause
                ;;
            3)
                clear
                echo -e "${CYAN}=== $(text "install_master") ===${NC}"
                install_master_node
                pause
                ;;
            4)
                clear
                echo -e "${CYAN}=== $(text "restart_master") ===${NC}"
                restart_node "master"
                pause
                ;;
            5)
                clear
                echo -e "${CYAN}=== $(text "status_master") ===${NC}"
                show_node_status "master"
                pause
                ;;
            6)
                clear
                echo -e "${CYAN}=== $(text "remove_master") ===${NC}"
                remove_node "master"
                pause
                ;;
            7)
                clear
                echo -e "${CYAN}=== $(text "install_child") ===${NC}"
                install_child_node
                pause
                ;;
            8)
                clear
                echo -e "${CYAN}=== $(text "restart_child") ===${NC}"
                restart_node "child"
                pause
                ;;
            9)
                clear
                echo -e "${CYAN}=== $(text "status_child") ===${NC}"
                show_node_status "child"
                pause
                ;;
            10)
                clear
                echo -e "${CYAN}=== $(text "remove_child") ===${NC}"
                remove_node "child"
                pause
                ;;
            11)
                clear
                echo -e "${CYAN}=== $(text "show_all") ===${NC}"
                show_all_containers
                pause
                ;;
            0)
                echo
                echo -e "${GREEN}$(text "thanks")${NC}"
                echo
                exit 0
                ;;
            *)
                echo
                error "$(text "invalid_choice")"
                sleep 2
                ;;
        esac
    done
}

# Check root permission
if [[ $EUID -ne 0 ]]; then
    error "$(text "need_root")"
    echo "$(text "use_sudo")"
    exit 1
fi

# Check if running in interactive terminal
if [[ ! -t 0 ]]; then
    error "$(text "need_interactive")"
    exit 1
fi

# Start main menu
main_menu
