# Example Output: Azure Resource Verification

This document shows example outputs from the Azure resource verification scripts.

## Scenario 1: User Not Logged In

```
============================================================
PhotoAlbum Azure Resource Verification
============================================================

Checking Azure CLI authentication...
❌ Not logged in to Azure CLI
Please run: az login
```

**Action Required**: Run `az login` to authenticate.

---

## Scenario 2: Missing Resource Group Parameter

```
============================================================
PhotoAlbum Azure Resource Verification
============================================================

Checking Azure CLI authentication...
✓ Authenticated to Azure

Current Subscription:
  Name: My Azure Subscription
  ID: 12345678-1234-1234-1234-123456789abc

❌ Resource group name is required
Usage: python check-azure-resources.py --resource-group <name>
Or set: export AZURE_RESOURCE_GROUP=<name>
```

**Action Required**: Provide resource group name via command-line or environment variable.

---

## Scenario 3: Resource Group Not Found

```
============================================================
PhotoAlbum Azure Resource Verification
============================================================

Checking Azure CLI authentication...
✓ Authenticated to Azure

Current Subscription:
  Name: My Azure Subscription
  ID: 12345678-1234-1234-1234-123456789abc

Checking resource group 'nonexistent-rg'...
❌ Resource group 'nonexistent-rg' not found
```

**Action Required**: Verify resource group name is correct or create the resource group.

---

## Scenario 4: Empty Resource Group

```
============================================================
PhotoAlbum Azure Resource Verification
============================================================

Checking Azure CLI authentication...
✓ Authenticated to Azure

Current Subscription:
  Name: My Azure Subscription
  ID: 12345678-1234-1234-1234-123456789abc

Checking resource group 'photoalbum-rg'...
✓ Resource group exists
  Location: eastus
  Status: Succeeded

Listing all resources in 'photoalbum-rg'...
⚠ Resource group is empty

Checking for PostgreSQL Flexible Server...
❌ No PostgreSQL Flexible Server found
   Required for: Database storage

Checking for Azure Container Apps...
⚠ No Container Apps found

Checking for Azure App Service...
⚠ No App Service found

Checking for Azure Container Registry...
⚠ No Container Registry found (optional but recommended)

============================================================
DEPLOYMENT READINESS SUMMARY
============================================================

Required Resources:
  ❌ PostgreSQL Database
  ❌ Container Hosting (Container Apps OR App Service)

Optional Resources:
  ⚠ Container Registry

Deployment Status:
❌ Missing required resources - deployment will fail

Next Steps:
  • Create Azure Database for PostgreSQL Flexible Server
  • Create Azure Container Apps or Azure App Service
  • (Optional) Create Azure Container Registry for Docker images

============================================================
```

**Action Required**: Create the required Azure resources.

---

## Scenario 5: Partial Resources (Only Database)

```
============================================================
PhotoAlbum Azure Resource Verification
============================================================

Checking Azure CLI authentication...
✓ Authenticated to Azure

Current Subscription:
  Name: My Azure Subscription
  ID: 12345678-1234-1234-1234-123456789abc

Checking resource group 'photoalbum-rg'...
✓ Resource group exists
  Location: eastus
  Status: Succeeded

Listing all resources in 'photoalbum-rg'...
Found 1 resource(s):
  - photoalbum-db (Microsoft.DBforPostgreSQL/flexibleServers)

Checking for PostgreSQL Flexible Server...
✓ Found PostgreSQL Flexible Server(s):
  - Name: photoalbum-db
    Status: Ready
    Version: 15
    FQDN: photoalbum-db.postgres.database.azure.com

Checking for Azure Container Apps...
⚠ No Container Apps found

Checking for Azure App Service...
⚠ No App Service found

Checking for Azure Container Registry...
⚠ No Container Registry found (optional but recommended)

============================================================
DEPLOYMENT READINESS SUMMARY
============================================================

Required Resources:
  ✓ PostgreSQL Database
  ❌ Container Hosting (Container Apps OR App Service)

Optional Resources:
  ⚠ Container Registry

Deployment Status:
❌ Missing required resources - deployment will fail

Next Steps:
  • Create Azure Container Apps or Azure App Service
  • (Optional) Create Azure Container Registry for Docker images

============================================================
```

**Action Required**: Create Container Apps or App Service.

---

## Scenario 6: All Required Resources Present (Container Apps)

