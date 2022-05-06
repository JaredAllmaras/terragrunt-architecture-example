variable "managed-disk" {
  type = object({
    create               = bool
    name                 = string
    location             = string
    resource_group_name  = string
    storage_account_type = string
    create_option        = string
    disk_size_gb         = string
    tags                 = map(string)
  })
}

variable "source_resource_id" {
  description = "id of managed disk to copy from"
  type        = string
  default     = null
}

variable "encryption_enabled" {
  description = "Is encryption enabled on this disk?"
  type        = bool
  default     = false
}

variable "encryption_settings" {
  description = "encryption settings for the managed disk"
  type = object({
    secret_url      = string
    key_url         = string
    source_vault_id = string
  })
  default = null
}

resource "azurerm_managed_disk" "md" {
  count                = var.managed-disk.create ? 1 : 0
  name                 = var.managed-disk.name
  location             = var.managed-disk.location
  resource_group_name  = var.managed-disk.resource_group_name
  storage_account_type = var.managed-disk.storage_account_type
  create_option        = var.managed-disk.create_option
  source_resource_id   = var.source_resource_id
  disk_size_gb         = var.managed-disk.disk_size_gb
  tags                 = var.managed-disk.tags

  dynamic "encryption_settings" {
    for_each = var.encryption_enabled ? [1] : []
    content {
      enabled = true
      disk_encryption_key {
        secret_url      = var.encryption_settings.secret_url
        source_vault_id = var.encryption_settings.source_vault_id
      }
      key_encryption_key {
        key_url         = var.encryption_settings.key_url
        source_vault_id = var.encryption_settings.source_vault_id
      }
    }
  }

}

output "id" {
  value = azurerm_managed_disk.md[0].id
}

output "name" {
  value = azurerm_managed_disk.md[0].name
}