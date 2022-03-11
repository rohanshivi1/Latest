# Locals Block for custom data
locals {
webvm_custom_data = <<CUSTOM_DATA
#!/bin/bash

sudo echo "10.145.28.7 aabccontainerregistry.azurecr.io" >> /etc/hosts
sudo echo "10.145.28.4 aabccontainerregistry.northeurope.data.azurecr.io" >> /etc/hosts

   
CUSTOM_DATA
}

data "azurerm_resource_group" "image" {
  name                = var.packer_resource_group_name
}

data "azurerm_image" "image" {
  name                = var.packer_image_name
  resource_group_name = data.azurerm_resource_group.image.name
}

resource "azurerm_virtual_machine_scale_set" "build-linuxvm" {
  name                      = "${var.deployment_prefix}-vmss"
  resource_group_name = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location 
  upgrade_policy_mode = "Manual"



 sku {
    name     = "Standard_F4s_v2"
    tier     = "Standard"
    capacity = 2
  }
 
os_profile {
    computer_name_prefix = "build"
    admin_username       = "azureadmin"
    admin_password       = data.azurerm_key_vault_secret.azureadmin-builad-scaleset.value
    custom_data = base64encode(local.webvm_custom_data)
  }

 storage_profile_image_reference {
    id=data.azurerm_image.image.id
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    os_type           = "Linux"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/azureadmin/.ssh/authorized_keys"
      key_data = file("./ssh-keys/terraform-azure.pub")
    }
  }
  

  network_profile {
    name    = "${var.deployment_prefix}-vmss-nic"
    primary = true

    ip_configuration {
      name      = "${var.deployment_prefix}-vmss-ipconfig"
      primary   = true
      subnet_id = data.azurerm_subnet.subnet.id
    }
  }


  lifecycle {
    ignore_changes = [
      extension,
      tags,

    ]
  }
 
  tags = local.common_tags
}


