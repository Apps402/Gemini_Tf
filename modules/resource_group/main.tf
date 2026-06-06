variable "resource_groups" {
  description = "Map of resource groups to create"
  type = map(object({
    location = string
    tags     = optional(map(string), {})
  }))
}

resource "azurerm_resource_group" "this" {
  for_each = var.resource_groups

  name     = each.key
  location = each.value.location
  tags     = each.value.tags
}

output "resource_group_names" {
  description = "Names of the created resource groups"
  value       = { for k, v in azurerm_resource_group.this : k => v.name }
}

output "resource_group_ids" {
  description = "IDs of the created resource groups"
  value       = { for k, v in azurerm_resource_group.this : k => v.id }
}
