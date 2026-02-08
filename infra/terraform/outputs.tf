output "AZURE_TENANT_ID" {
  value = data.azurerm_client_config.current.tenant_id
}

output "AZURE_RESOURCENAME_SUFFIX" {
  value = local.name
}

output "AZURE_RESOURCE_GROUP" {
  value = azurerm_resource_group.example.name
}

output "AZURE_AKS_CLUSTER_NAME" {
  value = module.aks.name
}

output "AZURE_AKS_NAMESPACE" {
  value = var.k8s_namespace
}

output "AZURE_AKS_CLUSTER_ID" {
  value = module.aks.resource_id
}

output "AZURE_AKS_OIDC_ISSUER_URL" {
  value = module.aks.oidc_issuer_url
}

# TEMPORARILY DISABLED - module.aoai disabled
# output "AZURE_OPENAI_ENDPOINT" {
#   value = local.deploy_azure_openai ? module.aoai[0].endpoint : ""
# }

output "AZURE_OPENAI_MODEL_NAME" {
  value = local.deploy_azure_openai ? var.chat_completion_model_name : ""
}

output "AZURE_OPENAI_DALL_E_MODEL_NAME" {
  value = local.deploy_image_generation_model ? var.image_generation_model_name : ""
}

# TEMPORARILY DISABLED - module.aoai disabled
# output "AZURE_OPENAI_DALL_E_ENDPOINT" {
#   value = local.deploy_image_generation_model ? module.aoai[0].endpoint : ""
# }

output "AZURE_IDENTITY_NAME" {
  value = local.deploy_azure_openai || local.deploy_azure_servicebus || local.deploy_azure_cosmosdb ? azurerm_user_assigned_identity.example[0].name : ""
}

output "AZURE_IDENTITY_CLIENT_ID" {
  value = local.deploy_azure_openai || local.deploy_azure_servicebus || local.deploy_azure_cosmosdb ? azurerm_user_assigned_identity.example[0].client_id : ""
}

output "AZURE_SERVICE_BUS_HOST" {
  value = local.deploy_azure_servicebus ? "sb-${local.name}.servicebus.windows.net" : ""
}

output "AZURE_SERVICE_BUS_URI" {
  value     = local.deploy_azure_servicebus ? "amqps://sb-${local.name}.servicebus.windows.net" : ""
  sensitive = true
}

output "AZURE_COSMOS_DATABASE_NAME" {
  value = local.deploy_azure_cosmosdb ? module.db[0].name : ""
}

output "AZURE_COSMOS_DATABASE_URI" {
  value = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "MongoDB" ? "mongodb://${module.db[0].name}.mongo.cosmos.azure.com:10255/?retryWrites=false" : local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "GlobalDocumentDB" ? "https://${module.db[0].name}.documents.azure.com:443/" : ""
}

output "AZURE_COSMOS_DATABASE_LIST_CONNECTIONSTRINGS_URL" {
  value = local.deploy_azure_cosmosdb ? "https://management.azure.com${module.db[0].resource_id}/listConnectionStrings?api-version=2021-04-15" : ""
}

output "AZURE_DATABASE_API" {
  value = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "MongoDB" ? "mongodb" : local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "GlobalDocumentDB" ? "cosmosdbsql" : ""
}

output "AZURE_CONTAINER_REGISTRY_NAME" {
  value = local.deploy_azure_container_registry ? module.acr[0].name : ""
}

output "AZURE_CONTAINER_REGISTRY_ENDPOINT" {
  value = local.deploy_azure_container_registry ? module.acr[0].resource.login_server : ""
}

output "SOURCE_REGISTRY" {
  value = local.deploy_azure_container_registry ? module.acr[0].resource.login_server : local.source_registry
}

output "DEPLOY_AZURE_CONTAINER_REGISTRY" {
  value = local.deploy_azure_container_registry
}

output "DEPLOY_AZURE_SERVICE_BUS" {
  value = local.deploy_azure_servicebus
}

output "DEPLOY_AZURE_COSMOSDB" {
  value = local.deploy_azure_cosmosdb
}

output "DEPLOY_AZURE_OPENAI" {
  value = local.deploy_azure_openai
}

# -----------------------------------------------------------------------------
# Networking Outputs
# -----------------------------------------------------------------------------
output "AZURE_VNET_ID" {
  value = local.deploy_networking ? module.networking[0].vnet_id : ""
}

output "AZURE_AKS_SUBNET_ID" {
  value = local.deploy_networking ? module.networking[0].aks_subnet_id : ""
}

output "AZURE_NAT_PUBLIC_IP" {
  value = local.deploy_networking ? module.networking[0].nat_gateway_public_ip : ""
}

output "DEPLOY_NETWORKING" {
  value = local.deploy_networking
}

output "DEPLOY_POSTGRESQL" {
  value = local.deploy_postgresql
}

# -----------------------------------------------------------------------------
# Key Vault Outputs
# -----------------------------------------------------------------------------
output "AZURE_KEY_VAULT_URI" {
  value       = module.keyvault.key_vault_uri
  description = "Key Vault URI for applications to fetch secrets"
}

output "AZURE_KEY_VAULT_NAME" {
  value       = module.keyvault.key_vault_name
  description = "Key Vault name"
}

output "AZURE_WORKLOAD_IDENTITY_CLIENT_ID" {
  value       = module.keyvault.workload_identity_client_id
  description = "Client ID for Workload Identity (use in K8s ServiceAccount)"
}

