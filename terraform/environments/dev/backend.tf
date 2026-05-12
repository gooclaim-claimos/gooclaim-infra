terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.95"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50"
    }
  }

  # ─── State Backend ───────────────────────────────────────────────────
  # State stored in Azure Storage Account (provisioned manually pre-Terraform).
  # Resource Group:  gooclaim-rg-dev
  # Storage Account: gooclaimtfstatedev
  # Container:       tfstate
  # State file key:  dev.terraform.tfstate
  #
  # Access auth: defaults to `az login` Azure AD identity (preferred).
  # Fallback: ARM_ACCESS_KEY env var (when running in CI/CD).
  backend "azurerm" {
    resource_group_name  = "gooclaim-rg-dev"
    storage_account_name = "gooclaimtfstatedev"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {}
