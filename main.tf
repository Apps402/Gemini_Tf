module "resource_groups" {
  source          = "./modules/resource_group"
  resource_groups = var.resource_groups
}

module "acr" {
  source     = "./modules/acr"
  registries = var.registries

  depends_on = [module.resource_groups]
}

module "aks" {
  source   = "./modules/aks"
  clusters = var.clusters

  depends_on = [module.resource_groups]
}
