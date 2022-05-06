variable "disk-attachment" {
  type = object({
    create             = bool
    managed_disk_id    = string
    virtual_machine_id = string
    lun                = string
    caching            = string
  })
}

# tags are not supported for this resource.

resource "azurerm_virtual_machine_data_disk_attachment" "disk-attachment" {
  count              = var.disk-attachment.create ? 1 : 0
  managed_disk_id    = var.disk-attachment.managed_disk_id
  virtual_machine_id = var.disk-attachment.virtual_machine_id
  lun                = var.disk-attachment.lun
  caching            = var.disk-attachment.caching
}

output "id" {
  value = azurerm_virtual_machine_data_disk_attachment.disk-attachment[0].id
}