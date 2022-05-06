variable "private-endpoint" {
  type = object({
    create                         = bool
    name                           = string
    resource_group_name            = string
    location                       = string
    subnet_id                      = string
    private_connection_resource_id = string
    subresource_names              = list(string)
    private_dns_zone_ids           = list(string)
    tags                           = map(string)
  })
}

resource "azurerm_private_endpoint" "pe" {
  count               = var.private-endpoint.create ? 1 : 0
  name                = var.private-endpoint.name
  location            = var.private-endpoint.location
  resource_group_name = var.private-endpoint.resource_group_name
  subnet_id           = var.private-endpoint.subnet_id
  tags                = var.private-endpoint.tags

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = var.private-endpoint.private_dns_zone_ids
  }

  private_service_connection {
    name                           = "${var.private-endpoint.name}-psc"
    private_connection_resource_id = var.private-endpoint.private_connection_resource_id
    subresource_names              = var.private-endpoint.subresource_names
    is_manual_connection           = false
  }

  lifecycle {
    ignore_changes = [
      tags["Deployed By"],
      tags["Last Updated"]
    ]
  }
}
