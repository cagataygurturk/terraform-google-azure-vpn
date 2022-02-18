module "vpn-ha-azure" {
  depends_on = [
    azurerm_virtual_network_gateway.to_gcp
  ]
  source     = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version    = "~> 2.2"
  project_id = data.google_project.gcp_project.project_id
  network    = data.google_compute_network.vpc.self_link
  region     = var.gcp_vpn_region
  name       = var.gcp_vpn_name
  router_asn = var.gcp_asn

  router_advertise_config = {
    mode   = "CUSTOM"
    groups = ["ALL_SUBNETS"]
    # See https://cloud.google.com/vpc/docs/configure-private-google-access-hybrid#config-routing
    ip_ranges = {
      "199.36.153.8/30" : "private.googleapis.com",
      "199.36.153.4/30" : "restricted.googleapis.com"
    }
  }

  peer_external_gateway = {
    redundancy_type = "TWO_IPS_REDUNDANCY"
    interfaces = [
      for k, ip in azurerm_public_ip.vpn : {
        id         = k
        ip_address = ip.ip_address
      }
    ]
  }

  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = var.azure_bgp_ips[0]
        asn     = var.azure_asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "${var.gcp_bgp_ips[0]}/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = 0
      shared_secret                   = random_id.ipsec_secret.b64_std
    }
    remote-1 = {
      bgp_peer = {
        address = var.azure_bgp_ips[1]
        asn     = var.azure_asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "${var.gcp_bgp_ips[1]}/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = 1
      shared_secret                   = random_id.ipsec_secret.b64_std
    }
  }
}
