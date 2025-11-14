# Azure Deployment Instructions for PhotoAlbumJava

This guide provides step-by-step instructions to deploy the PhotoAlbumJava application to Azure using the generated infrastructure files.

## Prerequisites

Before you begin, ensure you have:
- Azure subscription with appropriate permissions
- Azure CLI (`az`) installed and authenticated
- Azure Developer CLI (`azd`) installed
- Docker installed and running
- Git installed

## Architecture Overview

The deployment will create:
- **Azure Container Apps**: Hosts the Spring Boot application
- **Azure Database for PostgreSQL**: Flexible Server (Standard_D2ds_v5, PostgreSQL 17)
- **Azure Container Registry**: Stores Docker images
- **Azure Key Vault**: Stores secrets (connection strings, credentials)
- **Application Insights**: Application performance monitoring
- **Log Analytics Workspace**: Centralized logging
- **User-Assigned Managed Identity**: Secure authentication between services

## Step 1: Install Required Tools

### Install Azure Developer CLI (azd)

**Windows (PowerShell):**
```powershell
winget install microsoft.azd
```

**macOS:**
```bash
brew tap azure/azd && brew install azd
```

**Linux:**
```bash
curl -fsSL https://aka.ms/install-azd.sh | bash
```

### Verify installations:
```bash
az --version        # Should show Azure CLI version 2.79.0 or higher
azd version         # Should show Azure Developer CLI version
docker --version    # Should show Docker version
```

## Step 2: Authenticate with Azure

```bash
# Login to Azure CLI
az login

# Login to Azure Developer CLI
azd auth login

# Set your subscription (if you have multiple)
az account set --subscription <your-subscription-id>
```

## Step 3: Initialize AZD Environment

Navigate to the project root directory:
```bash
cd /path/to/PhotoAlbumJava
```

Create a new AZD environment:
```bash
azd env new photoalbum-env
```

This will prompt you for:
- **Environment name**: A unique name for your deployment (e.g., `photoalbum-prod`, `photoalbum-dev`)
- **Subscription**: Select your Azure subscription
- **Location**: Choose an Azure region (e.g., `eastus2`, `westus2`, `westeurope`)

## Step 4: Set Environment Variables

Set the required environment variables for the deployment:

```bash
# Set the Azure location (region)
azd env set AZURE_LOCATION eastus2

# Generate a strong password for PostgreSQL
azd env set POSTGRES_ADMIN_PASSWORD "<your-strong-password>"

# Optional: Set custom PostgreSQL username (default is photoalbumadmin)
azd env set POSTGRES_ADMIN_USERNAME photoalbumadmin
```

**Important**: Replace `<your-strong-password>` with a strong password that meets Azure PostgreSQL requirements:
- At least 8 characters
- Contains uppercase and lowercase letters
- Contains numbers
- Contains special characters

## Step 5: Create Resource Group

The Bicep template is scoped to resource group level, so you need to create a resource group first:

```bash
# Get your environment name
ENV_NAME=$(azd env get-values | grep AZURE_ENV_NAME | cut -d'=' -f2 | tr -d '"')

# Create resource group
az group create --name "rg-$ENV_NAME" --location eastus2

# Set the resource group environment variable
azd env set AZURE_RESOURCE_GROUP "rg-$ENV_NAME"
```

## Step 6: Preview Infrastructure (Dry Run)

Before deploying, preview what will be created:

```bash
azd provision --preview --no-prompt
```

This command will:
- Validate your Bicep templates
- Show you what resources will be created
- Estimate the deployment without actually creating resources

Review the output carefully. If there are any errors, fix them before proceeding.

## Step 7: Deploy to Azure

Deploy both infrastructure and application:

```bash
azd up --no-prompt
```

This command will:
1. Build the Docker image from the Dockerfile
2. Push the image to Azure Container Registry
3. Provision all Azure resources (PostgreSQL, Container App, Key Vault, etc.)
4. Deploy the application to Container Apps
5. Configure environment variables and secrets

**Note**: The first deployment may take 10-15 minutes.

### What happens during deployment:

1. **Docker Build**: The application is built using the multi-stage Dockerfile
2. **Image Push**: The image is pushed to Azure Container Registry
3. **Resource Provisioning**: All Azure resources are created via Bicep
4. **Database Setup**: PostgreSQL server is created and configured
5. **Container App Deployment**: The application is deployed to Container Apps
6. **Secret Configuration**: Connection strings are stored in Key Vault
7. **DNS Configuration**: A public URL is assigned to your application

## Step 8: Verify Deployment

After deployment completes, verify the application is running:

### Get the application URL:
```bash
azd env get-values | grep PHOTOALBUM_CONTAINER_APP_URL
```

Or retrieve it from Azure:
```bash
az containerapp show --name <container-app-name> --resource-group <resource-group-name> --query properties.configuration.ingress.fqdn -o tsv
```

