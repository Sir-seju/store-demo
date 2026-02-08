# ==============================================================================
# Main Infrastructure Configuration
# ==============================================================================

# -----------------------------------------------------------------------------
# Random Resources (for unique naming)
# -----------------------------------------------------------------------------
resource "random_integer" "example" {
  min = 10
  max = 99
}

resource "random_pet" "example" {
  length    = 1
  separator = ""
  keepers = {
    location = var.location
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
locals {
  name                            = "${var.environment}${random_pet.example.id}${random_integer.example.result}"
  aks_node_pool_vm_size           = var.aks_node_pool_vm_size != "" ? var.aks_node_pool_vm_size : "Standard_D2s_v4"
  deploy_azure_cosmosdb           = var.deploy_azure_cosmosdb == "true" ? true : false
  default_cosmosdb_account_kind   = "GlobalDocumentDB"
  cosmosdb_account_kind           = var.cosmosdb_account_kind != "" ? var.cosmosdb_account_kind : local.default_cosmosdb_account_kind
  deploy_observability_tools      = var.deploy_observability_tools == "true" ? true : false
  deploy_azure_container_registry = var.deploy_azure_container_registry == "true" ? true : false
  deploy_azure_openai             = var.deploy_azure_openai == "true" ? true : false
  deploy_image_generation_model   = var.deploy_image_generation_model == "true" ? true : false
  deploy_azure_servicebus         = var.deploy_azure_servicebus == "true" ? true : false
  deploy_networking               = var.deploy_networking == "true" && var.vnet_config != null ? true : false
  source_registry                 = var.source_registry != "" ? var.source_registry : "ghcr.io/azure-samples"
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "example" {
  name     = "rg-${local.name}"
  location = var.location
}

# -----------------------------------------------------------------------------
# Networking Module (Enterprise VNet)
# -----------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"
  count  = local.deploy_networking ? 1 : 0

  vnet_config = {
    name                = "vnet-${local.name}"
    address_space       = var.vnet_config.address_space
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name

    subnets = var.vnet_config.subnets

    enable_nat_gateway = var.vnet_config.enable_nat_gateway
    enable_flow_logs   = var.vnet_config.enable_flow_logs
    enable_bastion     = var.vnet_config.enable_bastion
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Key Vault Module (Secrets Management + Workload Identity)
# -----------------------------------------------------------------------------
# 
# ARCHITECTURE NOTES:
# - Key Vault stores secrets (DB connections, API keys)
# - Workload Identity allows pods to auth as Azure identity (no secrets in pods!)
# - Federated credentials link K8s ServiceAccounts to the Azure identity
# - This is the Azure equivalent of AWS IRSA
#
module "keyvault" {
  source = "./modules/keyvault"

  name_prefix            = local.name
  location               = azurerm_resource_group.example.location
  resource_group_name    = azurerm_resource_group.example.name
  tenant_id              = data.azurerm_client_config.current.tenant_id
  current_user_object_id = data.azurerm_client_config.current.object_id
  oidc_issuer_url        = module.aks.oidc_issuer_url

  # Federated credentials: which K8s ServiceAccounts can assume this identity
  federated_credentials = {
    "order-service" = {
      namespace            = "dev"
      service_account_name = "order-service"
    }
    "product-service" = {
      namespace            = "dev"
      service_account_name = "product-service"
    }
  }

  # Secrets to store in Key Vault
  mongodb_connection = var.mongodb_connection_string
  rabbitmq_uri       = var.rabbitmq_uri

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [module.aks]
}

