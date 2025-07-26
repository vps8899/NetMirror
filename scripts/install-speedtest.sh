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
get_arch() {
    local arch=$(uname -m)
    case $arch in
        "x86_64")
            echo "x86_64"
            ;;
        "aarch64")
            echo "aarch64"
            ;;
        "armv7l")
            echo "armhf"
            ;;
        "i386"|"i686")
            echo "i386"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Install Speedtest CLI
install_speedtest() {
    local arch=$(get_arch)
    local version="1.2.0"
    local temp_dir=$(mktemp -d)
    local speedtest_url="https://install.speedtest.net/app/cli/ookla-speedtest-${version}-linux-${arch}.tgz"
    local install_path="/usr/local/bin/speedtest"
    
    log_info "Installing Speedtest CLI..."
    log_info "Architecture: $arch"
    log_info "Version: $version"
    log_info "Download URL: $speedtest_url"
    
    # Download speedtest
    log_info "Downloading Speedtest CLI..."
    if wget -O "$temp_dir/speedtest.tgz" "$speedtest_url" 2>/dev/null; then
        log_success "Download completed"
    else
        log_error "Failed to download Speedtest CLI"
        log_info "Trying alternative download method..."
        
        # Try with curl as fallback
        if curl -L -o "$temp_dir/speedtest.tgz" "$speedtest_url" 2>/dev/null; then
            log_success "Download completed with curl"
        else
            log_error "Failed to download with both wget and curl"
            rm -rf "$temp_dir"
            exit 1
        fi
    fi
    
    # Extract archive
    log_info "Extracting archive..."
    if tar -xzf "$temp_dir/speedtest.tgz" -C "$temp_dir"; then
        log_success "Archive extracted successfully"
    else
        log_error "Failed to extract archive"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Find speedtest binary
    local speedtest_binary=$(find "$temp_dir" -name "speedtest" -type f -executable | head -1)
    
    if [ -z "$speedtest_binary" ]; then
        log_error "Speedtest binary not found in archive"
        log_info "Archive contents:"
        ls -la "$temp_dir"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Install binary
    log_info "Installing binary to $install_path..."
    if cp "$speedtest_binary" "$install_path" && chmod +x "$install_path"; then
        log_success "Speedtest CLI installed successfully"
    else
        log_error "Failed to install Speedtest CLI binary"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Verify installation
    log_info "Verifying installation..."
    if command -v speedtest >/dev/null 2>&1; then
        local installed_version=$(speedtest --version 2>/dev/null | head -1)
        log_success "Speedtest CLI is available: $installed_version"
        
        # Accept license automatically for non-interactive use
        log_info "Accepting license agreement..."
        speedtest --accept-license --accept-gdpr >/dev/null 2>&1 || true
        
        return 0
    else
        log_error "Speedtest CLI installation verification failed"
        return 1
    fi
}

# Alternative installation methods
install_speedtest_alternative() {
    log_warning "Trying alternative installation methods..."
    
    # Method 1: Try different version
    local arch=$(get_arch)
    
    # Try version 1.1.1
    log_info "Trying version 1.1.1..."
    local url="https://install.speedtest.net/app/cli/ookla-speedtest-1.1.1-linux-${arch}.tgz"
    local temp_dir=$(mktemp -d)
    
    if wget -O "$temp_dir/speedtest.tgz" "$url" 2>/dev/null; then
        if tar -xzf "$temp_dir/speedtest.tgz" -C "$temp_dir" 2>/dev/null; then
            local binary=$(find "$temp_dir" -name "speedtest" -type f -executable | head -1)
            if [ -n "$binary" ]; then
                if cp "$binary" "/usr/local/bin/speedtest" && chmod +x "/usr/local/bin/speedtest"; then
                    log_success "Speedtest CLI installed successfully (version 1.1.1)"
                    rm -rf "$temp_dir"
                    return 0
                fi
            fi
        fi
    fi
    rm -rf "$temp_dir"
    
    # Try version 1.0.0
    log_info "Trying version 1.0.0..."
    url="https://install.speedtest.net/app/cli/ookla-speedtest-1.0.0-linux-${arch}.tgz"
    temp_dir=$(mktemp -d)
    
    if wget -O "$temp_dir/speedtest.tgz" "$url" 2>/dev/null; then
        if tar -xzf "$temp_dir/speedtest.tgz" -C "$temp_dir" 2>/dev/null; then
            local binary=$(find "$temp_dir" -name "speedtest" -type f -executable | head -1)
            if [ -n "$binary" ]; then
                if cp "$binary" "/usr/local/bin/speedtest" && chmod +x "/usr/local/bin/speedtest"; then
                    log_success "Speedtest CLI installed successfully (version 1.0.0)"
                    rm -rf "$temp_dir"
                    return 0
                fi
            fi
        fi
    fi
    rm -rf "$temp_dir"
    
    # Method 2: Try package manager installation
    log_info "Trying package manager installation..."
    
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        if curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash 2>/dev/null; then
            if apt-get install -y speedtest 2>/dev/null; then
                log_success "Speedtest CLI installed via apt"
                return 0
            fi
        fi
    elif command -v yum >/dev/null 2>&1; then
        # CentOS/RHEL
        if curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | bash 2>/dev/null; then
            if yum install -y speedtest 2>/dev/null; then
                log_success "Speedtest CLI installed via yum"
                return 0
            fi
        fi
    fi
    
    log_error "All alternative installation methods failed"
    return 1
}

# Main function
main() {
    log_info "Starting Speedtest CLI installation..."
    
    # Check if already installed
    if command -v speedtest >/dev/null 2>&1; then
        local current_version=$(speedtest --version 2>/dev/null | head -1)
        log_info "Speedtest CLI is already installed: $current_version"
        log_info "Skipping installation"
        return 0
    fi
    
    # Try main installation method
    if install_speedtest; then
        log_success "Speedtest CLI installation completed successfully"
        return 0
    fi
    
    # Try alternative methods
    if install_speedtest_alternative; then
        log_success "Speedtest CLI installation completed via alternative method"
        return 0
    fi
    
    log_error "Speedtest CLI installation failed"
    log_warning "The application will work without Speedtest CLI, but the speedtest.net feature will be disabled"
    return 1
}

# Run main function
main "$@"
