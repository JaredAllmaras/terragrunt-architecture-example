variable "key-vault" {
  type = object({
    create                          = bool
    name                            = string
    location                        = string
    resource_group_name             = string
    sku_name                        = string
    tenant_id                       = string
    enable_rbac_authorization       = bool
    purge_protection_enabled        = bool
    soft_delete_retention_days      = number
    enabled_for_deployment          = bool
    enabled_for_disk_encryption     = bool
    enabled_for_template_deployment = bool
    tags                            = map(string)
  })
}


variable "ip_rules" {
  description = "list of ip ranges to allow access to key vault"
  type        = list(string)
  default     = null
}

variable "network-acls-default-action" {
  type    = string
  default = "Deny"
}

variable "network-acls-bypass" {
  type    = string
  default = "None"
}


resource "azurerm_key_vault" "kv" {
  count                           = var.key-vault.create ? 1 : 0
  name                            = var.key-vault.name
  location                        = var.key-vault.location
  resource_group_name             = var.key-vault.resource_group_name
  sku_name                        = var.key-vault.sku_name
  tenant_id                       = var.key-vault.tenant_id
  enable_rbac_authorization       = var.key-vault.enable_rbac_authorization
  purge_protection_enabled        = var.key-vault.purge_protection_enabled
  soft_delete_retention_days      = var.key-vault.soft_delete_retention_days
  enabled_for_deployment          = var.key-vault.enabled_for_deployment
  enabled_for_disk_encryption     = var.key-vault.enabled_for_disk_encryption
  enabled_for_template_deployment = var.key-vault.enabled_for_template_deployment
  tags                            = var.key-vault.tags

  network_acls {
    default_action = var.network-acls-default-action
    bypass         = var.network-acls-bypass
    ip_rules       = var.ip_rules
  }

}

output "id" {
  value = azurerm_key_vault.kv[0].id
}

output "name" {
  value = azurerm_key_vault.kv[0].name
}
