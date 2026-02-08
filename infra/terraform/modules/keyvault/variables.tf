# ==============================================================================
# Key Vault Module Variables
# ==============================================================================

variable "name_prefix" {
  description = "Prefix for resource names (e.g., 'devcattle65')"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "current_user_object_id" {
  description = "Object ID of the current user (for granting Key Vault admin access)"
  type        = string
}

variable "oidc_issuer_url" {
  description = "AKS OIDC issuer URL for federated credentials"
  type        = string
}

variable "federated_credentials" {
  description = "Map of federated credentials to create (K8s ServiceAccount → Azure Identity)"
  type = map(object({
    namespace            = string
    service_account_name = string
  }))
  default = {}
}

variable "mongodb_connection" {
  description = "MongoDB connection string to store in Key Vault"
  type        = string
  default     = ""
  sensitive   = true
}

variable "rabbitmq_uri" {
  description = "RabbitMQ URI to store in Key Vault"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
