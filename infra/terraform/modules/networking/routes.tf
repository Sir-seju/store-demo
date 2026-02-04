# ==============================================================================
# Azure Networking Module - Route Tables
# ==============================================================================
# Equivalent to AWS Route Tables
# Note: Azure NAT Gateway uses subnet association, not route tables
# These route tables are for custom routing scenarios (e.g., forced tunneling)
# ==============================================================================

# -----------------------------------------------------------------------------
# AKS Subnet Route Table
# Default routes are automatic in Azure; this is for custom scenarios
# AWS equivalent: Private route table with 0.0.0.0/0 → NAT Gateway
# -----------------------------------------------------------------------------
resource "azurerm_route_table" "aks" {
  name                          = "${var.vnet_config.name}-aks-rt"
  location                      = var.vnet_config.location
  resource_group_name           = var.vnet_config.resource_group_name
  bgp_route_propagation_enabled = true

  # Default route to Internet (handled by NAT Gateway association)
  # Only needed if you want explicit control or forced tunneling
  # route {
  #   name           = "default"
  #   address_prefix = "0.0.0.0/0"
  #   next_hop_type  = "Internet"
  # }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.aks.id
}

# -----------------------------------------------------------------------------
# VM Subnet Route Table
# -----------------------------------------------------------------------------
resource "azurerm_route_table" "vm" {
  name                          = "${var.vnet_config.name}-vm-rt"
  location                      = var.vnet_config.location
  resource_group_name           = var.vnet_config.resource_group_name
  bgp_route_propagation_enabled = true

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "vm" {
  subnet_id      = azurerm_subnet.vm.id
  route_table_id = azurerm_route_table.vm.id
}

# -----------------------------------------------------------------------------
# Database Subnet Route Table (Isolated - No Internet Route)
# AWS equivalent: Database route table with NO NAT Gateway route
# -----------------------------------------------------------------------------
resource "azurerm_route_table" "db" {
  name                          = "${var.vnet_config.name}-db-rt"
  location                      = var.vnet_config.location
  resource_group_name           = var.vnet_config.resource_group_name
  bgp_route_propagation_enabled = true

  # Explicitly block internet-bound traffic (defense in depth)
  route {
    name           = "block-internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "None"
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "db" {
  subnet_id      = azurerm_subnet.db.id
  route_table_id = azurerm_route_table.db.id
}
