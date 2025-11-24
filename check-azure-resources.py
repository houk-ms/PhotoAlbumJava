#!/usr/bin/env python3
"""
Azure Resource Verification Script for PhotoAlbum Application

This script uses Azure CLI to check if a resource group has the necessary
resources to deploy the PhotoAlbum Java application.

Required Resources:
1. Azure Database for PostgreSQL Flexible Server
2. Azure Container Apps OR Azure App Service
3. Azure Container Registry (optional but recommended)

Usage:
    python check-azure-resources.py --subscription <subscription-id> --resource-group <rg-name>
    
    Or with environment variables:
    export AZURE_SUBSCRIPTION_ID=<subscription-id>
    export AZURE_RESOURCE_GROUP=<rg-name>
    python check-azure-resources.py
"""

import subprocess
import json
import sys
import argparse
import os


class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'


def run_az_command(command_args):
    """Execute an Azure CLI command and return the output
    
    Args:
        command_args: List of command arguments or string (for backward compatibility)
    """
    # Convert string to list if necessary (for compatibility)
    if isinstance(command_args, str):
        import shlex
        command_args = shlex.split(command_args)
    
    try:
        result = subprocess.run(
            command_args,
            shell=False,
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        # Don't print the full command for security
        print(f"{Colors.RED}Error executing Azure CLI command{Colors.END}")
        print(f"{Colors.RED}Error details: {e.stderr}{Colors.END}")
        return None


def check_azure_login():
    """Check if user is logged in to Azure CLI"""
    print(f"\n{Colors.BLUE}Checking Azure CLI authentication...{Colors.END}")
    result = run_az_command(["az", "account", "show"])
    if result is None:
        print(f"{Colors.RED}❌ Not logged in to Azure CLI{Colors.END}")
        print(f"{Colors.YELLOW}Please run: az login{Colors.END}")
        return False
    print(f"{Colors.GREEN}✓ Authenticated to Azure{Colors.END}")
    return True


def get_subscription_info(subscription_id=None):
    """Get current subscription information"""
    if subscription_id:
        run_az_command(["az", "account", "set", "--subscription", subscription_id])
    
    result = run_az_command(["az", "account", "show", "--output", "json"])
    if result:
        return json.loads(result)
    return None


def check_resource_group_exists(resource_group):
    """Check if the resource group exists"""
    print(f"\n{Colors.BLUE}Checking resource group '{resource_group}'...{Colors.END}")
    result = run_az_command(["az", "group", "show", "--name", resource_group, "--output", "json"])
    
    if result:
        rg_info = json.loads(result)
        print(f"{Colors.GREEN}✓ Resource group exists{Colors.END}")
        print(f"  Location: {rg_info.get('location', 'N/A')}")
        print(f"  Status: {rg_info.get('properties', {}).get('provisioningState', 'N/A')}")
        return True
    else:
        print(f"{Colors.RED}❌ Resource group '{resource_group}' not found{Colors.END}")
        return False


def list_resources_in_group(resource_group):
    """List all resources in the resource group"""
    print(f"\n{Colors.BLUE}Listing all resources in '{resource_group}'...{Colors.END}")
    result = run_az_command(["az", "resource", "list", "--resource-group", resource_group, "--output", "json"])
    
    if result:
        resources = json.loads(result)
        if resources:
            print(f"{Colors.GREEN}Found {len(resources)} resource(s):{Colors.END}")
            for resource in resources:
                print(f"  - {resource['name']} ({resource['type']})")
            return resources
        else:
            print(f"{Colors.YELLOW}⚠ Resource group is empty{Colors.END}")
            return []
    return []


def check_postgresql_server(resource_group):
    """Check for PostgreSQL Flexible Server"""
    print(f"\n{Colors.BLUE}Checking for PostgreSQL Flexible Server...{Colors.END}")
    result = run_az_command(
        ["az", "postgres", "flexible-server", "list", "--resource-group", resource_group, "--output", "json"]
    )
    
    if result:
        servers = json.loads(result)
        if servers:
            print(f"{Colors.GREEN}✓ Found PostgreSQL Flexible Server(s):{Colors.END}")
            for server in servers:
                print(f"  - Name: {server['name']}")
                print(f"    Status: {server.get('state', 'N/A')}")
                print(f"    Version: {server.get('version', 'N/A')}")
                print(f"    FQDN: {server.get('fullyQualifiedDomainName', 'N/A')}")
            return True
        
    print(f"{Colors.RED}❌ No PostgreSQL Flexible Server found{Colors.END}")
    print(f"{Colors.YELLOW}   Required for: Database storage{Colors.END}")
    return False


def check_container_apps(resource_group):
    """Check for Azure Container Apps"""
    print(f"\n{Colors.BLUE}Checking for Azure Container Apps...{Colors.END}")
    result = run_az_command(
        ["az", "containerapp", "list", "--resource-group", resource_group, "--output", "json"]
    )
    
    if result:
        apps = json.loads(result)
        if apps:
            print(f"{Colors.GREEN}✓ Found Container App(s):{Colors.END}")
            for app in apps:
                print(f"  - Name: {app['name']}")
                print(f"    Status: {app.get('properties', {}).get('provisioningState', 'N/A')}")
                print(f"    FQDN: {app.get('properties', {}).get('configuration', {}).get('ingress', {}).get('fqdn', 'N/A')}")
            return True
    
    print(f"{Colors.YELLOW}⚠ No Container Apps found{Colors.END}")
    return False


def check_app_service(resource_group):
    """Check for Azure App Service"""
    print(f"\n{Colors.BLUE}Checking for Azure App Service...{Colors.END}")
    result = run_az_command(
        ["az", "webapp", "list", "--resource-group", resource_group, "--output", "json"]
    )
    
    if result:
        apps = json.loads(result)
        if apps:
            print(f"{Colors.GREEN}✓ Found App Service(s):{Colors.END}")
            for app in apps:
                print(f"  - Name: {app['name']}")
                print(f"    Status: {app.get('state', 'N/A')}")
                print(f"    URL: https://{app.get('defaultHostName', 'N/A')}")
            return True
    
    print(f"{Colors.YELLOW}⚠ No App Service found{Colors.END}")
    return False


def check_container_registry(resource_group):
    """Check for Azure Container Registry"""
    print(f"\n{Colors.BLUE}Checking for Azure Container Registry...{Colors.END}")
    result = run_az_command(
        ["az", "acr", "list", "--resource-group", resource_group, "--output", "json"]
    )
    
    if result:
        registries = json.loads(result)
        if registries:
            print(f"{Colors.GREEN}✓ Found Container Registry(ies):{Colors.END}")
            for registry in registries:
                print(f"  - Name: {registry['name']}")
                print(f"    Login Server: {registry.get('loginServer', 'N/A')}")
                print(f"    SKU: {registry.get('sku', {}).get('name', 'N/A')}")
            return True
    
    print(f"{Colors.YELLOW}⚠ No Container Registry found (optional but recommended){Colors.END}")
    return False


def print_summary(checks):
    """Print a summary of the resource check results"""
    print(f"\n{Colors.BOLD}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}DEPLOYMENT READINESS SUMMARY{Colors.END}")
    print(f"{Colors.BOLD}{'='*60}{Colors.END}\n")
    
    required_resources = {
        'PostgreSQL Database': checks['postgresql'],
        'Container Hosting (Container Apps OR App Service)': checks['container_apps'] or checks['app_service']
    }
    
    optional_resources = {
        'Container Registry': checks['container_registry']
    }
    
    print(f"{Colors.BOLD}Required Resources:{Colors.END}")
    all_required_present = True
    for resource, present in required_resources.items():
        status = f"{Colors.GREEN}✓" if present else f"{Colors.RED}❌"
        print(f"  {status} {resource}{Colors.END}")
        if not present:
            all_required_present = False
    
    print(f"\n{Colors.BOLD}Optional Resources:{Colors.END}")
    for resource, present in optional_resources.items():
        status = f"{Colors.GREEN}✓" if present else f"{Colors.YELLOW}⚠"
        print(f"  {status} {resource}{Colors.END}")
    
    print(f"\n{Colors.BOLD}Deployment Status:{Colors.END}")
    if all_required_present:
        print(f"{Colors.GREEN}✓ Resource group has all required resources for deployment{Colors.END}")
        return True
    else:
        print(f"{Colors.RED}❌ Missing required resources - deployment will fail{Colors.END}")
        print(f"\n{Colors.YELLOW}Next Steps:{Colors.END}")
        if not checks['postgresql']:
            print(f"  • Create Azure Database for PostgreSQL Flexible Server")
        if not (checks['container_apps'] or checks['app_service']):
            print(f"  • Create Azure Container Apps or Azure App Service")
        if not checks['container_registry']:
            print(f"  • (Optional) Create Azure Container Registry for Docker images")
        return False


def main():
    """Main execution function"""
    parser = argparse.ArgumentParser(
        description='Check if Azure resource group has required resources for PhotoAlbum deployment'
    )
    parser.add_argument(
        '--subscription',
        help='Azure subscription ID (or set AZURE_SUBSCRIPTION_ID env var)',
        default=os.environ.get('AZURE_SUBSCRIPTION_ID')
    )
    parser.add_argument(
        '--resource-group',
        help='Azure resource group name (or set AZURE_RESOURCE_GROUP env var)',
        default=os.environ.get('AZURE_RESOURCE_GROUP')
    )
    
    args = parser.parse_args()
    
    print(f"\n{Colors.BOLD}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}PhotoAlbum Azure Resource Verification{Colors.END}")
    print(f"{Colors.BOLD}{'='*60}{Colors.END}")
    
    # Check Azure CLI authentication
    if not check_azure_login():
        sys.exit(1)
    
    # Get subscription info
    subscription_info = get_subscription_info(args.subscription)
    if not subscription_info:
        print(f"{Colors.RED}❌ Failed to get subscription information{Colors.END}")
        sys.exit(1)
    
    print(f"\n{Colors.BOLD}Current Subscription:{Colors.END}")
    print(f"  Name: {subscription_info.get('name', 'N/A')}")
    print(f"  ID: {subscription_info.get('id', 'N/A')}")
    
    # Validate resource group parameter
    if not args.resource_group:
        print(f"\n{Colors.RED}❌ Resource group name is required{Colors.END}")
        print(f"{Colors.YELLOW}Usage: python check-azure-resources.py --resource-group <name>{Colors.END}")
        print(f"{Colors.YELLOW}Or set: export AZURE_RESOURCE_GROUP=<name>{Colors.END}")
        sys.exit(1)
    
    # Check if resource group exists
    if not check_resource_group_exists(args.resource_group):
        sys.exit(1)
    
    # List all resources
    resources = list_resources_in_group(args.resource_group)
    
    # Check for specific required resources
    checks = {
        'postgresql': check_postgresql_server(args.resource_group),
        'container_apps': check_container_apps(args.resource_group),
        'app_service': check_app_service(args.resource_group),
        'container_registry': check_container_registry(args.resource_group)
    }
    
    # Print summary
    deployment_ready = print_summary(checks)
    
    print(f"\n{Colors.BOLD}{'='*60}{Colors.END}\n")
    
    sys.exit(0 if deployment_ready else 1)


if __name__ == '__main__':
    main()
