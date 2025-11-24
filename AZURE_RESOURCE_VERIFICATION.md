# Azure Resource Verification Guide

This guide explains how to verify that your Azure resource group has all the necessary resources to deploy the PhotoAlbum Java application.

## Overview

The PhotoAlbum application requires the following Azure resources:

### Required Resources
1. **Azure Database for PostgreSQL Flexible Server** - For storing photo metadata and binary data
2. **Azure Container Apps OR Azure App Service** - For hosting the Spring Boot application
3. **Azure Container Registry** (optional but recommended) - For storing Docker container images

## Prerequisites

Before running the verification:

1. **Azure CLI** must be installed
   - Check: `az --version`
   - Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

2. **Azure Account** with appropriate permissions
   - Reader access to the resource group (minimum)
   - Contributor access for deployment

3. **Login to Azure**
   ```bash
   az login
   ```

## Method 1: Using the Python Verification Script

The repository includes a comprehensive Python script that checks all required resources.

### Usage

```bash
# Using command-line arguments
python check-azure-resources.py --subscription <subscription-id> --resource-group <resource-group-name>

# Using environment variables
export AZURE_SUBSCRIPTION_ID=<your-subscription-id>
export AZURE_RESOURCE_GROUP=<your-resource-group-name>
python check-azure-resources.py
```

### Example Output

```
============================================================
PhotoAlbum Azure Resource Verification
============================================================

Checking Azure CLI authentication...
✓ Authenticated to Azure

Current Subscription:
  Name: My Azure Subscription
  ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

Checking resource group 'my-photoalbum-rg'...
✓ Resource group exists
  Location: eastus
  Status: Succeeded

Listing all resources in 'my-photoalbum-rg'...
Found 3 resource(s):
  - photoalbum-db (Microsoft.DBforPostgreSQL/flexibleServers)
  - photoalbum-app (Microsoft.App/containerApps)
  - photoalbumregistry (Microsoft.ContainerRegistry/registries)

Checking for PostgreSQL Flexible Server...
✓ Found PostgreSQL Flexible Server(s):
  - Name: photoalbum-db
    Status: Ready
    Version: 15
    FQDN: photoalbum-db.postgres.database.azure.com

Checking for Azure Container Apps...
✓ Found Container App(s):
  - Name: photoalbum-app
    Status: Succeeded
    FQDN: photoalbum-app.example.azurecontainerapps.io

Checking for Azure Container Registry...
✓ Found Container Registry(ies):
  - Name: photoalbumregistry
    Login Server: photoalbumregistry.azurecr.io
    SKU: Basic

============================================================
DEPLOYMENT READINESS SUMMARY
============================================================

Required Resources:
  ✓ PostgreSQL Database
  ✓ Container Hosting (Container Apps OR App Service)

Optional Resources:
  ✓ Container Registry

Deployment Status:
✓ Resource group has all required resources for deployment
```

## Method 2: Using Azure CLI Directly

You can also manually check resources using Azure CLI commands:

### Check Resource Group Exists

```bash
az group show --name <resource-group-name>
```

### List All Resources in Group

```bash
az resource list --resource-group <resource-group-name> --output table
```

### Check PostgreSQL Server

```bash
az postgres flexible-server list --resource-group <resource-group-name> --output table
```

### Check Container Apps

```bash
az containerapp list --resource-group <resource-group-name> --output table
```

### Check App Service

```bash
az webapp list --resource-group <resource-group-name> --output table
```

### Check Container Registry

```bash
az acr list --resource-group <resource-group-name> --output table
```

## Method 3: Using Azure MCP Tools (For Copilot/AI Assistants)

If you're working with Azure MCP (Model Context Protocol), you can use these tools:

### List Subscriptions
```javascript
AzureMCPServer-subscription_list({ intent: "List all Azure subscriptions" })
```

### List Resource Groups
```javascript
AzureMCPServer-group_list({ 
    intent: "List resource groups",
    subscription: "<subscription-id>"
})
```

### Check PostgreSQL Servers
```javascript
AzureMCPServer-postgres({
    intent: "List PostgreSQL flexible servers",
    command: "flexible-server list",
    parameters: {
        "resource-group": "<resource-group-name>",
        subscription: "<subscription-id>"
    }
})
```

### Check Container Apps
```javascript
AzureMCPServer-appservice({
    intent: "List container apps",
    command: "containerapp list",
    parameters: {
        "resource-group": "<resource-group-name>",
        subscription: "<subscription-id>"
    }
})
```

### Check Container Registry
```javascript
AzureMCPServer-acr({
    intent: "List container registries",
    command: "list",
    parameters: {
        "resource-group": "<resource-group-name>",
        subscription: "<subscription-id>"
    }
})
```

## Creating Missing Resources

If the verification shows missing resources, you can create them:

### Create PostgreSQL Flexible Server

```bash
az postgres flexible-server create \
    --resource-group <resource-group-name> \
    --name <server-name> \
    --location <location> \
    --admin-user <admin-username> \
    --admin-password <admin-password> \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --version 15 \
    --storage-size 32
```

### Create Container App Environment and App

```bash
# Create Container App environment
az containerapp env create \
    --name <environment-name> \
    --resource-group <resource-group-name> \
    --location <location>

# Create Container App
az containerapp create \
    --name <app-name> \
    --resource-group <resource-group-name> \
    --environment <environment-name> \
    --image <container-image> \
    --target-port 8080 \
    --ingress external
```

### Create Container Registry

```bash
az acr create \
    --resource-group <resource-group-name> \
    --name <registry-name> \
    --sku Basic \
    --location <location>
```

## Troubleshooting

### Authentication Issues

If you see authentication errors:
```bash
az login --use-device-code  # For environments without browser
az account set --subscription <subscription-id>  # Set default subscription
```

### Permission Issues

Ensure your account has at least Reader role:
```bash
az role assignment list --assignee <your-email> --resource-group <resource-group-name>
```

### Resource Not Found

If resources exist but aren't detected:
- Verify resource group name is correct (case-sensitive)
- Check subscription is correct
- Ensure resources are in the expected resource group

## Next Steps

After verifying resources:

1. **If all resources exist**: Proceed with deployment
   - Use the included deployment scripts
   - Configure connection strings
   - Deploy application

2. **If resources are missing**: Create them using Azure Portal or CLI
   - Follow the resource creation guides above
   - Ensure proper naming conventions
   - Configure networking and security

3. **Update application configuration**:
   - Set environment variables for database connection
   - Configure container registry credentials
   - Update application settings in Azure

## Additional Resources

- [Azure Database for PostgreSQL Documentation](https://docs.microsoft.com/en-us/azure/postgresql/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
