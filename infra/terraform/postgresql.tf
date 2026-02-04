# ==============================================================================
# Azure PostgreSQL Flexible Server
# ==============================================================================
# Replaces Cosmos DB for cost savings
# AWS Equivalent: RDS PostgreSQL or Aurora PostgreSQL
# ==============================================================================

variable "deploy_postgresql" {
  description = "Deploy PostgreSQL Flexible Server"
  type        = string
  default     = "false"
}

variable "postgresql_sku" {
  description = "PostgreSQL SKU (B_Standard_B1ms = cheapest at ~$12/mo)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768  # 32GB minimum
}

locals {
  deploy_postgresql = var.deploy_postgresql == "true" ? true : false
}

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "main" {
  count = local.deploy_postgresql ? 1 : 0

  name                   = "psql-${local.name}"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  version                = "16"
  administrator_login    = "psqladmin"
  administrator_password = random_password.postgres[0].result
  zone                   = "1"

  # Use our custom networking
  delegated_subnet_id = local.deploy_networking ? module.networking[0].db_subnet_id : null
  private_dns_zone_id = local.deploy_networking ? azurerm_private_dns_zone.postgres[0].id : null

  # Cost-optimized tier
  sku_name   = var.postgresql_sku
  storage_mb = var.postgresql_storage_mb

  # Backup settings (cheaper)
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# -----------------------------------------------------------------------------
# Random Password for PostgreSQL
# -----------------------------------------------------------------------------
resource "random_password" "postgres" {
  count   = local.deploy_postgresql ? 1 : 0
  length  = 24
  special = true
}

# -----------------------------------------------------------------------------
# Private DNS Zone (Required for VNet integration)
# -----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "postgres" {
  count               = local.deploy_postgresql && local.deploy_networking ? 1 : 0
  name                = "${local.name}.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                 = local.deploy_postgresql && local.deploy_networking ? 1 : 0
  name                  = "postgres-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  resource_group_name   = azurerm_resource_group.example.name
  virtual_network_id    = module.networking[0].vnet_id
}

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_database" "orderdb" {
  count     = local.deploy_postgresql ? 1 : 0
  name      = "orderdb"
  server_id = azurerm_postgresql_flexible_server.main[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "POSTGRESQL_HOST" {
  value     = local.deploy_postgresql ? azurerm_postgresql_flexible_server.main[0].fqdn : ""
  sensitive = false
}

output "POSTGRESQL_DATABASE" {
  value = local.deploy_postgresql ? "orderdb" : ""
}

output "POSTGRESQL_USER" {
  value     = local.deploy_postgresql ? azurerm_postgresql_flexible_server.main[0].administrator_login : ""
  sensitive = false
}

output "POSTGRESQL_PASSWORD" {
  value     = local.deploy_postgresql ? random_password.postgres[0].result : ""
  sensitive = true
}
