# ==============================================================================
# Key Vault Module Outputs
# ==============================================================================

output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI (for applications to connect)"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "workload_identity_client_id" {
  description = "Client ID of the Workload Identity (use in K8s ServiceAccount annotation)"
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID of the Workload Identity"
  value       = azurerm_user_assigned_identity.workload.principal_id
}
