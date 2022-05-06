variable "monitor-diagnostic-setting" {
  type = object({
    create                         = bool
    name                           = string
    target_resource_id             = string
    eventhub_authorization_rule_id = string
    log_analytics_workspace_id     = string
    storage_account_id             = string
    logs = map(object({
      category = string
      enabled  = bool
    }))

    metrics = map(object({
      category = string
      enabled  = bool

    }))

  })
}

resource "azurerm_monitor_diagnostic_setting" "mds" {
  count                          = var.monitor-diagnostic-setting.create ? 1 : 0
  name                           = var.monitor-diagnostic-setting.name
  target_resource_id             = var.monitor-diagnostic-setting.target_resource_id
  eventhub_authorization_rule_id = var.monitor-diagnostic-setting.eventhub_authorization_rule_id
  log_analytics_workspace_id     = var.monitor-diagnostic-setting.log_analytics_workspace_id
  storage_account_id             = var.monitor-diagnostic-setting.storage_account_id

  dynamic "log" {
    for_each = var.monitor-diagnostic-setting.logs
    content {
      category = log.value.category
      enabled  = log.value.enabled

      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }

  dynamic "metric" {
    for_each = var.monitor-diagnostic-setting.metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled

      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }
}

output "id" {
  value = azurerm_monitor_diagnostic_setting.mds[0].id
}
