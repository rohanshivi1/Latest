# Terraform Block
terraform {
  required_version = "~> 1.0.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.0" 
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "infra-common-dev-rg"
    storage_account_name = "infracommontfstatedev"
    container_name       = "buildserver-deployment"
    key                  = "build-agent-01.terraform.tfstate"
  }
}


# Provider Block
provider "azurerm" {
 tenant_id       = var.tenant
 subscription_id = var.subscription
 skip_provider_registration = "true"
 features {}          
}
