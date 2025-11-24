#!/bin/bash

# Azure Resource Verification Script using Azure CLI
# This script checks if a resource group has the required resources for PhotoAlbum deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header() {
    echo -e "${BOLD}$1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Parse command line arguments
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-}"
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -s, --subscription <id>      Azure subscription ID"
            echo "  -g, --resource-group <name>  Azure resource group name"
            echo "  -h, --help                   Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  AZURE_SUBSCRIPTION_ID        Azure subscription ID"
            echo "  AZURE_RESOURCE_GROUP         Azure resource group name"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Banner
echo ""
print_header "============================================================"
print_header "PhotoAlbum Azure Resource Verification"
print_header "============================================================"
echo ""

# Check if Azure CLI is installed
if ! command_exists az; then
    print_error "Azure CLI is not installed"
    print_info "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

print_success "Azure CLI is installed"

# Check if logged in
if ! az account show &>/dev/null; then
    print_error "Not logged in to Azure"
    print_info "Please run: az login"
    exit 1
fi

print_success "Authenticated to Azure"

# Set subscription if provided
if [ -n "$SUBSCRIPTION_ID" ]; then
    print_info "Setting subscription to: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID" || {
        print_error "Failed to set subscription"
        exit 1
    }
fi

# Get current subscription
CURRENT_SUB=$(az account show --query "{name:name, id:id}" -o json 2>/dev/null)
if [ $? -eq 0 ]; then
    SUB_NAME=$(echo "$CURRENT_SUB" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    SUB_ID=$(echo "$CURRENT_SUB" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    echo ""
    print_header "Current Subscription:"
    echo "  Name: $SUB_NAME"
    echo "  ID: $SUB_ID"
else
    print_error "Failed to get subscription information"
    exit 1
fi

# Validate resource group parameter
if [ -z "$RESOURCE_GROUP" ]; then
    echo ""
    print_error "Resource group name is required"
    print_info "Usage: $0 --resource-group <name>"
    print_info "Or set: export AZURE_RESOURCE_GROUP=<name>"
    exit 1
fi

# Check if resource group exists
echo ""
print_info "Checking resource group '$RESOURCE_GROUP'..."

if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    RG_INFO=$(az group show --name "$RESOURCE_GROUP" --query "{location:location, state:properties.provisioningState}" -o json)
    LOCATION=$(echo "$RG_INFO" | grep -o '"location":"[^"]*"' | cut -d'"' -f4)
    STATE=$(echo "$RG_INFO" | grep -o '"state":"[^"]*"' | cut -d'"' -f4)
    
    print_success "Resource group exists"
    echo "  Location: $LOCATION"
    echo "  State: $STATE"
else
    print_error "Resource group '$RESOURCE_GROUP' not found"
    exit 1
fi

# List all resources in the group
echo ""
print_info "Listing all resources in '$RESOURCE_GROUP'..."

RESOURCE_COUNT=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length(@)" -o tsv 2>/dev/null || echo "0")

if [ "$RESOURCE_COUNT" -gt 0 ]; then
    print_success "Found $RESOURCE_COUNT resource(s)"
    az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Type:type}" -o table 2>/dev/null | tail -n +3 | while read -r line; do
        echo "  - $line"
    done
else
    print_warning "Resource group is empty"
fi

# Initialize check results
HAS_POSTGRES=false
HAS_CONTAINER_APP=false
HAS_APP_SERVICE=false
HAS_CONTAINER_REGISTRY=false

# Check for PostgreSQL Flexible Server
echo ""
print_info "Checking for PostgreSQL Flexible Server..."

PG_COUNT=$(az postgres flexible-server list --resource-group "$RESOURCE_GROUP" --query "length(@)" -o tsv 2>/dev/null || echo "0")

if [ "$PG_COUNT" -gt 0 ]; then
    print_success "Found PostgreSQL Flexible Server(s)"
    az postgres flexible-server list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, State:state, Version:version, FQDN:fullyQualifiedDomainName}" -o table 2>/dev/null | tail -n +3 | while read -r line; do
        echo "  $line"
    done
    HAS_POSTGRES=true
