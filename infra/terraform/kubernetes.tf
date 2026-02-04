// https://github.com/Azure/terraform-azurerm-avm-res-containerregistry-registry/
module "acr" {
  count               = local.deploy_azure_container_registry ? 1 : 0
  source              = "Azure/avm-res-containerregistry-registry/azurerm"
  version             = "0.4.0"
  name                = "acr${local.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

// https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster/
module "aks" {
  source                    = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version                   = "0.1.7"
  name                      = "aks-${local.name}"
  resource_group_name       = azurerm_resource_group.example.name
  location                  = azurerm_resource_group.example.location
  node_os_channel_upgrade   = "SecurityPatch"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = true

  # API server access - TEMPORARILY DISABLED for initial cluster creation
  # Re-enable after cluster is running with:
  # authorized_ip_ranges = ["<your-ip>/32", "<nat-gateway-ip>/32"]
  # api_server_access_profile = {
  #   authorized_ip_ranges = local.deploy_networking ? [
  #     "${chomp(data.http.current_ip.response_body)}/32",
  #     "${module.networking[0].nat_gateway_public_ip}/32"
  #   ] : ["${chomp(data.http.current_ip.response_body)}/32"]
  # }

  azure_active_directory_role_based_access_control = {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  default_node_pool = {
    name       = "system"
    vm_size    = local.aks_node_pool_vm_size
    node_count = 1 # Dev environment - single node to save cost

    # Use custom VNet subnet if networking is deployed
    vnet_subnet_id = local.deploy_networking ? module.networking[0].aks_subnet_id : null

    upgrade_settings = {
      max_surge = "10%"
    }
  }

  network_profile = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"

    # Service CIDR must NOT overlap with VNet (10.0.0.0/16)
    # Using 172.16.0.0/16 for Kubernetes internal services
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10" # Must be within service_cidr
  }

  key_vault_secrets_provider = {
    secret_rotation_enabled = true
  }

  managed_identities = {
    system_assigned = true
  }

  monitor_metrics = local.deploy_observability_tools ? {} : null
  oms_agent = local.deploy_observability_tools ? {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.example[0].id
    msi_auth_for_monitoring_enabled = true
  } : null

  # Ensure networking is created before AKS
  depends_on = [module.networking]
}

// https://github.com/Azure/terraform-azurerm-avm-res-authorization-roleassignment/
// Group-based AKS RBAC assignment removed; direct assignment to current principal is retained below

# COMMENTED OUT - Free subscriptions don't allow role assignments via Terraform
# Assign manually via: az role assignment create --assignee <your-email> \
#   --role "Azure Kubernetes Service RBAC Cluster Admin" \
#   --scope <aks-resource-id>
# resource "azurerm_role_assignment" "aks_cluster_admin" {
#   scope                = module.aks.resource_id
#   role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
#   principal_id         = data.azurerm_client_config.current.object_id
# }

// https://github.com/Azure/terraform-azurerm-avm-res-authorization-roleassignment
module "acr-role" {
  count   = local.deploy_azure_container_registry ? 1 : 0
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.3.0"
  user_assigned_managed_identities_by_principal_id = {
    kubelet_identity = module.aks.kubelet_identity_id
  }
  role_definitions = {
    acr_pull_role = {
      name = "AcrPull"
    }
  }
  role_assignments_for_scopes = {
    acr_role_assignments = {
      scope = module.acr[0].resource_id
      role_assignments = {
        role_assignment_1 = {
          role_definition                  = "acr_pull_role"
          user_assigned_managed_identities = ["kubelet_identity"]
        }
      }
    }
  }
  depends_on = [module.aks]
}
