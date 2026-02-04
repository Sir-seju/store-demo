# ==============================================================================
# Azure Networking Module - Variables
# ==============================================================================
# Enterprise-grade VNet configuration following AWS VPC patterns
# ==============================================================================

variable "vnet_config" {
  description = "Virtual Network configuration"
  type = object({
    name                = string
    address_space       = list(string)
    location            = string
    resource_group_name = string

    subnets = object({
      aks_cidr          = string                 # Large for Azure CNI (pods need IPs)
      vm_cidr           = string                 # Monolith VM subnet
      db_cidr           = string                 # PostgreSQL (delegated subnet)
      private_link_cidr = string                 # Private Endpoints
      bastion_cidr      = optional(string, null) # Azure Bastion (must be /26+)
    })

    enable_nat_gateway = optional(bool, true)
    enable_flow_logs   = optional(bool, true)
    enable_bastion     = optional(bool, false)
  })
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 7
}
