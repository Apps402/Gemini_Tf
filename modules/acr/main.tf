variable "registries" {
  description = "Map of Azure Container Registries to create"
  type = map(object({
    resource_group_name = string
    location            = string
    sku                 = optional(string, "Standard")
    admin_enabled       = optional(bool, false)
    tags                = optional(map(string), {})
    
    georeplications = optional(list(object({
      location                = string
      zone_redundancy_enabled = optional(bool, false)
      tags                    = optional(map(string), {})
    })), [])

    network_rule_set = optional(object({
      default_action = optional(string, "Allow")
      ip_rule = optional(list(object({
        action   = string
        ip_range = string
      })), [])
    }))

    retention_policy = optional(object({
      days    = optional(number, 7)
      enabled = optional(bool, false)
    }))

    trust_policy = optional(object({
      enabled = optional(bool, false)
    }))
  }))
}

resource "azurerm_container_registry" "this" {
  for_each = var.registries

  name                = each.key
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku
  admin_enabled       = each.value.admin_enabled
  tags                = each.value.tags

  dynamic "georeplications" {
    for_each = each.value.georeplications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = georeplications.value.tags
    }
  }

  dynamic "network_rule_set" {
    for_each = each.value.network_rule_set != null ? [each.value.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action
      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rule
        content {
          action   = ip_rule.value.action
          ip_range = ip_rule.value.ip_range
        }
      }
    }
  }

  dynamic "retention_policy" {
    for_each = each.value.retention_policy != null ? [each.value.retention_policy] : []
    content {
      days    = retention_policy.value.days
      enabled = retention_policy.value.enabled
    }
  }

  dynamic "trust_policy" {
    for_each = each.value.trust_policy != null ? [each.value.trust_policy] : []
    content {
      enabled = trust_policy.value.enabled
    }
  }
}

output "registry_ids" {
  value = { for k, v in azurerm_container_registry.this : k => v.id }
}

output "registry_login_servers" {
  value = { for k, v in azurerm_container_registry.this : k => v.login_server }
}
