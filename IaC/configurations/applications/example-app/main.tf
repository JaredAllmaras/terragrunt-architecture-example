terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.85.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "config" {
  type = object({
    tenant-id            = string
    subscription-abbr    = string
    location             = string
    location-name        = string
    application-abbr     = string
    mssql-db-sku         = string
    mssql-max-gb         = string
    mssql-read-scale     = bool
    mssql-license-type   = string
    mssql-zone-redundant = bool
    example-vm-count     = number
    example-vm-size      = string
    os-disk-type         = string
    vm-subnet-name       = string
    vnet-name            = string
    vnet-rg-name         = string
    pe-subnet-name       = string
    kv-pdns-id           = string
    db-pdns-id           = string
    managed-disks-per-vm = number
    ws-rg-name           = string
    ws-name              = string
    tags                 = map(string)
  })
}

variable "deployedBy" {
  type = string
}

variable "deployedTime" {
  type = string
}

resource "random_string" "kv" {
  length  = 4
  upper   = false
  lower   = true
  number  = false
  special = false
}

locals {
  example-rg-name            = "${var.config.subscription-abbr}-${var.config.application-abbr}-rg"
  example-kv-rg-name         = "${var.config.subscription-abbr}-${var.config.application-abbr}-kv-rg"
  example-sql-admin-pw-name  = "${var.config.subscription-abbr}-${var.config.application-abbr}-sql-admin-pw"
  example-vm-admin-pw-name   = "${var.config.subscription-abbr}-${var.config.application-abbr}-vm-admin-pw"
  example-kv-name            = "${var.config.subscription-abbr}-${var.config.application-abbr}-kv-"
  example-kv-name2           = join("", ["${var.config.subscription-abbr}-${var.config.application-abbr}-kv", "${random_string.kv.result}"])
  example-as-name            = "${var.config.subscription-abbr}-${var.config.application-abbr}-availability-set"
  example-vm-names           = [for index in range(var.config.example-vm-count) : "${var.config.subscription-abbr}-${var.config.application-abbr}-vm${index}"]
  example-sa-name            = replace("${var.config.subscription-abbr}${var.config.application-abbr}sa", "-", "")
  example-sc-name            = "${var.config.subscription-abbr}-${var.config.application-abbr}-sc"
  example-fs-name            = "${var.config.subscription-abbr}-${var.config.application-abbr}-share"
  example-sql-server-name    = "${var.config.subscription-abbr}-${var.config.application-abbr}-mssql-server"
  example-datadisk-count-map = { for i in toset(local.example-vm-names) : i => var.config.managed-disks-per-vm }
  luns                       = { for i in local.example-datadisk-lun-map : i.datadisk-name => i.lun }
  example-datadisk-lun-map = flatten([
    for vm-name, count in local.example-datadisk-count-map : [
      for i in range(count) : {
        datadisk-name = "${vm-name}_managed-disk${i}"
        lun           = i
      }
    ]
  ])
  merged-tags = merge(var.config.tags, { "Deployed By" = var.deployedBy, "Last Updated" = var.deployedTime })
}

data "azurerm_subnet" "vm-subnet" {
  name                 = var.config.vm-subnet-name
  virtual_network_name = var.config.vnet-name
  resource_group_name  = var.config.vnet-rg-name
}

data "azurerm_client_config" "current" {}

data "azurerm_subnet" "pe-subnet" {
  name                 = var.config.pe-subnet-name
  virtual_network_name = var.config.vnet-name
  resource_group_name  = var.config.vnet-rg-name
}

data "azurerm_log_analytics_workspace" "ws" {
  name                = var.config.ws-name
  resource_group_name = var.config.ws-rg-name
}

module "example-rg" {
  source = "../../../modules/resource-group"

  resource-group = {
    create   = true
    name     = local.example-rg-name
    location = var.config.location
    tags     = local.merged-tags
  }
}

