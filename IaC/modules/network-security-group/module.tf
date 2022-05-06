variable "network-security-group" {
  type = object({
    create              = bool
    name                = string
    resource_group_name = string
    location            = string
    rules               = map(any)
    tags                = map(string)
  })
}

resource "azurerm_network_security_group" "nsg" {
  count               = var.network-security-group.create ? 1 : 0
  name                = var.network-security-group.name
  resource_group_name = var.network-security-group.resource_group_name
  location            = var.network-security-group.location
  tags                = var.network-security-group.tags

}

module "rules" {
  for_each = var.network-security-group.rules
  source   = "../network-security-rule"

  network-security-rule = {
    create                      = true
    name                        = each.key
    resource_group_name         = var.network-security-group.resource_group_name
    network_security_group_name = azurerm_network_security_group.nsg[0].name
    description                 = each.value["description"]
    protocol                    = each.value["protocol"]
    source_port_range           = each.value["source_port_range"]
    destination_port_ranges     = each.value["destination_port_ranges"]
    source_address_prefix       = each.value["source_address_prefix"]
    destination_address_prefix  = each.value["destination_address_prefix"]
    access                      = each.value["access"]
    priority                    = each.value["priority"]
    direction                   = each.value["direction"]
  }
}

output "id" {
  value = azurerm_network_security_group.nsg[0].id
}

output "name" {
  value = azurerm_network_security_group.nsg[0].name
}