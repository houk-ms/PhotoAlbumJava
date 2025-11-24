# Azure MCP Integration - Quick Start Guide

This is a quick reference guide for using Azure MCP to verify resources for the PhotoAlbum Java application.

## What You Need to Know

The PhotoAlbum application requires these Azure resources to run:

| Resource | Type | Required | Purpose |
|----------|------|----------|---------|
| PostgreSQL Flexible Server | `Microsoft.DBforPostgreSQL/flexibleServers` | ✅ Yes | Store photo data and metadata |
| Container Apps OR App Service | `Microsoft.App/containerApps` OR `Microsoft.Web/sites` | ✅ Yes | Host the Spring Boot application |
| Container Registry | `Microsoft.ContainerRegistry/registries` | ⚠️ Optional | Store Docker images |

## Quick Verification (3 Steps)

### Step 1: Login to Azure
```bash
az login
```

### Step 2: Run Verification Script
```bash
# Option A: Python (recommended)
python check-azure-resources.py \
  --subscription YOUR_SUBSCRIPTION_ID \
  --resource-group YOUR_RESOURCE_GROUP

# Option B: Bash
./check-azure-resources.sh \
  --subscription YOUR_SUBSCRIPTION_ID \
  --resource-group YOUR_RESOURCE_GROUP
```

### Step 3: Read the Results
- ✅ **All green checkmarks** = Ready to deploy!
- ❌ **Red X marks** = Missing required resources
- ⚠️ **Yellow warnings** = Missing optional resources

## Common Scenarios

### Scenario A: Just Starting Out
**Question**: "I don't have any Azure resources yet. What do I do?"

**Answer**: You need to create:
1. A resource group
2. A PostgreSQL database
3. Either Container Apps or App Service

**Quick commands**:
```bash
# Create resource group
az group create --name photoalbum-rg --location eastus

# Create PostgreSQL server
az postgres flexible-server create \
  --resource-group photoalbum-rg \
  --name photoalbum-db \
  --admin-user dbadmin \
  --admin-password 'YourSecurePassword123!' \
  --sku-name Standard_B1ms \
  --version 15

# Create Container App (option 1)
az containerapp env create \
  --name photoalbum-env \
  --resource-group photoalbum-rg \
  --location eastus

az containerapp create \
  --name photoalbum-app \
  --resource-group photoalbum-rg \
  --environment photoalbum-env \
  --image nginx \
  --target-port 8080 \
  --ingress external
```

### Scenario B: Have Resources, Want to Verify
**Question**: "I already have Azure resources. How do I check if they're right?"

**Answer**: Run the verification script:
```bash
python check-azure-resources.py \
  --subscription YOUR_SUBSCRIPTION_ID \
  --resource-group YOUR_RESOURCE_GROUP
```

The script will tell you exactly what's present and what's missing.

### Scenario C: Using Environment Variables
**Question**: "I don't want to type the subscription and resource group every time."

**Answer**: Set environment variables:
```bash
# Add to your ~/.bashrc or ~/.zshrc
export AZURE_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789abc"
export AZURE_RESOURCE_GROUP="photoalbum-rg"

# Then just run:
python check-azure-resources.py
```

### Scenario D: CI/CD Pipeline
**Question**: "How do I use this in my GitHub Actions or Azure DevOps pipeline?"

**Answer**: Add to your workflow:

**GitHub Actions**:
```yaml
- name: Verify Azure Resources
  run: |
    python check-azure-resources.py \
      --subscription ${{ secrets.AZURE_SUBSCRIPTION_ID }} \
      --resource-group ${{ secrets.AZURE_RESOURCE_GROUP }}
```

**Azure DevOps**:
```yaml
- script: |
    python check-azure-resources.py \
      --subscription $(AZURE_SUBSCRIPTION_ID) \
      --resource-group $(AZURE_RESOURCE_GROUP)
  displayName: 'Verify Azure Resources'
```

## Understanding the Output

### Success Output
```
✓ Authenticated to Azure
✓ Resource group exists
✓ Found PostgreSQL Flexible Server(s)
✓ Found Container App(s)
✓ Resource group has all required resources for deployment
```
👉 **You're ready to deploy!**

### Failure Output
```
❌ No PostgreSQL Flexible Server found
❌ Container Hosting (Container Apps OR App Service)
❌ Missing required resources - deployment will fail
```
👉 **Create the missing resources before deploying**

### Warning Output
```
⚠ No Container Registry found (optional but recommended)
```
👉 **Not critical, but recommended for production**

## Troubleshooting

### Problem: "Authentication failed"
**Solution**: 
```bash
az login
az account show  # Verify you're logged in
```

### Problem: "Resource group not found"
**Solution**: Check the name (case-sensitive):
```bash
az group list --output table
```

### Problem: "Permission denied"
**Solution**: Ensure you have at least Reader access:
```bash
az role assignment list --assignee YOUR_EMAIL --resource-group YOUR_RG
```

### Problem: "Script not found" or "Permission denied"
**Solution**: Make scripts executable:
```bash
chmod +x check-azure-resources.py
chmod +x check-azure-resources.sh
```

## Using with Copilot

If you're using GitHub Copilot or an AI assistant with Azure MCP support, you can ask:

- "Check if my resource group has all resources for PhotoAlbum"
- "List resources in my photoalbum-rg resource group"
- "Verify my Azure setup for PhotoAlbum deployment"
- "What Azure resources do I need for PhotoAlbum?"

## Next Steps After Verification

### ✅ If All Resources Present
1. Configure database connection strings
2. Deploy your application
3. Test the deployment

### ❌ If Resources Missing
1. Create missing resources (see Azure Portal or CLI commands)
2. Re-run verification
3. Proceed with deployment once all resources exist

## Quick Reference Commands

```bash
# Login
az login

# List subscriptions
az account list --output table

# List resource groups
az group list --output table

# Show specific resource group
az group show --name YOUR_RG

# List all resources in a group
az resource list --resource-group YOUR_RG --output table

# Run verification
python check-azure-resources.py --subscription SUB_ID --resource-group RG_NAME
```

## Get Help

```bash
# Script help
python check-azure-resources.py --help
./check-azure-resources.sh --help

# Azure CLI help
az --help
az postgres flexible-server --help
az containerapp --help
```

## Documentation Links

- 📖 [Detailed Verification Guide](AZURE_RESOURCE_VERIFICATION.md)
- 📖 [Azure MCP Examples](AZURE_MCP_EXAMPLES.md)
- 📖 [Example Outputs](EXAMPLE_OUTPUTS.md)
- 🔗 [Azure Portal](https://portal.azure.com)
- 🔗 [Azure CLI Docs](https://docs.microsoft.com/en-us/cli/azure/)

---

**💡 Pro Tip**: Bookmark this page for quick reference when working with Azure resources!
