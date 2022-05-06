terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "=2.85.0"
      configuration_aliases = [azurerm.src, azurerm.dst]
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "src"
  subscription_id = var.config.src_subscription_id
  tenant_id       = var.config.tenant-id
  features {}
}

provider "azurerm" {
  alias           = "dst"
  subscription_id = var.config.dest_subscription_id
  tenant_id       = var.config.tenant-id
  features {}
}

variable "config" {
  type = object({
    tenant-id            = string
    subscription-abbr    = string
    location             = string
    location-abbr        = string
    location-name        = string
    application-abbr     = string
    src_subscription_id  = string
    dest_subscription_id = string
    vnet-address-space   = list(string)
    vnet_dns_servers     = list(string)
    vnet-peers           = map(any)
    route-tables         = map(any)
    nsgs                 = map(any)
    subnets              = map(any)
    tags                 = map(string)
  })
}

variable "deployedBy" {
  type = string
}

variable "deployedTime" {
  type = string
}

locals {
  rg-name     = "${var.config.subscription-abbr}-${var.config.application-abbr}-rg"
  vnet-name   = "${var.config.subscription-abbr}-${var.config.application-abbr}-vnet"
  merged-tags = merge(var.config.tags, { "Deployed By" = var.deployedBy, "Last Updated" = var.deployedTime })
}

module "resource-group" {
  source = "../../../modules/resource-group"

  resource-group = {
    create   = true
    name     = local.rg-name
    location = var.config.location
    tags     = local.merged-tags
  }
}

module "route-tables" {
  for_each = var.config.route-tables
  source   = "../../../modules/route-table"

  route-table = {
    create                        = true
    name                          = each.key
    resource_group_name           = module.resource-group.name
    location                      = var.config.location
    disable_bgp_route_propagation = false
    routes                        = each.value["routes"]
    tags                          = local.merged-tags
  }
}

module "nsgs" {
  for_each = var.config.nsgs
  source   = "../../../modules/network-security-group"

  network-security-group = {
    create              = true
    name                = each.key
    resource_group_name = module.resource-group.name
    location            = var.config.location
    rules               = each.value["rules"]
    tags                = local.merged-tags
  }
}

module "vnet" {
  source = "../../../modules/virtual-network"

  virtual-network = {
    create              = true
    name                = local.vnet-name
    resource_group_name = module.resource-group.name
    address_space       = var.config.vnet-address-space
    location            = var.config.location
    dns_servers         = var.config.vnet_dns_servers
    tags                = local.merged-tags
  }
}

module "virtual-network-peering" {
  for_each = var.config.vnet-peers
  source   = "../../../modules/virtual-network-peering"
  providers = {
    azurerm.dst = azurerm.dst,
    azurerm.src = azurerm.src
  }
  virtual-network-peering = {
    create                       = true
    name                         = each.key
    src_resource_group_name      = module.resource-group.name
    src_vnet_name                = module.vnet.name
    src_vnet_id                  = module.vnet.id
    dest_resource_group_name     = each.value["dest_resource_group_name"]
    dest_vnet_name               = each.value["dest_vnet_name"]
    allow_forwarded_traffic      = each.value["allow_forwarded_traffic"]
    allow_gateway_transit        = each.value["allow_gateway_transit"]
    allow_virtual_network_access = each.value["allow_virtual_network_access"]
    use_remote_gateways          = each.value["use_remote_gateways"]
  }
}

module "subnets" {
  for_each = var.config.subnets
  source   = "../../../modules/subnet"

  depends_on = [
    module.nsgs,
    module.route-tables,
    module.vnet
  ]

  subnet = {
    create                               = true
    name                                 = each.key
    resource_group_name                  = module.resource-group.name
    virtual_network_name                 = local.vnet-name
    address_prefixes                     = each.value["address-prefix"]
    enforce-private-link-endpoint-policy = each.value["enforce-private-link-endpoint-policy"]
    service_endpoints                    = each.value["service-endpoints"]
    delegation                           = each.value["delegation"]
    delegation-actions                   = each.value["delegation-actions"]
  }
}

resource "azurerm_subnet_network_security_group_association" "snet-nsg" {
  for_each                  = var.config.subnets
  subnet_id                 = module.subnets[each.key].id
  network_security_group_id = module.nsgs[each.value["nsg-name"]].id
}

resource "azurerm_subnet_route_table_association" "snet-rt" {
  for_each = {
    for key, subnet in var.config.subnets : key => subnet if subnet.rt-name != ""
  }
  subnet_id      = module.subnets[each.key].id
  route_table_id = module.route-tables[each.value["rt-name"]].id
}