variable "clusters" {
  description = "Map of AKS clusters to create"
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

resource "azurerm_kubernetes_cluster" "this" {
  for_each = var.clusters

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  dns_prefix          = each.value.dns_prefix
  kubernetes_version  = each.value.kubernetes_version
  sku_tier            = each.value.sku_tier
  tags                = each.value.tags

  default_node_pool {
    name                         = each.value.default_node_pool.name
    node_count                   = each.value.default_node_pool.node_count
    vm_size                      = each.value.default_node_pool.vm_size
    auto_scaling_enabled         = each.value.default_node_pool.auto_scaling_enabled
    max_count                    = each.value.default_node_pool.max_count
    min_count                    = each.value.default_node_pool.min_count
    os_disk_size_gb              = each.value.default_node_pool.os_disk_size_gb
    type                         = each.value.default_node_pool.type
    vnet_subnet_id               = each.value.default_node_pool.vnet_subnet_id
    max_pods                     = each.value.default_node_pool.max_pods
    orchestrator_version         = each.value.default_node_pool.orchestrator_version
    enable_node_public_ip        = each.value.default_node_pool.enable_node_public_ip
    node_labels                  = each.value.default_node_pool.node_labels
    only_critical_addons_enabled = each.value.default_node_pool.only_critical_addons_enabled
    zones                        = each.value.default_node_pool.zones
  }

  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.identity_ids
  }

  dynamic "network_profile" {
    for_each = each.value.network_profile != null ? [each.value.network_profile] : []
    content {
      network_plugin      = network_profile.value.network_plugin
      network_policy      = network_profile.value.network_policy
      dns_service_ip      = network_profile.value.dns_service_ip
      docker_bridge_cidr  = network_profile.value.docker_bridge_cidr
      outbound_type       = network_profile.value.outbound_type
      pod_cidr            = network_profile.value.pod_cidr
      service_cidr        = network_profile.value.service_cidr
      load_balancer_sku   = network_profile.value.load_balancer_sku
    }
  }

  role_based_access_control_enabled = each.value.role_based_access_control_enabled

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = each.value.azure_active_directory_role_based_access_control != null ? [each.value.azure_active_directory_role_based_access_control] : []
    content {
      managed                = azure_active_directory_role_based_access_control.value.managed
      tenant_id              = azure_active_directory_role_based_access_control.value.tenant_id
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
    }
  }

  dynamic "api_server_access_profile" {
    for_each = each.value.api_server_access_profile != null ? [each.value.api_server_access_profile] : []
    content {
      authorized_ip_ranges     = api_server_access_profile.value.authorized_ip_ranges
      subnet_id                = api_server_access_profile.value.subnet_id
      vnet_integration_enabled = api_server_access_profile.value.vnet_integration_enabled
    }
  }
}

output "cluster_ids" {
  value = { for k, v in azurerm_kubernetes_cluster.this : k => v.id }
}

output "cluster_fqdns" {
  value = { for k, v in azurerm_kubernetes_cluster.this : k => v.fqdn }
}

output "kube_configs" {
  value     = { for k, v in azurerm_kubernetes_cluster.this : k => v.kube_config_raw }
  sensitive = true
}
