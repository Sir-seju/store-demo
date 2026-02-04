# ==============================================================================
# Azure Networking Module - Outputs
# ==============================================================================
# Expose resource IDs for downstream modules (AKS, VM, PostgreSQL)
# AWS equivalent: VPC module outputs for subnet_ids, vpc_id, etc.
# ==============================================================================

# -----------------------------------------------------------------------------
# VNet Outputs
# -----------------------------------------------------------------------------
output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "The address space of the Virtual Network"
  value       = azurerm_virtual_network.main.address_space
}

# -----------------------------------------------------------------------------
# Subnet Outputs
# -----------------------------------------------------------------------------
output "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "The name of the AKS subnet"
  value       = azurerm_subnet.aks.name
}

output "vm_subnet_id" {
  description = "The ID of the VM subnet"
  value       = azurerm_subnet.vm.id
}

output "vm_subnet_name" {
  description = "The name of the VM subnet"
  value       = azurerm_subnet.vm.name
}

output "db_subnet_id" {
  description = "The ID of the database subnet (delegated to PostgreSQL)"
  value       = azurerm_subnet.db.id
}

output "db_subnet_name" {
  description = "The name of the database subnet"
  value       = azurerm_subnet.db.name
}

output "private_link_subnet_id" {
  description = "The ID of the Private Link subnet"
  value       = azurerm_subnet.private_link.id
}

output "private_link_subnet_name" {
  description = "The name of the Private Link subnet"
  value       = azurerm_subnet.private_link.name
}

output "bastion_subnet_id" {
  description = "The ID of the Azure Bastion subnet (if enabled)"
  value       = var.vnet_config.enable_bastion ? azurerm_subnet.bastion[0].id : null
}

# -----------------------------------------------------------------------------
# NSG Outputs
# -----------------------------------------------------------------------------
output "aks_nsg_id" {
  description = "The ID of the AKS NSG"
  value       = azurerm_network_security_group.aks.id
}

output "vm_nsg_id" {
  description = "The ID of the VM NSG"
  value       = azurerm_network_security_group.vm.id
}

output "db_nsg_id" {
  description = "The ID of the database NSG"
  value       = azurerm_network_security_group.db.id
}

# -----------------------------------------------------------------------------
# NAT Gateway Outputs
# -----------------------------------------------------------------------------
output "nat_gateway_id" {
  description = "The ID of the NAT Gateway (if enabled)"
  value       = var.vnet_config.enable_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "The public IP address of the NAT Gateway"
  value       = var.vnet_config.enable_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}

# -----------------------------------------------------------------------------
# Bastion Outputs
# -----------------------------------------------------------------------------
output "bastion_host_id" {
  description = "The ID of the Azure Bastion host (if enabled)"
  value       = var.vnet_config.enable_bastion ? azurerm_bastion_host.main[0].id : null
}

output "bastion_host_dns_name" {
  description = "The DNS name of the Azure Bastion host"
  value       = var.vnet_config.enable_bastion ? azurerm_bastion_host.main[0].dns_name : null
}

# -----------------------------------------------------------------------------
# Flow Logs Outputs
# -----------------------------------------------------------------------------
output "flow_logs_storage_account_id" {
  description = "The ID of the storage account for flow logs"
  value       = var.vnet_config.enable_flow_logs ? azurerm_storage_account.flow_logs[0].id : null
}
