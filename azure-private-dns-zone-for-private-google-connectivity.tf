# This file creates a private DNS zone in the Azure Virtual Network for *.googleapis.com
# See https://cloud.google.com/vpc/docs/configure-private-google-access-hybrid#config-domain for more info

resource "azurerm_private_dns_zone" "googleapis_com" {
  name                = "googleapis.com"
  resource_group_name = data.azurerm_resource_group.current.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "googleapis_com" {
  name                  = "googleapis.com"
  resource_group_name   = data.azurerm_resource_group.current.name
  private_dns_zone_name = azurerm_private_dns_zone.googleapis_com.name
  virtual_network_id    = data.azurerm_virtual_network.current.id
}

resource "azurerm_private_dns_a_record" "private_googleapis_com" {
  zone_name           = azurerm_private_dns_zone.googleapis_com.name
  resource_group_name = data.azurerm_resource_group.current.name
  ttl                 = 300
  name                = "private"
  records = [
    "199.36.153.8",
    "199.36.153.9",
    "199.36.153.10",
    "199.36.153.11"
  ]
}

resource "azurerm_private_dns_a_record" "restricted_googleapis_com" {
  zone_name           = azurerm_private_dns_zone.googleapis_com.name
  resource_group_name = data.azurerm_resource_group.current.name
  ttl                 = 300
  name                = "restricted"
  records = [
    "199.36.153.4",
    "199.36.153.5",
    "199.36.153.6",
    "199.36.153.7"
  ]
}

resource "azurerm_private_dns_cname_record" "private_googleapis_com" {
  zone_name           = azurerm_private_dns_zone.googleapis_com.name
  resource_group_name = data.azurerm_resource_group.current.name
  ttl                 = 300
  name                = "*"
  record              = "private.googleapis.com"
}
