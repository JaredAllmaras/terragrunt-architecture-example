variable "subnet-route-table-association" {
  type = object({
    subnet-id      = string
    route-table-id = string
  })
}

resource "azurerm_subnet_route_table_association" "snet-rt" {
  count          = var.subnet-route-table-association.route-table-id != "" ? 1 : 0
  subnet_id      = var.subnet-route-table-association.subnet-id
  route_table_id = var.subnet-route-table-association.route-table-id
}

output "id" {
  value = azurerm_subnet_route_table_association.snet-rt[0].id
}