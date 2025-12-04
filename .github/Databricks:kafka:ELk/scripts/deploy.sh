#!/bin/bash

# Threat Detection Pipeline Deployment Script
# This script deploys the complete threat detection infrastructure

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
MONITORING_DIR="$PROJECT_ROOT/monitoring"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed. Please install terraform first."
        exit 1
    fi
    
    # Check if kubectl is installed  
    if ! command -v kubectl &> /dev/null; then
        warning "kubectl is not installed. Some features may not work."
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        warning "Helm is not installed. Kubernetes deployments may not work."
    fi
    
    success "Prerequisites check completed"
}

# Initialize Terraform
init_terraform() {
    log "Initializing Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    if [ ! -f "main.tf" ]; then
        error "Terraform configuration not found at $TERRAFORM_DIR/main.tf"
        exit 1
    fi
    
    terraform init
    success "Terraform initialized successfully"
}

# Validate Terraform configuration
validate_terraform() {
    log "Validating Terraform configuration..."
    
    cd "$TERRAFORM_DIR"
    terraform validate
    
    if [ $? -eq 0 ]; then
        success "Terraform configuration is valid"
    else
        error "Terraform configuration validation failed"
        exit 1
    fi
}

# Plan Terraform deployment
plan_terraform() {
    log "Planning Terraform deployment..."
    
    cd "$TERRAFORM_DIR"
    
    # Use dev.tfvars if it exists
    if [ -f "dev.tfvars" ]; then
        terraform plan -var-file="dev.tfvars" -out="deployment.tfplan"
    else
        terraform plan -out="deployment.tfplan"
    fi
    
    success "Terraform plan completed"
}

# Apply Terraform deployment
apply_terraform() {
    log "Applying Terraform deployment..."
    
    cd "$TERRAFORM_DIR"
    
    if [ ! -f "deployment.tfplan" ]; then
        error "No deployment plan found. Run planning first."
        exit 1
    fi
    
    terraform apply "deployment.tfplan"
    success "Terraform deployment completed"
}

# Deploy monitoring components
deploy_monitoring() {
    log "Deploying monitoring components..."
    
    if [ -d "$MONITORING_DIR" ]; then
        cd "$MONITORING_DIR"
        
        # Check for monitoring configuration files
        if [ -f "docker-compose.yml" ]; then
            log "Found Docker Compose configuration, starting services..."
            docker-compose up -d
        elif [ -f "monitoring-stack.yaml" ]; then
            log "Found Kubernetes monitoring configuration..."
            kubectl apply -f monitoring-stack.yaml
        else
            warning "No monitoring configuration found in $MONITORING_DIR"
        fi
        
        success "Monitoring deployment completed"
    else
        warning "Monitoring directory not found: $MONITORING_DIR"
    fi
}

# Deploy Kafka infrastructure
deploy_kafka() {
    log "Deploying Kafka infrastructure..."
    
    HELM_CHARTS_DIR="$PROJECT_ROOT/helm-charts/kafka"
    
    if [ -d "$HELM_CHARTS_DIR" ]; then
        cd "$HELM_CHARTS_DIR"
        
        if [ -f "Chart.yaml" ]; then
            log "Installing Kafka Helm chart..."
            helm install kafka . --namespace kafka --create-namespace
            success "Kafka deployment completed"
        else
            warning "Kafka Chart.yaml not found"
        fi
    else
        warning "Kafka Helm charts not found"
    fi
}

# Deploy platform toolkit records
deploy_platform_toolkit() {
    log "Deploying Platform Toolkit records..."
    
    TOOLKIT_DIR="$PROJECT_ROOT/platformtoolkit-records"
    
    if [ -d "$TOOLKIT_DIR" ]; then
        cd "$TOOLKIT_DIR"
        
        # Check if we're on macOS or Linux for appropriate deployment
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if [ -f "macos/platform_toolkit.sh" ]; then
                log "Installing macOS Platform Toolkit..."
                chmod +x macos/platform_toolkit.sh
                ./macos/platform_toolkit.sh --install
            fi
        else
            if [ -f "platform_toolkit.ps1" ]; then
                log "Platform Toolkit PowerShell scripts found (requires Windows)"
                warning "Run platform_toolkit.ps1 on Windows systems"
            fi
        fi
        
        success "Platform Toolkit deployment completed"
    else
        warning "Platform Toolkit directory not found"
    fi
}

# Main deployment function
main() {
    log "Starting Threat Detection Pipeline deployment..."
    
    # Parse command line arguments
    SKIP_TERRAFORM=false
    SKIP_MONITORING=false
    SKIP_KAFKA=false
    SKIP_TOOLKIT=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-terraform)
                SKIP_TERRAFORM=true
                shift
                ;;
            --skip-monitoring)
                SKIP_MONITORING=true
                shift
                ;;
            --skip-kafka)
                SKIP_KAFKA=true
                shift
                ;;
            --skip-toolkit)
                SKIP_TOOLKIT=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --skip-terraform   Skip Terraform deployment"
                echo "  --skip-monitoring  Skip monitoring deployment"
                echo "  --skip-kafka       Skip Kafka deployment"
                echo "  --skip-toolkit     Skip Platform Toolkit deployment"
                echo "  --help             Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run deployment steps
    check_prerequisites
    
    if [ "$SKIP_TERRAFORM" = false ]; then
        init_terraform
        validate_terraform
        plan_terraform
        
        # Ask for confirmation before applying
        echo -e "${YELLOW}Ready to apply Terraform deployment. Continue? (y/N)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            apply_terraform
        else
            log "Skipping Terraform apply"
        fi
    fi
    
    if [ "$SKIP_MONITORING" = false ]; then
        deploy_monitoring
    fi
    
    if [ "$SKIP_KAFKA" = false ]; then
        deploy_kafka
    fi
    
    if [ "$SKIP_TOOLKIT" = false ]; then
        deploy_platform_toolkit
    fi
    
    success "Threat Detection Pipeline deployment completed successfully!"
    
    log "Deployment Summary:"
    log "- Terraform: $([ "$SKIP_TERRAFORM" = false ] && echo "Deployed" || echo "Skipped")"
    log "- Monitoring: $([ "$SKIP_MONITORING" = false ] && echo "Deployed" || echo "Skipped")"
    log "- Kafka: $([ "$SKIP_KAFKA" = false ] && echo "Deployed" || echo "Skipped")"
    log "- Platform Toolkit: $([ "$SKIP_TOOLKIT" = false ] && echo "Deployed" || echo "Skipped")"
}

# Run main function with all arguments
main "$@"