module "example-kv-rg" {
  source = "../../../modules/resource-group"

  resource-group = {
    create   = true
    name     = local.example-kv-rg-name
    location = var.config.location
    tags     = local.merged-tags
  }
}

module "example-kv" {
  source = "../../../modules/key-vault"

  key-vault = {
    create                          = true
    name                            = join("", [local.example-kv-name, random_string.kv.result])
    location                        = var.config.location
    resource_group_name             = module.example-kv-rg.name
    sku_name                        = "standard"
    tenant_id                       = data.azurerm_client_config.current.tenant_id
    enable_rbac_authorization       = true
    purge_protection_enabled        = true
    soft_delete_retention_days      = 7
    enabled_for_deployment          = false
    enabled_for_disk_encryption     = false
    enabled_for_template_deployment = false
    tags                            = local.merged-tags
  }
  network-acls-default-action = "Allow"
}

module "example-kv-pe" {
  source = "../../../modules/private-endpoint"

  private-endpoint = {
    create                         = false # will be re-evaluated once on prem build agents are created
    name                           = join("", [module.example-kv.name, "-pe"])
    resource_group_name            = module.example-kv-rg.name
    location                       = var.config.location
    subnet_id                      = data.azurerm_subnet.pe-subnet.id
    private_connection_resource_id = module.example-kv.id
    subresource_names              = ["vault"]
    private_dns_zone_ids           = [var.config.kv-pdns-id]
    tags                           = local.merged-tags
  }
}

module "example-kv-diag" {
  source = "../../../modules/monitor-diagnostic-setting"

  monitor-diagnostic-setting = {
    create                         = true
    name                           = "LogAnalytics"
    target_resource_id             = module.example-kv.id
    eventhub_authorization_rule_id = null
    log_analytics_workspace_id     = data.azurerm_log_analytics_workspace.ws.id
    storage_account_id             = null

    logs = {
      "AuditEvent" = {
        category = "AuditEvent"
        enabled  = true
      }
      "AzurePolicyEvaluationDetails" = {
        category = "AzurePolicyEvaluationDetails"
        enabled  = true
      }
    }
    metrics = {
      "AllMetrics" = {
        category = "AllMetrics"
        enabled  = true
      }
    }
  }
}

resource "random_password" "example-vm-pw" {
  length  = 12
  special = true
}

resource "random_password" "example-sql-pw" {
  length  = 12
  special = true
}

module "example-vm-admin-pw" {
  source = "../../../modules/key-vault-secret"

  key-vault-secret = {
    create       = true
    name         = local.example-vm-admin-pw-name
    value        = random_password.example-vm-pw.result
    key_vault_id = module.example-kv.id
    tags         = local.merged-tags
  }
}

module "example-sql-admin-pw" {
  source = "../../../modules/key-vault-secret"

  key-vault-secret = {
    create       = true
    name         = local.example-sql-admin-pw-name
    value        = random_password.example-sql-pw.result
    key_vault_id = module.example-kv.id
    tags         = local.merged-tags
  }
}

module "example-as" {
  source = "../../../modules/vm-availability-set"

  availability-set = {
    create              = true
    name                = local.example-as-name
    resource_group_name = module.example-rg.name
    location            = var.config.location
    tags                = local.merged-tags
  }
}

data "azurerm_key_vault_secret" "vm-admin-pw" {
  name         = local.example-vm-admin-pw-name
  key_vault_id = module.example-kv.id

  depends_on = [module.example-vm-admin-pw]
}

data "azurerm_key_vault_secret" "sql-admin-pw" {
  name         = local.example-sql-admin-pw-name
  key_vault_id = module.example-kv.id

  depends_on = [module.example-sql-admin-pw]
}


module "example-vm" {
  source = "../../../modules/windows-vm"

  for_each = toset(local.example-vm-names)

