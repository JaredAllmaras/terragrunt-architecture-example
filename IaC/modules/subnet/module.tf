variable "subnet" {
  type = object({
    create                               = bool
    name                                 = string
    resource_group_name                  = string
    virtual_network_name                 = string
    address_prefixes                     = string
    enforce-private-link-endpoint-policy = bool
    service_endpoints                    = list(string)
    delegation                           = string
    delegation-actions                   = list(string)
  })
}

# tags are not supported for this resource.

resource "azurerm_subnet" "snet" {
  count                                          = var.subnet.create ? 1 : 0
  name                                           = var.subnet.name
  resource_group_name                            = var.subnet.resource_group_name
  virtual_network_name                           = var.subnet.virtual_network_name
  address_prefixes                               = [var.subnet.address_prefixes]
  enforce_private_link_endpoint_network_policies = var.subnet.enforce-private-link-endpoint-policy
  service_endpoints                              = var.subnet.service_endpoints

  dynamic "delegation" {
    for_each = var.subnet.delegation != "" ? [1] : []
    content {
      name = var.subnet.delegation
      service_delegation {
        name    = var.subnet.delegation
        actions = var.subnet.delegation-actions
      }
    }
  }
}

output "id" {
  value = azurerm_subnet.snet[0].id
}
