#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Architecture detection
fix_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        "aarch64")
            echo "arm64"
            ;;
        "x86_64")
            echo "amd64"
            ;;
        "armv7l")
            echo "armv7"
            ;;
        *)
            echo $ARCH
            ;;
    esac
}

# Generic GitHub release installer
install_from_github() {
    local OWNER=$1
    local PROJECT=$2
    local SAVE_AS=$3
    local ARCH=${4:-$(fix_arch)}
    local PATTERN=${5:-"linux.*$ARCH"}
    
    log_info "Installing $PROJECT from GitHub..."
    
    # Get latest release info
    local API_URL="https://api.github.com/repos/$OWNER/$PROJECT/releases/latest"
    local RELEASE_INFO=$(wget -qO - "$API_URL" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        log_error "Failed to fetch release information for $OWNER/$PROJECT"
        return 1
    fi
    
    # Extract download URL
    local DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*' | grep -E "$PATTERN" | head -1 | cut -d'"' -f4)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        log_warning "No suitable release found for $PROJECT (arch: $ARCH, pattern: $PATTERN)"
        return 1
    fi
    
    log_info "Downloading from: $DOWNLOAD_URL"
    
    # Create temporary directory
    local TEMP_DIR=$(mktemp -d)
    local TEMP_FILE="$TEMP_DIR/download"
    
    # Download file
    if wget -O "$TEMP_FILE" "$DOWNLOAD_URL" 2>/dev/null; then
        # Handle different file types
        case "$DOWNLOAD_URL" in
            *.tar.gz|*.tgz)
                tar -xzf "$TEMP_FILE" -C "$TEMP_DIR"
                # Find the binary (usually the largest executable file)
                local BINARY=$(find "$TEMP_DIR" -type f -executable | head -1)
                if [ -n "$BINARY" ]; then
                    cp "$BINARY" "$SAVE_AS"
                    chmod +x "$SAVE_AS"
                    log_success "Installed $PROJECT to $SAVE_AS"
                else
                    log_error "Could not find binary in archive for $PROJECT"
                    rm -rf "$TEMP_DIR"
                    return 1
                fi
                ;;
            *.zip)
                unzip -q "$TEMP_FILE" -d "$TEMP_DIR"
                local BINARY=$(find "$TEMP_DIR" -type f -executable | head -1)
                if [ -n "$BINARY" ]; then
                    cp "$BINARY" "$SAVE_AS"
                    chmod +x "$SAVE_AS"
                    log_success "Installed $PROJECT to $SAVE_AS"
                else
                    log_error "Could not find binary in archive for $PROJECT"
                    rm -rf "$TEMP_DIR"
                    return 1
                fi
                ;;
            *)
                # Assume it's a direct binary
                cp "$TEMP_FILE" "$SAVE_AS"
                chmod +x "$SAVE_AS"
                log_success "Installed $PROJECT to $SAVE_AS"
                ;;
        esac
    else
        log_error "Failed to download $PROJECT"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    return 0
}

# Install system packages
install_system_packages() {
    log_info "Installing system packages..."
    
    # Detect package manager and install packages
    if command -v apk >/dev/null 2>&1; then
        # Alpine Linux
        apk add --no-cache \
            iperf3 \
            mtr \
            traceroute \
            iputils \
            bind-tools \
            curl \
            wget \
            ca-certificates \
            tzdata
    elif command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        apt-get update
        apt-get install -y \
            iperf3 \
            mtr-tiny \
            traceroute \
            iputils-ping \
            dnsutils \
            curl \
            wget \
            ca-certificates \
            tzdata
    elif command -v yum >/dev/null 2>&1; then
        # CentOS/RHEL
        yum install -y \
            iperf3 \
            mtr \
            traceroute \
            iputils \
            bind-utils \
            curl \
            wget \
            ca-certificates \
            tzdata
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora
        dnf install -y \
            iperf3 \
            mtr \
            traceroute \
            iputils \
            bind-utils \
            curl \
            wget \
            ca-certificates \
            tzdata
    else
        log_warning "Unknown package manager, skipping system package installation"
        return 1
    fi
    
    log_success "System packages installed successfully"
}

# Install NextTrace
install_nexttrace() {
    log_info "Installing NextTrace..."
    
    local ARCH=$(fix_arch)
    local INSTALL_PATH="/usr/local/bin/nexttrace"
    
    # Try different repository names as the project might have moved
    local REPOS=("nxtrace/Ntrace-V1" "nxtrace/NTrace-core" "sjlleo/nexttrace")
    
    for repo in "${REPOS[@]}"; do
        log_info "Trying repository: $repo"
        if install_from_github "${repo%/*}" "${repo#*/}" "$INSTALL_PATH" "$ARCH" "linux.*$ARCH"; then
            log_success "NextTrace installed successfully from $repo"
            return 0
        fi
    done
    
    log_error "Failed to install NextTrace from any repository"
    return 1
}

# Install additional network tools
install_network_tools() {
    log_info "Installing additional network tools..."
    
    local ARCH=$(fix_arch)
    
    # Install gping (modern ping with graph)
    if install_from_github "orf" "gping" "/usr/local/bin/gping" "$ARCH" "linux.*$ARCH"; then
        log_success "gping installed successfully"
    else
        log_warning "Failed to install gping"
    fi
    
    # Install bandwhich (network utilization by process)
    if install_from_github "imsnif" "bandwhich" "/usr/local/bin/bandwhich" "$ARCH" "linux.*$ARCH"; then
        log_success "bandwhich installed successfully"
    else
        log_warning "Failed to install bandwhich"
    fi
    
    # Install dog (DNS lookup tool)
    if install_from_github "ogham" "dog" "/usr/local/bin/dog" "$ARCH" "linux.*$ARCH"; then
        log_success "dog installed successfully"
    else
        log_warning "Failed to install dog"
    fi
}

# Verify installations
verify_installations() {
    log_info "Verifying installations..."
    
    local tools=("iperf3" "mtr" "traceroute" "ping" "nexttrace")
    local failed=0
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "$tool is available"
        else
            log_error "$tool is not available"
            failed=$((failed + 1))
        fi
    done
    
    # Check optional tools
    local optional_tools=("gping" "bandwhich" "dog")
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "$tool is available (optional)"
        else
            log_warning "$tool is not available (optional)"
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_success "All required tools are available"
        return 0
    else
        log_error "$failed required tools are missing"
        return 1
    fi
}

# Main installation process
main() {
    log_info "Starting ALS software installation..."
    log_info "Architecture: $(fix_arch)"
    log_info "OS: $(uname -s)"
    
    # Install system packages
    if ! install_system_packages; then
        log_error "Failed to install system packages"
        exit 1
    fi
    
    # Install NextTrace
    install_nexttrace
    
    # Install additional network tools
    install_network_tools
    
    # Install Speedtest CLI
    if [ -f "install-speedtest.sh" ]; then
        log_info "Installing Speedtest CLI..."
        if bash install-speedtest.sh; then
            log_success "Speedtest CLI installed successfully"
        else
            log_warning "Failed to install Speedtest CLI"
        fi
    else
        log_warning "install-speedtest.sh not found, skipping Speedtest CLI installation"
    fi
    
    # Verify installations
    verify_installations
    
    log_success "ALS software installation completed!"
    log_info "You can now run the ALS server"
}

# Run main function
main "$@"
