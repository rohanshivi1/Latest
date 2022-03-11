
data "template_file" "linux-vm-cloud-init" {
  template = file("cloud-init.yml")
}

resource "azurerm_linux_virtual_machine_scale_set" "deployment" {
  name                      = "${var.deployment_prefix}-vmss"
  resource_group_name       = data.azurerm_resource_group.main.name
  location                  = data.azurerm_resource_group.main.location
  sku                       = "Standard_F4s_v2"
  instances                 = var.numberOfWorkerNodes

  overprovision             = false
  single_placement_group    = false

  admin_username            = ""
  admin_password            = ""
  #admin_password            = azurerm_key_vault_secret.vmsecret.value
  disable_password_authentication = false
  
  custom_data               = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  tags                      = var.tags

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = ""
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadOnly"

    diff_disk_settings {
      option = "Local"
    }
  }

  network_interface {
    name    = "${var.deployment_prefix}-vmss-nic"
    primary = true

    ip_configuration {
      name      = "${var.deployment_prefix}-vmss-ipconfig"
      primary   = true
      subnet_id = data.azurerm_subnet.main.id
    }
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to the following tags.
      # These are managed by Azure DevOps when the scaleset joins as an agent pool.
      extension,
      tags,
      automatic_instance_repair,
      automatic_os_upgrade_policy,
      instances,
    ]
  }
}
