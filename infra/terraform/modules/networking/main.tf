# ==============================================================================
# Azure Networking Module - VNet and Subnets
# ==============================================================================
# Equivalent to AWS VPC module with public/private/database subnet tiers
# Key difference: Azure subnets span ALL availability zones by default
# ==============================================================================

# -----------------------------------------------------------------------------
# Virtual Network (AWS equivalent: aws_vpc)
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_config.name
  location            = var.vnet_config.location
  resource_group_name = var.vnet_config.resource_group_name
  address_space       = var.vnet_config.address_space

  tags = merge(var.tags, { Name = var.vnet_config.name })
}

# -----------------------------------------------------------------------------
# AKS Subnet (AWS equivalent: Private subnets combined)
# Large CIDR needed for Azure CNI - each pod gets a real IP
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "aks" {
  name                 = "${var.vnet_config.name}-aks-subnet"
  resource_group_name  = var.vnet_config.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.vnet_config.subnets.aks_cidr]

  # Required for AKS with Azure CNI
  service_endpoints = [
    "Microsoft.ContainerRegistry",
    "Microsoft.KeyVault",
    "Microsoft.Storage"
  ]
}

# -----------------------------------------------------------------------------
# VM Subnet (Monolith Application)
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "vm" {
  name                 = "${var.vnet_config.name}-vm-subnet"
  resource_group_name  = var.vnet_config.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.vnet_config.subnets.vm_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Storage"
  ]
}

# -----------------------------------------------------------------------------
# Database Subnet (PostgreSQL Flexible Server - Delegated)
# AWS equivalent: Database subnets (isolated tier)
# Azure requires subnet delegation for PostgreSQL Flexible Server
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "db" {
  name                 = "${var.vnet_config.name}-db-subnet"
  resource_group_name  = var.vnet_config.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.vnet_config.subnets.db_cidr]

  # Delegation required for PostgreSQL Flexible Server VNet integration
  delegation {
    name = "postgresql-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }

  service_endpoints = ["Microsoft.Storage"]
}

# -----------------------------------------------------------------------------
# Private Link Subnet (AWS equivalent: VPC Interface Endpoints)
# Used for Private Endpoints to Azure PaaS services
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "private_link" {
  name                 = "${var.vnet_config.name}-private-link-subnet"
  resource_group_name  = var.vnet_config.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.vnet_config.subnets.private_link_cidr]

  # Disable private endpoint network policies for Private Endpoints
  private_endpoint_network_policies = "Disabled"
}

# -----------------------------------------------------------------------------
# Azure Bastion Subnet (AWS equivalent: Bastion host in public subnet)
# Provides secure RDP/SSH access without public IPs on VMs
# Subnet name MUST be "AzureBastionSubnet" (Azure requirement)
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "bastion" {
  count = var.vnet_config.enable_bastion && var.vnet_config.subnets.bastion_cidr != null ? 1 : 0

  name                 = "AzureBastionSubnet" # Required name by Azure
  resource_group_name  = var.vnet_config.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.vnet_config.subnets.bastion_cidr]
}

# -----------------------------------------------------------------------------
# Azure Bastion Host (Optional)
# -----------------------------------------------------------------------------
resource "azurerm_public_ip" "bastion" {
  count = var.vnet_config.enable_bastion && var.vnet_config.subnets.bastion_cidr != null ? 1 : 0

  name                = "${var.vnet_config.name}-bastion-pip"
  location            = var.vnet_config.location
  resource_group_name = var.vnet_config.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_bastion_host" "main" {
  count = var.vnet_config.enable_bastion && var.vnet_config.subnets.bastion_cidr != null ? 1 : 0

  name                = "${var.vnet_config.name}-bastion"
  location            = var.vnet_config.location
  resource_group_name = var.vnet_config.resource_group_name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = var.tags
}
