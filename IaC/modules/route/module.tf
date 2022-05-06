variable "route" {
  type = object({
    create                 = bool
    name                   = string
    resource_group_name    = string
    route_table_name       = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = string
  })
}

# tags are not supported for this resource.

resource "azurerm_route" "this" {
  count                  = var.route.create ? 1 : 0
  name                   = var.route.name
  resource_group_name    = var.route.resource_group_name
  route_table_name       = var.route.route_table_name
  address_prefix         = var.route.address_prefix
  next_hop_type          = var.route.next_hop_type
  next_hop_in_ip_address = var.route.next_hop_type == "VirtualAppliance" ? var.route.next_hop_in_ip_address : null
}

output "id" {
  value = azurerm_route.this[0].id
}