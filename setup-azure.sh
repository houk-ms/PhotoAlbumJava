#!/bin/bash
set -e

echo "======================================"
echo "PhotoAlbumJava - Azure Deployment Setup"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI (az) is not installed${NC}"
    echo "Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
else
    echo -e "${GREEN}✅ Azure CLI is installed${NC}"
fi

# Check Azure Developer CLI
if ! command -v azd &> /dev/null; then
    echo -e "${RED}❌ Azure Developer CLI (azd) is not installed${NC}"
    echo "Please install from: https://aka.ms/azd-install"
    exit 1
else
    echo -e "${GREEN}✅ Azure Developer CLI is installed${NC}"
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install from: https://docs.docker.com/get-docker/"
    exit 1
else
    echo -e "${GREEN}✅ Docker is installed${NC}"
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
else
    echo -e "${GREEN}✅ Docker is running${NC}"
fi

echo ""
echo "======================================"
echo "Azure Authentication"
echo "======================================"
echo ""

# Check Azure CLI authentication
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Azure CLI not authenticated. Running 'az login'...${NC}"
    az login
else
    echo -e "${GREEN}✅ Azure CLI is authenticated${NC}"
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    echo "Current subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
fi

# Check AZD authentication
echo -e "${YELLOW}Checking Azure Developer CLI authentication...${NC}"
azd auth login --check-status || azd auth login

echo ""
echo "======================================"
echo "Environment Setup"
echo "======================================"
echo ""

# Check if .azure directory exists
if [ -d ".azure" ]; then
    echo -e "${YELLOW}Found existing .azure directory${NC}"
    read -p "Do you want to use existing environment? (y/n): " use_existing
    if [[ $use_existing =~ ^[Yy]$ ]]; then
        echo "Using existing environment..."
    else
        echo "Creating new environment..."
        rm -rf .azure
    fi
fi

# Create new environment if needed
if [ ! -d ".azure" ]; then
    echo "Creating new Azure Developer environment..."
    read -p "Enter environment name (e.g., photoalbum-dev): " ENV_NAME
    azd env new "$ENV_NAME"
fi

# Set location
echo ""
echo "Available regions: eastus, eastus2, westus, westus2, centralus, northeurope, westeurope"
read -p "Enter Azure region (default: eastus2): " LOCATION
LOCATION=${LOCATION:-eastus2}
azd env set AZURE_LOCATION "$LOCATION"
echo -e "${GREEN}✅ Location set to: $LOCATION${NC}"

# Set PostgreSQL credentials
echo ""
echo "PostgreSQL Configuration"
echo "Password requirements: At least 8 characters, uppercase, lowercase, numbers, and special characters"
read -p "Enter PostgreSQL admin username (default: photoalbumadmin): " PG_USER
PG_USER=${PG_USER:-photoalbumadmin}
azd env set POSTGRES_ADMIN_USERNAME "$PG_USER"

read -sp "Enter PostgreSQL admin password: " PG_PASSWORD
echo ""
if [ -z "$PG_PASSWORD" ]; then
    echo -e "${RED}❌ Password cannot be empty${NC}"
    exit 1
fi
azd env set POSTGRES_ADMIN_PASSWORD "$PG_PASSWORD"
echo -e "${GREEN}✅ PostgreSQL credentials configured${NC}"

# Create resource group
echo ""
echo "======================================"
echo "Resource Group Setup"
echo "======================================"
echo ""

ENV_NAME=$(azd env get-values | grep AZURE_ENV_NAME | cut -d'=' -f2 | tr -d '"' | tr -d "'")
RG_NAME="rg-$ENV_NAME"

echo "Creating resource group: $RG_NAME in $LOCATION"
az group create --name "$RG_NAME" --location "$LOCATION" --output none
echo -e "${GREEN}✅ Resource group created: $RG_NAME${NC}"

# Set resource group environment variable
azd env set AZURE_RESOURCE_GROUP "$RG_NAME"

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Environment: $ENV_NAME"
echo "Location: $LOCATION"
echo "Resource Group: $RG_NAME"
echo ""
echo "Next steps:"
echo "1. Review the configuration: azd env get-values"
echo "2. Preview deployment: azd provision --preview --no-prompt"
echo "3. Deploy: azd up --no-prompt"
echo ""
echo "For detailed instructions, see DEPLOYMENT.md"
echo ""
