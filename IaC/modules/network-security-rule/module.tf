variable "network-security-rule" {
  type = object({
    create                      = bool
    name                        = string
    resource_group_name         = string
    network_security_group_name = string
    description                 = string
    protocol                    = string
    source_port_range           = string
    destination_port_ranges     = list(string)
    source_address_prefix       = string
    destination_address_prefix  = string
    access                      = string
    priority                    = number
    direction                   = string
  })
}

# tags are not supported for this resource.

resource "azurerm_network_security_rule" "nsr" {
  count                       = var.network-security-rule.create ? 1 : 0
  name                        = var.network-security-rule.name
  resource_group_name         = var.network-security-rule.resource_group_name
  network_security_group_name = var.network-security-rule.network_security_group_name
  description                 = var.network-security-rule.description
  protocol                    = var.network-security-rule.protocol
  source_port_range           = var.network-security-rule.source_port_range
  destination_port_range      = var.network-security-rule.destination_port_ranges[0] == "*" ? "*" : null
  destination_port_ranges     = var.network-security-rule.destination_port_ranges[0] == "*" ? null : var.network-security-rule.destination_port_ranges
  source_address_prefix       = var.network-security-rule.source_address_prefix
  destination_address_prefix  = var.network-security-rule.destination_address_prefix
  access                      = var.network-security-rule.access
  priority                    = var.network-security-rule.priority
  direction                   = var.network-security-rule.direction
}

output "id" {
  value = azurerm_network_security_rule.nsr[0].id
}