```
============================================================
PhotoAlbum Azure Resource Verification
============================================================

Checking Azure CLI authentication...
✓ Authenticated to Azure

Current Subscription:
  Name: My Azure Subscription
  ID: 12345678-1234-1234-1234-123456789abc

Checking resource group 'photoalbum-rg'...
✓ Resource group exists
  Location: eastus
  Status: Succeeded

Listing all resources in 'photoalbum-rg'...
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
    FQDN: photoalbum-app.happyhill-12345678.eastus.azurecontainerapps.io

Checking for Azure App Service...
⚠ No App Service found

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

============================================================
```

**Status**: ✅ Ready for deployment!

---

## Scenario 7: All Required Resources Present (App Service)

```
============================================================
PhotoAlbum Azure Resource Verification
============================================================

Checking Azure CLI authentication...
✓ Authenticated to Azure

Current Subscription:
  Name: My Azure Subscription
  ID: 12345678-1234-1234-1234-123456789abc

Checking resource group 'photoalbum-rg'...
✓ Resource group exists
  Location: westus2
  Status: Succeeded

Listing all resources in 'photoalbum-rg'...
Found 3 resource(s):
  - photoalbum-db (Microsoft.DBforPostgreSQL/flexibleServers)
  - photoalbum-webapp (Microsoft.Web/sites)
  - photoalbumregistry (Microsoft.ContainerRegistry/registries)

Checking for PostgreSQL Flexible Server...
✓ Found PostgreSQL Flexible Server(s):
  - Name: photoalbum-db
    Status: Ready
    Version: 15
    FQDN: photoalbum-db.postgres.database.azure.com

Checking for Azure Container Apps...
⚠ No Container Apps found

Checking for Azure App Service...
✓ Found App Service(s):
  - Name: photoalbum-webapp
    Status: Running
    URL: https://photoalbum-webapp.azurewebsites.net

Checking for Azure Container Registry...
✓ Found Container Registry(ies):
  - Name: photoalbumregistry
    Login Server: photoalbumregistry.azurecr.io
    SKU: Standard

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

============================================================
```

**Status**: ✅ Ready for deployment!

---

## Scenario 8: Multiple Resources of Same Type

```
============================================================
PhotoAlbum Azure Resource Verification
============================================================

Checking Azure CLI authentication...
✓ Authenticated to Azure

Current Subscription:
  Name: Production Subscription
  ID: 12345678-1234-1234-1234-123456789abc

Checking resource group 'photoalbum-prod-rg'...
✓ Resource group exists
  Location: eastus2
  Status: Succeeded

Listing all resources in 'photoalbum-prod-rg'...
Found 5 resource(s):
  - photoalbum-db-primary (Microsoft.DBforPostgreSQL/flexibleServers)
  - photoalbum-db-replica (Microsoft.DBforPostgreSQL/flexibleServers)
  - photoalbum-app (Microsoft.App/containerApps)
  - photoalbum-api (Microsoft.App/containerApps)
  - photoalbumregistry (Microsoft.ContainerRegistry/registries)

Checking for PostgreSQL Flexible Server...
✓ Found PostgreSQL Flexible Server(s):
  - Name: photoalbum-db-primary
    Status: Ready
    Version: 15
    FQDN: photoalbum-db-primary.postgres.database.azure.com
  - Name: photoalbum-db-replica
    Status: Ready
    Version: 15
    FQDN: photoalbum-db-replica.postgres.database.azure.com

Checking for Azure Container Apps...
✓ Found Container App(s):
  - Name: photoalbum-app
    Status: Succeeded
    FQDN: photoalbum-app.nicemeadow-98765432.eastus2.azurecontainerapps.io
  - Name: photoalbum-api
    Status: Succeeded
    FQDN: photoalbum-api.nicemeadow-98765432.eastus2.azurecontainerapps.io

Checking for Azure App Service...
⚠ No App Service found

Checking for Azure Container Registry...
✓ Found Container Registry(ies):
  - Name: photoalbumregistry
    Login Server: photoalbumregistry.azurecr.io
    SKU: Premium

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

============================================================
```

**Status**: ✅ Ready for deployment with redundancy!

---

## Color Coding in Terminal

When run in a terminal that supports ANSI colors:

- 🟢 **Green (✓)**: Resource found / Check passed
- 🔴 **Red (❌)**: Required resource missing / Check failed
- 🟡 **Yellow (⚠)**: Optional resource missing / Warning
- 🔵 **Blue (ℹ)**: Informational message
- **Bold**: Headers and important sections

---

## Exit Codes

- **0**: All required resources found (deployment ready)
- **1**: Missing required resources or error occurred

This allows the scripts to be used in automated workflows and CI/CD pipelines.
