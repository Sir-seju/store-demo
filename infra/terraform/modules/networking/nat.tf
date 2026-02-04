# ==============================================================================
# Azure Networking Module - NAT Gateway
# ==============================================================================
# Equivalent to AWS NAT Gateway
# Key difference: Azure NAT Gateway provides automatic zone redundancy
# No need for per-AZ NAT Gateways like in AWS
# ==============================================================================

# -----------------------------------------------------------------------------
# Public IP for NAT Gateway
# AWS equivalent: Elastic IP for NAT Gateway
# -----------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  count = var.vnet_config.enable_nat_gateway ? 1 : 0

  name                = "${var.vnet_config.name}-nat-pip"
  location            = var.vnet_config.location
  resource_group_name = var.vnet_config.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"] # Zone-redundant

  tags = merge(var.tags, { Name = "${var.vnet_config.name}-nat-pip" })
}

# -----------------------------------------------------------------------------
# NAT Gateway
# AWS equivalent: aws_nat_gateway
# Provides outbound internet for private subnets without public IPs
# -----------------------------------------------------------------------------
resource "azurerm_nat_gateway" "main" {
  count = var.vnet_config.enable_nat_gateway ? 1 : 0

  name                    = "${var.vnet_config.name}-nat-gateway"
  location                = var.vnet_config.location
  resource_group_name     = var.vnet_config.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"] # NAT Gateway in Zone 1

  tags = merge(var.tags, { Name = "${var.vnet_config.name}-nat-gateway" })
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = var.vnet_config.enable_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

# -----------------------------------------------------------------------------
# Associate NAT Gateway with Subnets
# AWS equivalent: Route table entries pointing to NAT Gateway
# Azure uses direct subnet association instead of route tables for NAT
# -----------------------------------------------------------------------------

# AKS Subnet → NAT Gateway
resource "azurerm_subnet_nat_gateway_association" "aks" {
  count = var.vnet_config.enable_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# VM Subnet → NAT Gateway
resource "azurerm_subnet_nat_gateway_association" "vm" {
  count = var.vnet_config.enable_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.vm.id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# NOTE: Database subnet intentionally NOT associated with NAT Gateway
# This matches the AWS pattern where database subnets are isolated
# PostgreSQL Flexible Server in VNet can still reach Azure services via service endpoints
