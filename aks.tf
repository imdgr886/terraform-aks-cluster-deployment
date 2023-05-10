resource "random_id" "prefix" {
  byte_length = 4
}

resource "azurerm_resource_group" "rg" {

  location = var.location
  name     = "${var.prefix}-${random_id.prefix.hex}-rg"
}

locals {
  resource_group = {
    name     = azurerm_resource_group.rg.name
    location = var.location
  }
  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.52.0.0/16"]
  location            = local.resource_group.location
  name                = "${var.prefix}-${random_id.prefix.hex}-vn"
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet" "aks" {
  address_prefixes     = ["10.52.0.0/24"]
  name                 = "aks-sn"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "agw" {
  address_prefixes     = ["10.52.2.0/24"]
  name                 = "awg-sn"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "6.8.0"

  prefix                    = "${var.prefix}-${random_id.prefix.hex}"
  resource_group_name       = local.resource_group.name
  kubernetes_version        = "1.25" # don't specify the patch version!
  automatic_channel_upgrade = "patch"
  agents_availability_zones = ["1"]
  agents_count              = null
  agents_max_count          = 10
  agents_max_pods           = 100
  agents_min_count          = 1
  agents_pool_name          = "agentpool"
  agents_pool_linux_os_configs = [
    {
      transparent_huge_page_enabled = "always"
      sysctl_configs = [{
        fs_aio_max_nr               = 65536
        fs_file_max                 = 100000
        fs_inotify_max_user_watches = 1000000
      }]
    }
  ]
  agents_type          = "VirtualMachineScaleSets"
  azure_policy_enabled = true

  enable_auto_scaling                   = true
  enable_host_encryption                = false
  http_application_routing_enabled      = false
  ingress_application_gateway_enabled   = true
  ingress_application_gateway_name      = "${random_id.prefix.hex}-agw"
  ingress_application_gateway_subnet_id = azurerm_subnet.agw.id
  local_account_disabled                = false
  log_analytics_workspace_enabled       = true
  maintenance_window = {
    allowed = [
      {
        day   = "Sunday",
        hours = [22, 23]
      },
    ]
    not_allowed = [
    ]
  }
  net_profile_dns_service_ip        = "10.0.0.10"
  net_profile_service_cidr          = "10.0.0.0/16"
  network_plugin                    = "azure"
  network_policy                    = "azure"
  os_disk_size_gb                   = 60
  private_cluster_enabled           = false
  public_network_access_enabled     = true
  rbac_aad                          = false
  rbac_aad_managed                  = false
  role_based_access_control_enabled = true
  sku_tier                          = "Standard"
  vnet_subnet_id                    = azurerm_subnet.aks.id

  agents_labels = {
  }
  agents_tags = {
  }

  identity_type = "SystemAssigned"

  attached_acr_id_map = {
    acr = var.acr_id
  }
}

data "azurerm_public_ip" "pip" {
  name                = "${module.aks.ingress_application_gateway.gateway_name}-appgwpip"
  resource_group_name = tolist(split("/", module.aks.ingress_application_gateway.effective_gateway_id))[4]
}
