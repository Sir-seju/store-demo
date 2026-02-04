#!/bin/bash
# ==============================================================================
# Azure Terraform State Backend Bootstrap
# ==============================================================================
# Equivalent to AWS CloudFormation bootstrap for S3 + DynamoDB
# Creates: Resource Group, Storage Account, Blob Container
# 
# Azure difference: No DynamoDB needed - Blob storage has built-in lease locking
# ==============================================================================

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
LOCATION="eastus"
RESOURCE_GROUP_NAME="tfstate-rg"
STORAGE_ACCOUNT_NAME="tfstate$(openssl rand -hex 4)"  # Must be globally unique
CONTAINER_NAME="tfstate"

echo "=============================================="
echo "Azure Terraform State Backend Bootstrap"
echo "=============================================="
echo ""
echo "Configuration:"
echo "  Location:         $LOCATION"
echo "  Resource Group:   $RESOURCE_GROUP_NAME"
echo "  Storage Account:  $STORAGE_ACCOUNT_NAME"
echo "  Container:        $CONTAINER_NAME"
echo ""

# -----------------------------------------------------------------------------
# Create Resource Group
# -----------------------------------------------------------------------------
echo "Creating Resource Group..."
az group create \
  --name "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --tags Purpose=TerraformState ManagedBy=Bootstrap

# -----------------------------------------------------------------------------
# Create Storage Account with Enterprise Security Settings
# -----------------------------------------------------------------------------
echo "Creating Storage Account with security hardening..."
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access true \
  --tags Purpose=TerraformState ManagedBy=Bootstrap

# Enable versioning (state file protection - like S3 versioning)
echo "Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --enable-versioning true

# Enable soft delete (recovery protection)
echo "Enabling soft delete..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --enable-delete-retention true \
  --delete-retention-days 7

# -----------------------------------------------------------------------------
# Create Blob Container
# -----------------------------------------------------------------------------
echo "Creating Blob Container..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --auth-mode login

# -----------------------------------------------------------------------------
# Output Backend Configuration
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "SUCCESS! Add this to your Terraform config:"
echo "=============================================="
echo ""
cat << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "rosetta.tfstate"
  }
}
EOF
echo ""
echo "=============================================="
echo "Storage Account Details:"
echo "=============================================="
echo "  Name: $STORAGE_ACCOUNT_NAME"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Features Enabled:"
echo "    - HTTPS only"
echo "    - TLS 1.2 minimum"
echo "    - Blob versioning"
echo "    - Soft delete (7 days)"
echo "    - No public blob access"
echo "=============================================="
