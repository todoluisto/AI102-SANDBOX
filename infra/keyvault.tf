# ─── Key Vault ────────────────────────────────────────────────────
resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = local.common_tags
}

# ─── RBAC: Grant current user Key Vault Secrets Officer ──────────
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ─── Store AI Services API Keys in Key Vault ─────────────────────
resource "azurerm_key_vault_secret" "cognitive_key1" {
  name         = "cognitive-key1"
  value        = azurerm_cognitive_account.main.primary_access_key
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "cognitive_key2" {
  name         = "cognitive-key2"
  value        = azurerm_cognitive_account.main.secondary_access_key
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}