### Check application logs:
```bash
# View container app logs
az containerapp logs show --name <container-app-name> --resource-group <resource-group-name> --follow

# Or use the appmod tool (if available)
# This will retrieve logs from Log Analytics
```

### Test the application:
1. Open the application URL in your browser
2. You should see the PhotoAlbum application home page
3. Test uploading a photo
4. Verify photos are displayed in the gallery

## Step 9: Verify Database Connection

Check that the application successfully connected to PostgreSQL:

```bash
# Check container app logs for database connection
az containerapp logs show --name <container-app-name> --resource-group <resource-group-name> --tail 100 | grep -i postgres

# Should see successful connection logs like:
# "HikariPool-1 - Starting..."
# "HikariPool-1 - Start completed."
```

## Troubleshooting

### Common Issues and Solutions

#### 1. PostgreSQL Deployment Error: "An unexpected error while processing the request"

**Cause**: Quota limit for PostgreSQL Flexible Servers in the region.

**Solution**:
```bash
# Check quota
az postgres flexible-server list-skus --location <location>

# Try a different region
azd env set AZURE_LOCATION <different-region>
azd down --force --no-prompt
azd up --no-prompt
```

#### 2. Container App cannot access Key Vault

**Cause**: Network restrictions or managed identity not configured properly.

**Solution**: The Bicep template uses direct connection strings initially. After first successful deployment:
1. Get the Container App's outbound IP
2. Update Key Vault to switch to Key Vault references
3. Add the IP to Key Vault network rules

#### 3. Docker build fails

**Cause**: Maven dependency resolution issues.

**Solution**:
```bash
# Build locally first to verify
mvn clean package -DskipTests

# If successful, retry azd up
azd up --no-prompt
```

#### 4. Application starts but cannot connect to database

**Cause**: Firewall rules or connection string misconfiguration.

**Solution**:
- Verify firewall rule allows Azure Services (0.0.0.0)
- Check connection string format in Container App environment variables
- Verify PostgreSQL server is running

## Step 10: Update Application

To deploy application updates:

```bash
# Make code changes
# Then redeploy
azd deploy

# Or to rebuild and redeploy everything
azd up
```

## Step 11: Monitor Application

### View Application Insights:
1. Go to Azure Portal
2. Navigate to your Application Insights resource
3. View metrics, logs, and performance data

### View Container App Metrics:
```bash
az containerapp show --name <container-app-name> --resource-group <resource-group-name>
```

## Step 12: Clean Up Resources

When you're done, delete all resources:

```bash
# Delete all resources
azd down --force --purge --no-prompt

# Or manually delete the resource group
az group delete --name <resource-group-name> --yes --no-wait
```

## Environment Variables Reference

The following environment variables are used in the deployment:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `AZURE_ENV_NAME` | Environment name | Yes | Set by azd env new |
| `AZURE_LOCATION` | Azure region | Yes | Set by azd env set |
| `AZURE_RESOURCE_GROUP` | Resource group name | Yes | Set manually |
| `POSTGRES_ADMIN_USERNAME` | PostgreSQL admin username | No | photoalbumadmin |
| `POSTGRES_ADMIN_PASSWORD` | PostgreSQL admin password | Yes | Set by azd env set |

## Resource Naming Convention

Resources are named using the pattern: `az{prefix}{uniqueToken}`

Where:
- `prefix`: Resource type prefix (e.g., `ca` for Container App, `pg` for PostgreSQL)
- `uniqueToken`: Generated from `uniqueString(subscription().id, resourceGroup().id, location, environmentName)`

Example resource names:
- Container App: `azcaabcd1234efgh5678`
- PostgreSQL: `azpgabcd1234efgh5678`
- Key Vault: `azkvabcd1234efgh5678`
- Container Registry: `azacrabcd1234efgh5678`

## Next Steps

After successful deployment:
1. Configure custom domain (optional)
2. Enable authentication/authorization (optional)
3. Set up CI/CD pipeline for automated deployments
4. Configure backup and disaster recovery
5. Implement monitoring alerts
6. Review and optimize costs

## Support

For issues or questions:
- Review Azure Container Apps documentation
- Check Application Insights for application errors
- Review deployment logs with `azd monitor --logs`
- Consult Azure PostgreSQL documentation

## Security Best Practices

1. **Secrets Management**: All secrets are stored in Key Vault
2. **Managed Identity**: Used for authentication between services
3. **Network Security**: Firewall rules configured for Azure Services
4. **SSL/TLS**: Enforced for PostgreSQL connections
5. **RBAC**: Key Vault uses Role-Based Access Control
6. **Container Security**: Images stored in private ACR

## Cost Optimization

- Container Apps scale to zero when not in use
- PostgreSQL Flexible Server can be stopped when not needed
- Use Burstable SKU for development environments
- Monitor costs with Azure Cost Management
