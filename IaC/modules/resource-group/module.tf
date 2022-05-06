variable "resource-group" {
  type = object({
    create   = bool
    name     = string
    location = string
    tags     = map(string)
  })
}

resource "azurerm_resource_group" "rg" {
  count    = var.resource-group.create ? 1 : 0
  name     = var.resource-group.name
  location = var.resource-group.location
  tags     = var.resource-group.tags

  lifecycle {
    ignore_changes = [
      tags["Last Updated"],
      tags["Deployed By"]
    ]
  }
}

output "id" {
  value = azurerm_resource_group.rg[0].id
}

output "name" {
  value = azurerm_resource_group.rg[0].name
}
