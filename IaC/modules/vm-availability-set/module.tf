variable "availability-set" {
  type = object({
    create              = bool
    name                = string
    resource_group_name = string
    location            = string
    tags                = map(string)
  })
}

resource "azurerm_availability_set" "as" {
  count               = var.availability-set.create ? 1 : 0
  name                = var.availability-set.name
  resource_group_name = var.availability-set.resource_group_name
  location            = var.availability-set.location
  tags                = var.availability-set.tags

}

output "id" {
  value = azurerm_availability_set.as[0].id
}

output "name" {
  value = azurerm_availability_set.as[0].name
}