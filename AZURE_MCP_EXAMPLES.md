# Azure MCP Integration Examples

This document provides examples of how to use Azure MCP (Model Context Protocol) to check Azure resources programmatically.

## What is Azure MCP?

Azure MCP is a Model Context Protocol implementation that provides a standardized interface for AI assistants and tools to interact with Azure services. It enables:

- Querying Azure resources through a consistent API
- Authentication management
- Resource discovery and validation
- Automated resource checks

## Using Azure MCP with Copilot/AI Assistants

When working with GitHub Copilot or other AI assistants that support MCP, you can use natural language to check Azure resources:

### Example Queries

1. **List subscriptions**
   ```
   Show me all my Azure subscriptions
   ```

2. **List resource groups**
   ```
   List all resource groups in my subscription
   ```

3. **Check specific resources**
   ```
   Check if my resource group 'photoalbum-rg' has a PostgreSQL server
   ```

4. **Verify deployment readiness**
   ```
   Verify if resource group 'photoalbum-rg' has all resources needed to deploy my PhotoAlbum app
   ```

## Using Azure MCP Tools Directly

If you have access to the Azure MCP server tools, you can call them directly:

### 1. List Subscriptions

```javascript
// Using the Azure MCP subscription_list tool
AzureMCPServer-subscription_list({
    intent: "List all Azure subscriptions available to the current user"
})
```

**Expected Response:**
```json
{
    "subscriptions": [
        {
            "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
            "displayName": "My Azure Subscription",
            "state": "Enabled",
            "tenantId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
            "isDefault": true
        }
    ]
}
```

### 2. List Resource Groups

```javascript
// Using the Azure MCP group_list tool
AzureMCPServer-group_list({
    intent: "List all resource groups in subscription",
    subscription: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
})
```

**Expected Response:**
```json
{
    "resourceGroups": [
        {
            "name": "photoalbum-rg",
            "location": "eastus",
            "provisioningState": "Succeeded"
        }
    ]
}
```

### 3. Check PostgreSQL Servers

```javascript
// Using the Azure MCP postgres tool
AzureMCPServer-postgres({
    intent: "List PostgreSQL flexible servers in resource group",
    command: "flexible-server list",
    parameters: {
        "resource-group": "photoalbum-rg",
        subscription: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
})
```

**Expected Response:**
```json
{
    "servers": [
        {
            "name": "photoalbum-db",
            "state": "Ready",
            "version": "15",
            "fullyQualifiedDomainName": "photoalbum-db.postgres.database.azure.com"
        }
    ]
}
```

### 4. Check Container Apps

```javascript
// Using the Azure MCP appservice tool for Container Apps
AzureMCPServer-appservice({
    intent: "List Azure Container Apps in resource group",
    command: "containerapp list",
    parameters: {
        "resource-group": "photoalbum-rg",
        subscription: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
})
```

### 5. Check App Service Web Apps

```javascript
// Using the Azure MCP appservice tool for Web Apps
AzureMCPServer-appservice({
    intent: "List Azure App Service web apps in resource group",
    command: "webapp list",
    parameters: {
        "resource-group": "photoalbum-rg",
        subscription: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
})
```

### 6. Check Container Registry

```javascript
// Using the Azure MCP acr tool
AzureMCPServer-acr({
    intent: "List Azure Container Registries in resource group",
    command: "list",
    parameters: {
        "resource-group": "photoalbum-rg",
        subscription: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
})
```

## Complete Verification Workflow

Here's a complete workflow for verifying resources using Azure MCP:

```javascript
// Step 1: Get available subscriptions
const subscriptions = await AzureMCPServer-subscription_list({
    intent: "List all Azure subscriptions"
});

// Step 2: Select subscription and list resource groups
const resourceGroups = await AzureMCPServer-group_list({
    intent: "List resource groups",
    subscription: subscriptions[0].subscriptionId
});

// Step 3: Check for required resources
const resourceGroup = "photoalbum-rg";
const subscriptionId = subscriptions[0].subscriptionId;

// Check PostgreSQL
const postgresServers = await AzureMCPServer-postgres({
    intent: "List PostgreSQL servers",
    command: "flexible-server list",
    parameters: {
        "resource-group": resourceGroup,
        subscription: subscriptionId
    }
});

// Check Container Apps
const containerApps = await AzureMCPServer-appservice({
    intent: "List Container Apps",
    command: "containerapp list",
    parameters: {
        "resource-group": resourceGroup,
        subscription: subscriptionId
    }
});

// Check App Service
const webApps = await AzureMCPServer-appservice({
    intent: "List Web Apps",
    command: "webapp list",
    parameters: {
        "resource-group": resourceGroup,
        subscription: subscriptionId
    }
});

// Check Container Registry
const registries = await AzureMCPServer-acr({
    intent: "List Container Registries",
    command: "list",
    parameters: {
        "resource-group": resourceGroup,
        subscription: subscriptionId
    }
});

// Step 4: Validate results
const hasPostgres = postgresServers && postgresServers.length > 0;
const hasContainerHost = (containerApps && containerApps.length > 0) || 
                         (webApps && webApps.length > 0);
const hasRegistry = registries && registries.length > 0;

// Step 5: Report results
if (hasPostgres && hasContainerHost) {
    console.log("✓ Resource group has all required resources");
} else {
    console.log("✗ Missing required resources:");
    if (!hasPostgres) console.log("  - PostgreSQL Flexible Server");
    if (!hasContainerHost) console.log("  - Container Apps or App Service");
}

if (!hasRegistry) {
    console.log("⚠ Optional: Container Registry not found");
}
```

## Error Handling

When using Azure MCP, handle authentication and authorization errors:

```javascript
try {
    const result = await AzureMCPServer-subscription_list({
        intent: "List subscriptions"
    });
    
    if (result.status === 401) {
        console.error("Authentication failed. Please run: az login");
        return;
    }
    
    if (result.status === 403) {
        console.error("Authorization failed. Insufficient permissions.");
        return;
    }
    
    // Process successful result
    console.log("Subscriptions:", result.subscriptions);
    
} catch (error) {
    console.error("Error querying Azure:", error.message);
}
```

## Best Practices

1. **Authentication First**: Always verify authentication before making MCP calls
2. **Cache Results**: Cache subscription and resource group lists to reduce API calls
3. **Error Handling**: Implement robust error handling for network and auth failures
4. **Pagination**: For large result sets, implement pagination
5. **Rate Limiting**: Respect Azure API rate limits
6. **Logging**: Log all MCP operations for debugging and audit purposes

## Integration with CI/CD

Azure MCP can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
name: Verify Azure Resources

on:
  push:
    branches: [ main ]

jobs:
  verify-resources:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Verify Resources
        run: |
          python check-azure-resources.py \
            --subscription ${{ secrets.AZURE_SUBSCRIPTION_ID }} \
            --resource-group ${{ secrets.AZURE_RESOURCE_GROUP }}
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Solution: Run `az login` and ensure credentials are valid
   - For service principals: Set `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`

2. **Permission Errors**
   - Solution: Ensure account has at least Reader role on the resource group
   - Check: `az role assignment list --assignee <user-email>`

3. **Resource Not Found**
   - Solution: Verify resource group name (case-sensitive)
   - Check subscription context: `az account show`

4. **Timeout Errors**
   - Solution: Check network connectivity
   - Increase timeout values in MCP configuration

## Additional Resources

- [Azure MCP Documentation](https://github.com/microsoft/azure-mcp)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure REST API Reference](https://docs.microsoft.com/en-us/rest/api/azure/)
