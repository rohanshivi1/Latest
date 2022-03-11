data "azurerm_key_vault"  "infra-common-dev-kv"{
 name         = ""
 resource_group_name = "aa-rg"
}

data "azurerm_key_vault_secret" "azureadmin-builad-scaleset" {
  name         = "a"
  key_vault_id = data.azurerm_key_vault.aa.id
}
