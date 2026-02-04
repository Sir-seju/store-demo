# ==============================================================================
# Terraform Configuration & Providers
# ==============================================================================

terraform {
  required_version = ">= 1.9.2"

  # ---------------------------------------------------------------------------
  # Remote State Backend (Azure Blob Storage)
  # ---------------------------------------------------------------------------
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate69421708"
    container_name       = "tfstate"
    key                  = "rosetta.tfstate"
  }

  # ---------------------------------------------------------------------------
  # Required Providers
  # ---------------------------------------------------------------------------
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    http = {
      source  = "hashicorp/http"
      version = "=3.4.3"
    }
  }
}

# -----------------------------------------------------------------------------
# Azure Provider Configuration
# -----------------------------------------------------------------------------
provider "azurerm" {
  resource_provider_registrations = "none"

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    cognitive_account {
      purge_soft_delete_on_destroy = true
    }

    key_vault {
      purge_soft_delete_on_destroy = true
    }

    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }
}
