# ─── Resource Group ───────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ─── AI Services (Multi-Service Cognitive Account) ────────────────
resource "azurerm_cognitive_account" "main" {
  name                  = local.cognitive_name
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  kind                  = "CognitiveServices"
  sku_name              = "S0"
  custom_subdomain_name = local.cognitive_name
  local_auth_enabled    = true

  tags = local.common_tags
}

# ─── Storage Account ─────────────────────────────────────────────
resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"

  tags = local.common_tags
}