else
    print_error "No PostgreSQL Flexible Server found"
    print_warning "Required for: Database storage"
fi

# Check for Azure Container Apps
echo ""
print_info "Checking for Azure Container Apps..."

CA_COUNT=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "length(@)" -o tsv 2>/dev/null || echo "0")

if [ "$CA_COUNT" -gt 0 ]; then
    print_success "Found Container App(s)"
    az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, State:properties.provisioningState}" -o table 2>/dev/null | tail -n +3 | while read -r line; do
        echo "  $line"
    done
    HAS_CONTAINER_APP=true
else
    print_warning "No Container Apps found"
fi

# Check for Azure App Service
echo ""
print_info "Checking for Azure App Service..."

AS_COUNT=$(az webapp list --resource-group "$RESOURCE_GROUP" --query "length(@)" -o tsv 2>/dev/null || echo "0")

if [ "$AS_COUNT" -gt 0 ]; then
    print_success "Found App Service(s)"
    az webapp list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, State:state, URL:defaultHostName}" -o table 2>/dev/null | tail -n +3 | while read -r line; do
        echo "  $line"
    done
    HAS_APP_SERVICE=true
else
    print_warning "No App Service found"
fi

# Check for Azure Container Registry
echo ""
print_info "Checking for Azure Container Registry..."

ACR_COUNT=$(az acr list --resource-group "$RESOURCE_GROUP" --query "length(@)" -o tsv 2>/dev/null || echo "0")

if [ "$ACR_COUNT" -gt 0 ]; then
    print_success "Found Container Registry(ies)"
    az acr list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, LoginServer:loginServer, SKU:sku.name}" -o table 2>/dev/null | tail -n +3 | while read -r line; do
        echo "  $line"
    done
    HAS_CONTAINER_REGISTRY=true
else
    print_warning "No Container Registry found (optional but recommended)"
fi

# Print summary
echo ""
print_header "============================================================"
print_header "DEPLOYMENT READINESS SUMMARY"
print_header "============================================================"
echo ""

print_header "Required Resources:"
if [ "$HAS_POSTGRES" = true ]; then
    print_success "PostgreSQL Database"
else
    print_error "PostgreSQL Database"
fi

if [ "$HAS_CONTAINER_APP" = true ] || [ "$HAS_APP_SERVICE" = true ]; then
    print_success "Container Hosting (Container Apps OR App Service)"
else
    print_error "Container Hosting (Container Apps OR App Service)"
fi

echo ""
print_header "Optional Resources:"
if [ "$HAS_CONTAINER_REGISTRY" = true ]; then
    print_success "Container Registry"
else
    print_warning "Container Registry"
fi

echo ""
print_header "Deployment Status:"
if [ "$HAS_POSTGRES" = true ] && ([ "$HAS_CONTAINER_APP" = true ] || [ "$HAS_APP_SERVICE" = true ]); then
    print_success "Resource group has all required resources for deployment"
    echo ""
    print_header "============================================================"
    echo ""
    exit 0
else
    print_error "Missing required resources - deployment will fail"
    echo ""
    print_header "Next Steps:"
    if [ "$HAS_POSTGRES" = false ]; then
        echo "  • Create Azure Database for PostgreSQL Flexible Server"
    fi
    if [ "$HAS_CONTAINER_APP" = false ] && [ "$HAS_APP_SERVICE" = false ]; then
        echo "  • Create Azure Container Apps or Azure App Service"
    fi
    if [ "$HAS_CONTAINER_REGISTRY" = false ]; then
        echo "  • (Optional) Create Azure Container Registry for Docker images"
    fi
    echo ""
    print_header "============================================================"
    echo ""
    exit 1
fi
