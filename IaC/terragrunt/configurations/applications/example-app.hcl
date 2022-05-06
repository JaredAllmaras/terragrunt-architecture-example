skip = true

locals {
  env-config    = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
  global-config = read_terragrunt_config(find_in_parent_folders("global.hcl")).locals
  tags = {
      deployed_by = ""
  }
  application-abbr = "ex-app"
  application-name = "example application"

  inputs = {
    dev = {
      mssql-license-type   = null
      mssql-read-scale     = false
      mssql-max-gb         = "250"
      mssql-db-sku         = "BC_Gen5_4"
      mssql-zone-redundant = false
      example-vm-count     = 2
      example-vm-size      = "Standard_D4_v4"
      os-disk-type         = "StandardSSD_LRS"
      managed-disks-per-vm = 2
    },
    test = {
      mssql-license-type   = null
      mssql-read-scale     = false
      mssql-max-gb         = "250"
      mssql-db-sku         = "BC_Gen5_4"
      mssql-zone-redundant = false
      example-vm-count     = 2
      example-vm-size      = "Standard_D4_v4"
      os-disk-type         = "StandardSSD_LRS"
      managed-disks-per-vm = 2
    },
    staging = {
      mssql-license-type   = null
      mssql-read-scale     = false
      mssql-max-gb         = "250"
      mssql-db-sku         = "BC_Gen5_4"
      mssql-zone-redundant = false
      example-vm-count     = 4
      example-vm-size      = "Standard_D4_v4"
      os-disk-type         = "StandardSSD_ZRS"
      managed-disks-per-vm = 2
    },
    prododuction = {
      mssql-license-type   = null
      mssql-read-scale     = false
      mssql-max-gb         = "250"
      mssql-db-sku         = "BC_Gen5_4"
      mssql-zone-redundant = false
      example-vm-count     = 4
      example-vm-size      = "Standard_D4_v4"
      os-disk-type         = "StandardSSD_ZRS"
      managed-disks-per-vm = 2
    }
  }
}

inputs = {
  config = {
    subscription-abbr    = local.env-config.subscription-abbr
    location             = local.env-config.location
    location-name        = local.env-config.location-name
    application-abbr     = local.application-abbr
    vnet-rg-name         = join("", [local.env-config.subscription-abbr, "-net-rg"])
    vnet-name            = join("", [local.env-config.subscription-abbr, "-net-vnet"])
    vm-subnet-name       = join("", [local.env-config.subscription-abbr, "net-web01-sn"])
    ws-rg-name           = join("", [local.env-config.subscription-abbr, "-shla-rg"])
    ws-name              = join("", [local.env-config.subscription-abbr, "-shla-ws"])
    mssql-db-sku         = local.inputs[local.env-config.subscription-abbr].mssql-db-sku
    mssql-max-gb         = local.inputs[local.env-config.subscription-abbr].mssql-max-gb
    mssql-read-scale     = local.inputs[local.env-config.subscription-abbr].mssql-read-scale
    mssql-license-type   = local.inputs[local.env-config.subscription-abbr].mssql-license-type
    mssql-zone-redundant = local.inputs[local.env-config.subscription-abbr].mssql-zone-redundant
    example-vm-count     = local.inputs[local.env-config.subscription-abbr].example-vm-count
    example-vm-size      = local.inputs[local.env-config.subscription-abbr].example-vm-size
    os-disk-type         = local.inputs[local.env-config.subscription-abbr].os-disk-type

    managed-disks-per-vm = local.inputs[local.env-config.subscription-abbr].managed-disks-per-vm
    tags                 = local.tags
  }
}

terraform {
  source = "${find_in_parent_folders("terragrunt-example-architecture")}//configurations/applications/example-app"
}

remote_state {
  config = {
    resource_group_name  = local.env-config.tfstate_sa_rg_name
    storage_account_name = local.env-config.tfstate_sa_name
    container_name       = "tfstates"
    key                  = local.application-abbr
  }
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
