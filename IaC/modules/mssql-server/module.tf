variable "mssql-server" {
  type = object({
    create                       = bool
    name                         = string
    resource_group_name          = string
    location                     = string
    version                      = string
    administrator_login          = string
    administrator_login_password = string
    enable_firewall_rules        = bool
    tags                         = map(string)
  })
}

variable "mssql_firewall_rule" {
  description = "Range of IP addresses to allow firewall connections to mssql server"
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

variable "azuread_administrator" {
  description = "Identity of the Azure AD User/RBAC group with default administrator access to server"
  type = object({
    login_username              = string
    object_id                   = string
    tenant_id                   = string
    azuread_authentication_only = bool
  })
  default = null
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "log_monitoring_enabled" {
  type    = bool
  default = true
}

variable "storage_endpoint" {
  type    = string
  default = null
}

variable "storage_account_access_key" {
  type    = string
  default = null
}

variable "disabled_alerts" {
  type    = list(string)
  default = []
}

variable "policy_disabled" {
  type    = bool
  default = false
}

resource "azurerm_mssql_server" "mssql-server" {
  count                         = var.mssql-server.create ? 1 : 0
  name                          = var.mssql-server.name
  resource_group_name           = var.mssql-server.resource_group_name
  location                      = var.mssql-server.location
  version                       = var.mssql-server.version
  administrator_login           = var.mssql-server.administrator_login
  administrator_login_password  = var.mssql-server.administrator_login_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.mssql-server.tags

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? [1] : []
    content {
      login_username              = var.azuread_administrator.login_username
      object_id                   = var.azuread_administrator.object_id
      tenant_id                   = var.azuread_administrator.tenant_id
      azuread_authentication_only = var.azuread_administrator.azuread_authentication_only
    }
  }

}

resource "azurerm_mssql_server_security_alert_policy" "mssql-server-security-audit-policy" {
  resource_group_name        = var.mssql-server.resource_group_name
  server_name                = azurerm_mssql_server.mssql-server[0].name
  state                      = var.policy_disabled ? "Disabled" : "Enabled"
  storage_endpoint           = var.storage_endpoint
  storage_account_access_key = var.storage_account_access_key
  disabled_alerts            = var.disabled_alerts

}

resource "azurerm_mssql_firewall_rule" "firewall-rules" {
  count            = var.mssql-server.enable_firewall_rules && length(var.mssql_firewall_rule) > 0 ? length(var.mssql_firewall_rule) : 0
  name             = var.mssql_firewall_rule[count.index].name
  server_id        = azurerm_mssql_server.mssql-server[0].id
  start_ip_address = var.mssql_firewall_rule[count.index].start_ip_address
  end_ip_address   = var.mssql_firewall_rule[count.index].end_ip_address
}

output "id" {
  value = azurerm_mssql_server.mssql-server[0].id
}

output "name" {
  value = azurerm_mssql_server.mssql-server[0].name
}

output "security_audit_policy_id" {
  value = azurerm_mssql_server_security_alert_policy.mssql-server-security-audit-policy.id
}
