resource "azurerm_public_ip" "vpn" {
  count               = 2
  name                = "${var.azure_vpn_name}-${count.index}"
  resource_group_name = data.azurerm_resource_group.current.name
  location            = data.azurerm_resource_group.current.location
  allocation_method   = "Static"
  sku                 = var.azure_public_ip_sku
  availability_zone   = var.azure_public_ip_availability_zone
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = data.azurerm_resource_group.current.name
  virtual_network_name = data.azurerm_virtual_network.current.name
  address_prefixes     = var.azure_gateway_subnet_address_prefixes
}

resource "azurerm_virtual_network_gateway" "to_gcp" {
  name                = var.azure_vpn_name
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name

  type          = "Vpn"
  enable_bgp    = true
  active_active = true
  sku           = var.azure_vpn_sku
  generation    = var.azure_vpn_generation

  bgp_settings {
    asn = var.azure_asn
    dynamic "peering_addresses" {
      for_each = var.azure_bgp_ips
      iterator = ip
      content {
        ip_configuration_name = "vnetGatewayConfig-${ip.key}"
        apipa_addresses       = [ip.value]
      }
    }
  }

  dynamic "ip_configuration" {
    for_each = azurerm_public_ip.vpn
    iterator = ip
    content {
      name                 = "vnetGatewayConfig-${ip.key}"
      public_ip_address_id = ip.value.id
      subnet_id            = azurerm_subnet.gateway.id
    }
  }
}

resource "azurerm_local_network_gateway" "gcp" {
  count               = 2
  name                = "gcp-${count.index}"
  location            = data.azurerm_resource_group.current.location
  resource_group_name = data.azurerm_resource_group.current.name
  gateway_address     = module.vpn-ha-azure.gateway[0].vpn_interfaces[count.index].ip_address
  bgp_settings {
    asn                 = var.gcp_asn
    bgp_peering_address = var.gcp_bgp_ips[count.index]
  }
}

resource "azurerm_virtual_network_gateway_connection" "to_gcp" {
  count                      = 2
  name                       = "to-gcp-${count.index}"
  location                   = data.azurerm_resource_group.current.location
  resource_group_name        = data.azurerm_resource_group.current.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.to_gcp.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp[count.index].id
  shared_key                 = random_id.ipsec_secret.b64_std
  enable_bgp                 = true
}