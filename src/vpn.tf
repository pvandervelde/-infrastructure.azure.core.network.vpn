terraform {
    backend "local" {
    }
}

provider "azurerm" {
  alias  = "production"

  features {}

  subscription_id = var.subscription_production

  version = "~>2.18.0"
}

provider "azurerm" {
    #alias = "target"

    features {}

    subscription_id = var.environment == "production" ? var.subscription_production : var.subscription_test

    version = "~>2.18.0"
}

#
# LOCALS
#

locals {
  location_map = {
    australiacentral = "auc",
    australiacentral2 = "auc2",
    australiaeast = "aue",
    australiasoutheast = "ause",
    brazilsouth = "brs",
    canadacentral = "cac",
    canadaeast = "cae",
    centralindia = "inc",
    centralus = "usc",
    eastasia = "ase",
    eastus = "use",
    eastus2 = "use2",
    francecentral = "frc",
    francesouth = "frs",
    germanynorth = "den",
    germanywestcentral = "dewc",
    japaneast = "jpe",
    japanwest = "jpw",
    koreacentral = "krc",
    koreasouth = "kre",
    northcentralus = "usnc",
    northeurope = "eun",
    norwayeast = "noe",
    norwaywest = "now",
    southafricanorth = "zan",
    southafricawest = "zaw",
    southcentralus = "ussc",
    southeastasia = "asse",
    southindia = "ins",
    switzerlandnorth = "chn",
    switzerlandwest = "chw",
    uaecentral = "aec",
    uaenorth = "aen",
    uksouth = "uks",
    ukwest = "ukw",
    westcentralus = "uswc",
    westeurope = "euw",
    westindia = "inw",
    westus = "usw",
    westus2 = "usw2",
  }
}

locals {
  environment_short = substr(var.environment, 0, 1)
  location_short = lookup(local.location_map, var.location, "aue")
}

# Name prefixes
locals {
  name_prefix = "${local.environment_short}-${local.location_short}"
  name_prefix_tf = "${local.name_prefix}-tf-${var.category}"
}

locals {
  common_tags = {
    category    = "${var.category}"
    environment = "${var.environment}"
    location    = "${var.location}"
    source      = "${var.meta_source}"
    version     = "${var.meta_version}"
  }

  extra_tags = {
  }
}

data "azurerm_client_config" "current" {}

locals {
  vnet_resource_group = "p-aue-tf-nwk-hub-rg"
}

data "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name = "p-aue-tf-analytics-law-logs"
  provider = azurerm.production
  resource_group_name = "p-aue-tf-analytics-rg"
}

data "azurerm_virtual_network" "vnet" {
  name = "p-aue-tf-nwk-hub-vn"
  provider = azurerm.production
  resource_group_name = local.vnet_resource_group
}

data "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  provider = azurerm.production
  resource_group_name  = local.vnet_resource_group
  virtual_network_name = "p-aue-tf-nwk-hub-vn"
}

#
# Gateway
#

resource "random_string" "dns" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_public_ip" "vpn" {
  allocation_method = "Dynamic"
  location = var.location
  name = "${local.name_prefix_tf}-pip"
  resource_group_name = local.vnet_resource_group
  sku = "Basic"
  tags = merge( local.common_tags, local.extra_tags, var.tags )
}

resource "azurerm_monitor_diagnostic_setting" "vpn_pip" {
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics_workspace.id
  name = "${local.name_prefix_tf}-pip-log-analytics"
  target_resource_id = azurerm_public_ip.vpn.id

  log {
    category = "DDoSProtectionNotifications"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "DDoSMitigationFlowLogs"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "DDoSMitigationReports"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name = "${local.name_prefix_tf}-gw"
  location = var.location
  resource_group_name = local.vnet_resource_group

  type     = "Vpn"
  vpn_type = "RouteBased"
  generation = "None"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name = "${local.name_prefix_tf}-gw-config"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vpn.id
    subnet_id = data.azurerm_subnet.gateway_subnet.id
  }

  tags = merge( local.common_tags, local.extra_tags, var.tags )
}

resource "azurerm_monitor_diagnostic_setting" "vpn" {
  name = "${local.name_prefix_tf}-analytics"
  target_resource_id = azurerm_virtual_network_gateway.vpn.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_analytics_workspace.id

  log {
    category = "GatewayDiagnosticLog"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "TunnelDiagnosticLog"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "RouteDiagnosticLog"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "IKEDiagnosticLog"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "P2SDiagnosticLog"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_local_network_gateway" "local" {
  address_space = [ var.local_network_address_space ]
  gateway_address = var.local_network_gateway_address
  location = var.location
  name  = "${local.name_prefix_tf}-lng"
  resource_group_name = local.vnet_resource_group

  tags = merge( local.common_tags, local.extra_tags, var.tags )
}

resource "azurerm_virtual_network_gateway_connection" "local" {
  name = "${local.name_prefix_tf}-lngc"
  location = var.location
  resource_group_name = local.vnet_resource_group

  type = "IPSec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn.id
  local_network_gateway_id  = azurerm_local_network_gateway.local.id

  shared_key = var.local_network_shared_key

  tags = merge( local.common_tags, local.extra_tags, var.tags )
}
