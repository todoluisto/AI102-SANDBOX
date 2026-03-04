data "azurerm_client_config" "current" {}

locals {
  # Naming convention: ai102-<svc>-<region>
  resource_group_name  = "${var.project}-rsg-${var.region_short}"
  cognitive_name       = "${var.project}-cog-${var.region_short}"
  key_vault_name       = "${var.project}-kvt-${var.region_short}"
  storage_account_name = "${var.project}stg${var.region_short}"
  log_analytics_name   = "${var.project}-law-${var.region_short}"

  common_tags = {
    project = var.project
  }
}
