variable "route-table" {
  type = object({
    create                        = bool
    name                          = string
    resource_group_name           = string
    location                      = string
    disable_bgp_route_propagation = bool
    routes                        = map(any)
    tags                          = map(string)
  })
}

resource "azurerm_route_table" "rt" {
  count                         = var.route-table.create ? 1 : 0
  name                          = var.route-table.name
  resource_group_name           = var.route-table.resource_group_name
  location                      = var.route-table.location
  disable_bgp_route_propagation = var.route-table.disable_bgp_route_propagation
  tags                          = var.route-table.tags

}

module "routes" {
  for_each = var.route-table.routes
  source   = "../route"

  route = {
    create                 = true
    name                   = each.key
    resource_group_name    = var.route-table.resource_group_name
    route_table_name       = azurerm_route_table.rt[0].name
    address_prefix         = each.value["address_prefix"]
    next_hop_type          = each.value["next_hop_type"]
    next_hop_in_ip_address = each.value["next_hop_type"] == "VirtualAppliance" ? each.value["next_hop_in_ip_address"] : null
  }
}

output "id" {
  value = azurerm_route_table.rt[0].id
}