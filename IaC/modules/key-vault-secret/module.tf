variable "key-vault-secret" {
  type = object({
    create       = bool
    name         = string
    value        = string
    key_vault_id = string
    tags         = map(string)
  })
}

resource "azurerm_key_vault_secret" "kv-secret" {
  count        = var.key-vault-secret.create ? 1 : 0
  name         = var.key-vault-secret.name
  value        = var.key-vault-secret.value
  key_vault_id = var.key-vault-secret.key_vault_id
  tags         = var.key-vault-secret.tags

}

output "id" {
  value = azurerm_key_vault_secret.kv-secret[0].id
}

output "name" {
  value = azurerm_key_vault_secret.kv-secret[0].name
}
