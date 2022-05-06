variable "application-insights" {
  type = object({
    create           = bool
    name             = string
    location         = string
    rg_name          = string
    workspace_id     = string
    application_type = string
    tags             = map(string)
  })
}

resource "azurerm_application_insights" "ai" {
  count               = var.application-insights.create ? 1 : 0
  name                = var.application-insights.name
  location            = var.application-insights.location
  resource_group_name = var.application-insights.rg_name
  workspace_id        = var.application-insights.workspace_id
  application_type    = var.application-insights.application_type
  tags                = var.application-insights.tags

}

output "id" {
  value = azurerm_application_insights.ai[0].id
}

output "instrumentation_key" {
  value = azurerm_application_insights.ai[0].instrumentation_key
}
