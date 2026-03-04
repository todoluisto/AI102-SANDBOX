# ─── Log Analytics Workspace ─────────────────────────────────────
resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_analytics_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# ─── Diagnostic Settings: AI Services -> Log Analytics ───────────
resource "azurerm_monitor_diagnostic_setting" "cognitive" {
  name                       = "${local.cognitive_name}-diagnostics"
  target_resource_id         = azurerm_cognitive_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestResponse"
  }

  enabled_log {
    category = "Trace"
  }

  metric {
    category = "AllMetrics"
  }
}
