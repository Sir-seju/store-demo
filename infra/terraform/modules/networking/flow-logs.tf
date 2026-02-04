# ==============================================================================
# Azure Networking Module - NSG Flow Logs
# ==============================================================================
# Equivalent to AWS VPC Flow Logs
# Key difference: Azure flow logs attach to NSGs, not VNets
# Logs stored in Storage Account (cheaper) or Log Analytics (better querying)
#
# COST NOTE: Flow logs require a Storage Account (~$0.02/GB) and optional
# Traffic Analytics requires Log Analytics (~$2.30/GB ingested)
# ==============================================================================

# -----------------------------------------------------------------------------
# Storage Account for Flow Logs
# AWS equivalent: CloudWatch Log Group or S3 bucket
# -----------------------------------------------------------------------------
resource "azurerm_storage_account" "flow_logs" {
  count = var.vnet_config.enable_flow_logs ? 1 : 0

  name                     = replace("${substr(var.vnet_config.name, 0, 16)}flowlogs", "-", "")
  location                 = var.vnet_config.location
  resource_group_name      = var.vnet_config.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Network Watcher (Required for Flow Logs)
# Azure automatically creates one per region, but we ensure it exists
# -----------------------------------------------------------------------------
data "azurerm_network_watcher" "main" {
  count = var.vnet_config.enable_flow_logs ? 1 : 0

  name                = "NetworkWatcher_${var.vnet_config.location}"
  resource_group_name = "NetworkWatcherRG"
}

# -----------------------------------------------------------------------------
# NSG Flow Logs
# AWS equivalent: aws_flow_log
# Created for each NSG to capture network traffic
# NOTE: Traffic Analytics disabled to save costs (requires Log Analytics)
# -----------------------------------------------------------------------------
resource "azurerm_network_watcher_flow_log" "aks" {
  count = var.vnet_config.enable_flow_logs ? 1 : 0

  name                 = "${var.vnet_config.name}-aks-flow-log"
  network_watcher_name = data.azurerm_network_watcher.main[0].name
  resource_group_name  = "NetworkWatcherRG"
  location             = var.vnet_config.location

  network_security_group_id = azurerm_network_security_group.aks.id
  storage_account_id        = azurerm_storage_account.flow_logs[0].id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  # Traffic Analytics disabled by default (requires Log Analytics Workspace = $$$)
  # Uncomment and provide workspace details if you want deeper insights

  tags = var.tags
}

resource "azurerm_network_watcher_flow_log" "vm" {
  count = var.vnet_config.enable_flow_logs ? 1 : 0

  name                 = "${var.vnet_config.name}-vm-flow-log"
  network_watcher_name = data.azurerm_network_watcher.main[0].name
  resource_group_name  = "NetworkWatcherRG"
  location             = var.vnet_config.location

  network_security_group_id = azurerm_network_security_group.vm.id
  storage_account_id        = azurerm_storage_account.flow_logs[0].id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  tags = var.tags
}

resource "azurerm_network_watcher_flow_log" "db" {
  count = var.vnet_config.enable_flow_logs ? 1 : 0

  name                 = "${var.vnet_config.name}-db-flow-log"
  network_watcher_name = data.azurerm_network_watcher.main[0].name
  resource_group_name  = "NetworkWatcherRG"
  location             = var.vnet_config.location

  network_security_group_id = azurerm_network_security_group.db.id
  storage_account_id        = azurerm_storage_account.flow_logs[0].id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  tags = var.tags
}