  windows-vm = {
    create              = true
    admin_password      = data.azurerm_key_vault_secret.vm-admin-pw.value
    admin_username      = "exampleAdmin1234"
    location            = var.config.location
    license_type        = "Windows_Server"
    name                = each.key
    resource_group_name = module.example-rg.name
    size                = var.config.example-vm-size
    subnet_id           = data.azurerm_subnet.vm-subnet.id
    tags                = local.merged-tags

    os_disk = {
      caching              = "ReadWrite"
      storage_account_type = var.config.os-disk-type
    }
  }
  computer_name       = length(each.key) <= 15 ? each.key : trimprefix(each.key, "${var.config.subscription-abbr}-")
  availability_set_id = module.example-as.id
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  image_id = null

}

module "example-vm-managed-disk" {
  source = "../../../modules/managed-disk"

  for_each = toset([for i in local.example-datadisk-lun-map : i.datadisk-name])
  managed-disk = {
    create               = true
    name                 = each.key
    location             = var.config.location
    resource_group_name  = module.example-rg.name
    storage_account_type = "StandardSSD_LRS"
    create_option        = "Empty"
    disk_size_gb         = "100"
    tags                 = local.merged-tags
  }
}

module "example-vm-disk-attachment" {
  source = "../../../modules/vm-data-disk-attachment"

  for_each = toset([for i in local.example-datadisk-lun-map : i.datadisk-name])
  disk-attachment = {
    create             = true
    managed_disk_id    = module.example-vm-managed-disk[each.key].id
    virtual_machine_id = module.example-vm[element(split("_", each.key), 0)].id
    lun                = lookup(local.luns, each.key)
    caching            = "ReadWrite"
  }
}

module "example-vm-diag" {
  source = "../../../modules/monitor-diagnostic-setting"

  for_each = toset(local.example-vm-names) 
  monitor-diagnostic-setting = {
    create                         = true
    name                           = "LogAnalytics"
    target_resource_id             = module.example-vm[each.key].id
    eventhub_authorization_rule_id = null
    log_analytics_workspace_id     = data.azurerm_log_analytics_workspace.ws.id
    storage_account_id             = null

    logs = {
    }
    metrics = {
      "AllMetrics" = {
        category = "AllMetrics"
        enabled  = true
      }
    }
  }
}

module "example-sql-server" {
  source = "../../../modules/mssql-server"

  mssql-server = {
    create                       = true
    name                         = local.example-sql-server-name
    resource_group_name          = module.example-rg.name
    location                     = var.config.location
    version                      = "12.0"
    administrator_login          = "exampleAdmin"
    administrator_login_password = data.azurerm_key_vault_secret.sql-admin-pw.value
    enable_firewall_rules        = false
    tags                         = local.merged-tags
  }

  azuread_administrator = {
    login_username              = "<insert login username>"
    object_id                   = "<insert aad objet id>"
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = false
  }
}

module "example-sql-server-pe" {
  source = "../../../modules/private-endpoint"

  private-endpoint = {
    create                         = true
    name                           = join("", [module.example-sql-server.name, "-pe"])
    resource_group_name            = module.example-rg.name
    location                       = var.config.location
    subnet_id                      = data.azurerm_subnet.pe-subnet.id
    private_connection_resource_id = module.example-sql-server.id
    subresource_names              = ["sqlServer"]
    private_dns_zone_ids           = [var.config.db-pdns-id]
    tags                           = local.merged-tags
  }
}

module "example-sql-database" {
  source = "../../../modules/mssql-database"

  mssql-database = {
    create          = true
    name            = "example"
    mssql_server_id = module.example-sql-server.id
    collation       = "SQL_Latin1_General_CP1_CI_AS"
    license_type    = var.config.mssql-license-type
    max_size_gb     = var.config.mssql-max-gb
    read_scale      = var.config.mssql-read-scale
    sku_name        = var.config.mssql-db-sku
    tags            = local.merged-tags
  }
  zone_redundant = var.config.mssql-zone-redundant
}