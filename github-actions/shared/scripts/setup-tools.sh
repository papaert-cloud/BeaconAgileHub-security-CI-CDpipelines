#!/bin/bash
# Universal Security Tools Installation Script
# This script installs all necessary security and DevOps tools for both pipelines

set -euo pipefail

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

# Check if running on supported OS
check_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        ARCH=$(uname -m)
        case $ARCH in
            x86_64) ARCH="amd64" ;;
            aarch64) ARCH="arm64" ;;
            *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
        esac
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="darwin"
        ARCH=$(uname -m)
        case $ARCH in
            x86_64) ARCH="amd64" ;;
            arm64) ARCH="arm64" ;;
            *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
        esac
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    log_info "Detected OS: $OS, Architecture: $ARCH"
}

# Create tools directory
setup_directories() {
    TOOLS_DIR="$HOME/.local/bin"
    mkdir -p "$TOOLS_DIR"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$TOOLS_DIR:"* ]]; then
        echo "export PATH=\"$TOOLS_DIR:\$PATH\"" >> "$HOME/.bashrc"
        export PATH="$TOOLS_DIR:$PATH"
        log_info "Added $TOOLS_DIR to PATH"
    fi
}

# Install AWS CLI v2
install_aws_cli() {
    log_info "Installing AWS CLI v2..."
    
    if command -v aws &> /dev/null; then
        AWS_VERSION=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        if [[ "$AWS_VERSION" =~ ^2\. ]]; then
            log_success "AWS CLI v2 already installed: $AWS_VERSION"
            return
        fi
    fi
    
    case "$OS" in
        "linux")
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip -q awscliv2.zip
            sudo ./aws/install --update
            rm -rf aws awscliv2.zip
            ;;
        "darwin")
            curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
            ;;
    esac
    
    log_success "AWS CLI v2 installed successfully"
}

# Install Terraform
install_terraform() {
    log_info "Installing Terraform..."
    
    TERRAFORM_VERSION="1.6.6"
    
    if command -v terraform &> /dev/null; then
        CURRENT_VERSION=$(terraform version -json | jq -r '.terraform_version')
        if [[ "$CURRENT_VERSION" == "$TERRAFORM_VERSION" ]]; then
            log_success "Terraform $TERRAFORM_VERSION already installed"
            return
        fi
    fi
    
    TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip"
    
    curl -LO "$TERRAFORM_URL"
    unzip -q "terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip"
    chmod +x terraform
    mv terraform "$TOOLS_DIR/"
    rm "terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip"
    
    log_success "Terraform $TERRAFORM_VERSION installed successfully"
}

# Install kubectl
install_kubectl() {
    log_info "Installing kubectl..."
    
    if command -v kubectl &> /dev/null; then
        log_success "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'version check failed')"
        return
    fi
    
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${ARCH}/kubectl"
    
    curl -LO "$KUBECTL_URL"
    chmod +x kubectl
    mv kubectl "$TOOLS_DIR/"
    
    log_success "kubectl $KUBECTL_VERSION installed successfully"
}

# Install Helm
install_helm() {
    log_info "Installing Helm..."
    
    if command -v helm &> /dev/null; then
        log_success "Helm already installed: $(helm version --short)"
        return
    fi
    
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    HELM_INSTALL_DIR="$TOOLS_DIR" ./get_helm.sh --no-sudo
    rm get_helm.sh
    
    log_success "Helm installed successfully"
}

# Install Docker (if not already installed)
install_docker() {
    log_info "Checking Docker installation..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker already installed: $(docker --version)"
        return
    fi
    
    log_warning "Docker not found. Please install Docker manually:"
    case "$OS" in
        "linux")
            echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
            echo "  sudo sh get-docker.sh"
            echo "  sudo usermod -aG docker \$USER"
            ;;
        "darwin")
            echo "  Download Docker Desktop from https://www.docker.com/products/docker-desktop"
            ;;
    esac
}

# Install Go
install_go() {
    log_info "Installing Go..."
    
    GO_VERSION="1.21.5"
    
    if command -v go &> /dev/null; then
        CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        if [[ "$CURRENT_GO_VERSION" == "$GO_VERSION" ]]; then
            log_success "Go $GO_VERSION already installed"
            return
        fi
    fi
    
    GO_URL="https://golang.org/dl/go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    
    curl -LO "$GO_URL"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    rm "go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    
    # Add Go to PATH
    if [[ ":$PATH:" != *":/usr/local/go/bin:"* ]]; then
        echo "export PATH=\"/usr/local/go/bin:\$PATH\"" >> "$HOME/.bashrc"
        export PATH="/usr/local/go/bin:$PATH"
    fi
    
    log_success "Go $GO_VERSION installed successfully"
}

