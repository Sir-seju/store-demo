# ==============================================================================
# Azure Networking Module - Network Security Groups
# ==============================================================================
# Equivalent to AWS Security Groups module
# Key difference: Azure NSGs are attached to subnets OR NICs, and are stateful
# ==============================================================================

# -----------------------------------------------------------------------------
# AKS Subnet NSG
# AWS equivalent: EKS security group
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "aks" {
  name                = "${var.vnet_config.name}-aks-nsg"
  location            = var.vnet_config.location
  resource_group_name = var.vnet_config.resource_group_name

  # Allow HTTPS from VNet (internal services)
  security_rule {
    name                       = "AllowVNetHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow HTTP from VNet
  security_rule {
    name                       = "AllowVNetHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow all internal VNet traffic (pod-to-pod, node-to-node)
  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer health probes
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSG with AKS subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# -----------------------------------------------------------------------------
# VM Subnet NSG
# AWS equivalent: EC2/Bastion security group
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "vm" {
  name                = "${var.vnet_config.name}-vm-nsg"
  location            = var.vnet_config.location
  resource_group_name = var.vnet_config.resource_group_name

  # Allow SSH from Azure Bastion subnet only
  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.vnet_config.subnets.bastion_cidr != null ? var.vnet_config.subnets.bastion_cidr : "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow HTTP from internal VNet (AKS can reach monolith)
  security_rule {
    name                       = "AllowHTTPFromVNet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow HTTPS from internal VNet
  security_rule {
    name                       = "AllowHTTPSFromVNet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# -----------------------------------------------------------------------------
# Database Subnet NSG
# AWS equivalent: RDS security group (isolated)
# Only allows PostgreSQL (5432) from AKS and VM subnets
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "db" {
  name                = "${var.vnet_config.name}-db-nsg"
  location            = var.vnet_config.location
  resource_group_name = var.vnet_config.resource_group_name

  # Allow PostgreSQL from AKS subnet
  security_rule {
    name                       = "AllowPostgresFromAKS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.vnet_config.subnets.aks_cidr
    destination_address_prefix = "*"
  }

  # Allow PostgreSQL from VM subnet
  security_rule {
    name                       = "AllowPostgresFromVM"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.vnet_config.subnets.vm_cidr
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic (explicit for clarity)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

# -----------------------------------------------------------------------------
# Private Link Subnet NSG
# Minimal rules - Private Endpoints handle access
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "private_link" {
  name                = "${var.vnet_config.name}-private-link-nsg"
  location            = var.vnet_config.location
  resource_group_name = var.vnet_config.resource_group_name

  # Allow all VNet inbound (Private Endpoints are internal)
  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "private_link" {
  subnet_id                 = azurerm_subnet.private_link.id
  network_security_group_id = azurerm_network_security_group.private_link.id
}
