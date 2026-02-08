# ==============================================================================
# Key Vault Module for Secrets Management
# ==============================================================================
# 
# ARCHITECTURE THOUGHT PROCESS:
# 
# We're implementing "zero-secret infrastructure" - pods authenticate to 
# Azure services without any hardcoded credentials in code or environment vars.
#
# Flow:
# 1. Key Vault stores actual secrets (DB connection strings, API keys)
# 2. Workload Identity: Pod → K8s ServiceAccount → Federated Credential → Azure Identity
# 3. Azure Identity has RBAC permission to read Key Vault secrets
# 4. Application uses Azure SDK to fetch secrets at startup
#
# This is the Azure equivalent of AWS IRSA (IAM Roles for Service Accounts)
# ==============================================================================

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------
resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.name_prefix}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false # Set to true in production!
  soft_delete_retention_days  = 7

  # RBAC mode - no access policies, use Azure RBAC instead
  # This is the modern, recommended approach
  rbac_authorization_enabled = true

  # Network rules - allow all for dev (restrict in production)
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# User-Assigned Managed Identity for Workload Identity
# -----------------------------------------------------------------------------
# This identity will be federated with K8s ServiceAccounts
# Each pod using this ServiceAccount can assume this Azure identity
resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${var.name_prefix}-workload"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Grant the Workload Identity access to Key Vault secrets
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "workload_keyvault_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

# -----------------------------------------------------------------------------
# Federated Credentials - Link K8s ServiceAccounts to Azure Identity
# -----------------------------------------------------------------------------
# Each federated credential allows a specific K8s ServiceAccount (in a specific
# namespace) to authenticate as this Azure identity.
#
# This is the key to Workload Identity - no secrets exchanged, just OIDC tokens.
resource "azurerm_federated_identity_credential" "workload" {
  for_each = var.federated_credentials

  name                = each.key
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"
}

# -----------------------------------------------------------------------------
# Store secrets in Key Vault
# -----------------------------------------------------------------------------
# Note: We create individual resources instead of for_each because
# Terraform doesn't allow sensitive values in for_each keys.

resource "azurerm_key_vault_secret" "mongodb" {
  count = var.mongodb_connection != "" ? 1 : 0

  name         = "mongodb-connection"
  value        = var.mongodb_connection
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.current_user]
}

resource "azurerm_key_vault_secret" "rabbitmq" {
  count = var.rabbitmq_uri != "" ? 1 : 0

  name         = "rabbitmq-uri"
  value        = var.rabbitmq_uri
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.current_user]
}

# -----------------------------------------------------------------------------
# Grant current user (Terraform executor) access to create secrets
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "current_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.current_user_object_id
}
