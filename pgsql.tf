resource "azurerm_subnet" "subnet_pgsql" {
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  name                 = "${var.prefix}-pgsql-subnet"
  address_prefixes     = ["10.52.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  depends_on           = [azurerm_virtual_network.vnet]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "dnszone" {
  name                = "${var.prefix}-${random_id.prefix.hex}.postgres.database.azure.com"
  resource_group_name = local.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "${var.prefix}-${random_id.prefix.hex}-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.dnszone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = local.resource_group.name
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "azurerm_postgresql_flexible_server" "postgresql_server" {
  name                   = "${var.prefix}-${random_id.prefix.hex}-db"
  resource_group_name    = local.resource_group.name
  location               = local.resource_group.location
  version                = "13"
  delegated_subnet_id    = azurerm_subnet.subnet_pgsql.id
  private_dns_zone_id    = azurerm_private_dns_zone.dnszone.id
  administrator_login    = "postgres"
  administrator_password = random_password.db_password.result
  zone                   = ["1", "2"]

  storage_mb = 131072

  sku_name   = "GP_Standard_D2s_v3"
  depends_on = [azurerm_subnet.subnet_pgsql, azurerm_private_dns_zone_virtual_network_link.dns_link]

}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.postgresql_server.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
