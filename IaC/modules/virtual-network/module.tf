variable "virtual-network" {
  type = object({
    create              = bool
    name                = string
    resource_group_name = string
    address_space       = list(string)
    dns_servers         = list(string)
    location            = string
    tags                = map(string)
  })
}

resource "azurerm_virtual_network" "vnet" {
  count               = var.virtual-network.create ? 1 : 0
  name                = var.virtual-network.name
  resource_group_name = var.virtual-network.resource_group_name
  address_space       = var.virtual-network.address_space
  dns_servers         = var.virtual-network.dns_servers
  location            = var.virtual-network.location
  tags                = var.virtual-network.tags

}

output "id" {
  value = azurerm_virtual_network.vnet[0].id
}

output "name" {
  value = azurerm_virtual_network.vnet[0].name
}

output "vnet_address_space" {
  value = azurerm_virtual_network.vnet[0].address_space
}