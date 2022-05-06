variable "storage-account" {
  type = object({
    create                   = bool
    name                     = string
    resource_group_name      = string
    location                 = string
    account_kind             = string
    account_tier             = string
    account_replication_type = string
    allow_blob_public_access = bool
    tags                     = map(string)
  })
}

variable "is_hns_enabled" {
  description = "Is Heirarchal Namespace enabled? Required to be true for Azure Data Lake Storage Gen 2"
  type        = bool
  default     = null
}

variable "network-rules-default-action" {
  type    = string
  default = "Allow"
}

variable "ip_rules" {
  description = "list of ip ranges to allow access to storage account"
  type        = list(string)
  default     = null
}

variable "virtual-network-subnet-ids" {
  description = "A list of resource ids for subnets"
  type        = list(string)
  default     = null
}

resource "azurerm_storage_account" "sa" {
  count                     = var.storage-account.create ? 1 : 0
  name                      = var.storage-account.name
  resource_group_name       = var.storage-account.resource_group_name
  location                  = var.storage-account.location
  account_kind              = var.storage-account.account_kind
  account_tier              = var.storage-account.account_tier
  account_replication_type  = var.storage-account.account_replication_type
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  allow_blob_public_access  = var.storage-account.allow_blob_public_access
  is_hns_enabled            = var.is_hns_enabled
  tags                      = var.storage-account.tags

  network_rules {
    default_action             = var.network-rules-default-action
    bypass                     = ["AzureServices"]
    ip_rules                   = var.ip_rules
    virtual_network_subnet_ids = var.virtual-network-subnet-ids
  }

}

output "id" {
  value = azurerm_storage_account.sa[0].id
}

output "name" {
  value = azurerm_storage_account.sa[0].name
}

output "primary_access_key" {
  value = azurerm_storage_account.sa[0].primary_access_key
}

output "primary_connection_string" {
  value = azurerm_storage_account.sa[0].primary_connection_string
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.sa[0].primary_blob_endpoint
}