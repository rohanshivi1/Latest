terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.79.1"
    }
  }
    backend "azurerm" {
    resource_group_name  = "aa-rg"
    storage_account_name = ""
    container_name       = "vm-scaleset-deployment"
    key                  = "statefile.terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  skip_provider_registration = "true"
}

# Data references to existing Azure resources not managed by this module
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_subnet" "main" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.network_resource_group_name
}
