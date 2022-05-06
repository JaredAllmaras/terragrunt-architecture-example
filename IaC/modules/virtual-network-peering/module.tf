terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.dst, azurerm.src]
    }
  }
}

variable "virtual-network-peering" {
  type = object({
    create                       = bool
    name                         = string
    src_resource_group_name      = string
    src_vnet_name                = string
    src_vnet_id                  = string
    dest_resource_group_name     = string
    dest_vnet_name               = string
    allow_forwarded_traffic      = bool
    allow_gateway_transit        = bool
    allow_virtual_network_access = bool
    use_remote_gateways          = bool
  })
}

data "azurerm_resource_group" "src_rg" {
  provider = azurerm.src
  name     = var.virtual-network-peering.src_resource_group_name
}

data "azurerm_virtual_network" "src_vnet" {
  provider            = azurerm.src
  name                = var.virtual-network-peering.src_vnet_name
  resource_group_name = var.virtual-network-peering.src_resource_group_name
}

data "azurerm_resource_group" "dst_rg" {
  provider = azurerm.dst
  name     = var.virtual-network-peering.dest_resource_group_name
}

data "azurerm_virtual_network" "dst_vnet" {
  provider            = azurerm.dst
  name                = var.virtual-network-peering.dest_vnet_name
  resource_group_name = var.virtual-network-peering.dest_resource_group_name
}

# tags are not supported for this resource.
resource "azurerm_virtual_network_peering" "vnp" {
  provider                     = azurerm.src
  count                        = var.virtual-network-peering.create ? 1 : 0
  name                         = var.virtual-network-peering.name
  resource_group_name          = var.virtual-network-peering.src_resource_group_name
  virtual_network_name         = var.virtual-network-peering.src_vnet_name
  remote_virtual_network_id    = data.azurerm_virtual_network.dst_vnet.id
  allow_forwarded_traffic      = var.virtual-network-peering.allow_forwarded_traffic
  allow_gateway_transit        = var.virtual-network-peering.allow_gateway_transit
  allow_virtual_network_access = var.virtual-network-peering.allow_virtual_network_access
  use_remote_gateways          = var.virtual-network-peering.use_remote_gateways
}

resource "azurerm_virtual_network_peering" "dest-to-src" {
  provider                     = azurerm.dst
  count                        = var.virtual-network-peering.create ? 1 : 0
  name                         = var.virtual-network-peering.name
  resource_group_name          = data.azurerm_virtual_network.dst_vnet.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.dst_vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.src_vnet.id
  allow_forwarded_traffic      = var.virtual-network-peering.allow_forwarded_traffic
  allow_gateway_transit        = var.virtual-network-peering.allow_gateway_transit
  allow_virtual_network_access = var.virtual-network-peering.allow_virtual_network_access
  use_remote_gateways          = var.virtual-network-peering.use_remote_gateways
}

output "id" {
  value = azurerm_virtual_network_peering.vnp[0].id
}

output "remote_id" {
  value = azurerm_virtual_network_peering.dest-to-src[0].id
}