# Install Security Tools
install_security_tools() {
    log_info "Installing security tools..."
    
    # Install Syft (SBOM generator)
    if ! command -v syft &> /dev/null; then
        log_info "Installing Syft..."
        curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b "$TOOLS_DIR"
        log_success "Syft installed successfully"
    else
        log_success "Syft already installed: $(syft version)"
    fi
    
    # Install Grype (vulnerability scanner)
    if ! command -v grype &> /dev/null; then
        log_info "Installing Grype..."
        curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b "$TOOLS_DIR"
        log_success "Grype installed successfully"
    else
        log_success "Grype already installed: $(grype version)"
    fi
    
    # Install Cosign (container signing)
    if ! command -v cosign &> /dev/null; then
        log_info "Installing Cosign..."
        COSIGN_VERSION="v2.2.2"
        COSIGN_URL="https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-${OS}-${ARCH}"
        
        curl -L "$COSIGN_URL" -o cosign
        chmod +x cosign
        mv cosign "$TOOLS_DIR/"
        log_success "Cosign $COSIGN_VERSION installed successfully"
    else
        log_success "Cosign already installed: $(cosign version --short)"
    fi
    
    # Install Trivy (comprehensive security scanner)
    if ! command -v trivy &> /dev/null; then
        log_info "Installing Trivy..."
        case "$OS" in
            "linux")
                sudo apt-get update && sudo apt-get install -y wget apt-transport-https gnupg lsb-release
                wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
                sudo apt-get update && sudo apt-get install -y trivy
                ;;
            "darwin")
                if command -v brew &> /dev/null; then
                    brew install trivy
                else
                    log_warning "Homebrew not found. Please install Trivy manually."
                fi
                ;;
        esac
        log_success "Trivy installed successfully"
    else
        log_success "Trivy already installed: $(trivy --version)"
    fi
}

# Install additional utilities
install_utilities() {
    log_info "Installing additional utilities..."
    
    # Install jq (JSON processor)
    if ! command -v jq &> /dev/null; then
        case "$OS" in
            "linux")
                sudo apt-get update && sudo apt-get install -y jq
                ;;
            "darwin")
                if command -v brew &> /dev/null; then
                    brew install jq
                else
                    log_warning "Homebrew not found. Please install jq manually."
                fi
                ;;
        esac
        log_success "jq installed successfully"
    else
        log_success "jq already installed"
    fi
    
    # Install yq (YAML processor)
    if ! command -v yq &> /dev/null; then
        YQ_VERSION="v4.40.5"
        YQ_URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}"
        
        curl -L "$YQ_URL" -o yq
        chmod +x yq
        mv yq "$TOOLS_DIR/"
        log_success "yq $YQ_VERSION installed successfully"
    else
        log_success "yq already installed: $(yq --version)"
    fi
}

# Verify installations
verify_installations() {
    log_info "Verifying installations..."
    
    TOOLS=(
        "aws:AWS CLI"
        "terraform:Terraform"
        "kubectl:kubectl"
        "helm:Helm"
        "go:Go"
        "syft:Syft"
        "grype:Grype"
        "cosign:Cosign"
        "jq:jq"
        "yq:yq"
    )
    
    for tool_info in "${TOOLS[@]}"; do
        IFS=':' read -r tool_cmd tool_name <<< "$tool_info"
        if command -v "$tool_cmd" &> /dev/null; then
            log_success "$tool_name is available"
        else
            log_error "$tool_name is NOT available"
        fi
    done
}

# Main installation function
main() {
    log_info "Starting DevSecOps tools installation..."
    
    check_os
    setup_directories
    
    # Core tools
    install_aws_cli
    install_terraform
    install_kubectl
    install_helm
    install_docker
    install_go
    
    # Security tools
    install_security_tools
    
    # Utilities
    install_utilities
    
    # Verification
    verify_installations
    
    log_success "Installation completed! Please restart your shell or run 'source ~/.bashrc' to update PATH."
    log_info "You may need to configure AWS credentials: aws configure"
}

# Run main function
main "$@"