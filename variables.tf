variable "resource_groups" {
  type = map(object({
    location = string
    tags     = optional(map(string), {})
  }))
}

variable "registries" {
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

variable "clusters" {
  type = map(object({
    resource_group_name = string
    location            = string
    dns_prefix          = string
    kubernetes_version  = optional(string)
    sku_tier            = optional(string, "Free")
    tags                = optional(map(string), {})
    default_node_pool = object({
      name                         = string
      node_count                   = optional(number, 1)
      vm_size                      = string
      auto_scaling_enabled         = optional(bool, false)
      max_count                    = optional(number)
      min_count                    = optional(number)
      os_disk_size_gb              = optional(number)
      type                         = optional(string, "VirtualMachineScaleSets")
      vnet_subnet_id               = optional(string)
      max_pods                     = optional(number)
      orchestrator_version         = optional(string)
      enable_node_public_ip        = optional(bool, false)
      node_labels                  = optional(map(string))
      only_critical_addons_enabled = optional(bool, false)
      zones                        = optional(list(string))
    })
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }), { type = "SystemAssigned" })
    network_profile = optional(object({
      network_plugin      = optional(string, "kubenet")
      network_policy      = optional(string)
      dns_service_ip      = optional(string)
      docker_bridge_cidr  = optional(string)
      outbound_type       = optional(string, "loadBalancer")
      pod_cidr            = optional(string)
      service_cidr        = optional(string)
      load_balancer_sku   = optional(string, "standard")
    }))
    role_based_access_control_enabled = optional(bool, true)
    azure_active_directory_role_based_access_control = optional(object({
      managed                = optional(bool, true)
      tenant_id              = optional(string)
      admin_group_object_ids = optional(list(string))
      azure_rbac_enabled     = optional(bool, true)
    }))
    api_server_access_profile = optional(object({
      authorized_ip_ranges     = optional(list(string))
      subnet_id                = optional(string)
      vnet_integration_enabled = optional(bool, false)
    }))
  }))
}
