<!-- BEGIN_TF_DOCS -->
# VPN between GCP and Azure

This repository contains a drop-in Terraform template that sets up a HA VPN between Azure and Google Cloud Platform.

Features:

- On GCP side a [HA VPN](https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview) is set up with two tunnels.
- On Azure side an [Azure Virtual VPN](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways) is set up with two connections. By default, a zone-redundant SKU is set (`VpnGw1AZ`) but it is possible to change the SKU to support higher bandwidths.
- Both VPNs are configured to exchange the same randomly generated secret.
- Both VPNs are configured to establish BGP sessions between each other, so Azure VNET and Google Cloud VPC automatically learns the routes from each other.
- Proper routes are propagated from the GCP side to enable Private Google Access from Azure (see [below](#private-google-access))
- A private DNS zone is created on the Azure side to support private connectivity to GCP APIs. (see [here](https://cloud.google.com/vpc-service-controls/docs/set-up-private-connectivity#configure-dns))

## Installation

This stack requires the following resources:

- On Azure side: A subscription, a resource group and a Virtual Network
- On GCP side: A project, a VPC network

Many variables have default values. For those without default values, check out [terraform.tfvars](terraform.tfvars).

## Example usage

````terraform
module "vpn" {
  depends_on = [google_compute_network.vpc, azurerm_virtual_network.vnet, azurerm_resource_group.test]
  source           = "registry.terraform.io/cagataygurturk/azure-vpn/google"
  gcp_project_id   = "example-project-id"
  gcp_network_name = "vpc-network"
  gcp_vpn_region   = "us-central1"

  azure_resource_group_name             = "example-resource-group"
  azure_vnet_name                       = "example-vnet"
  azure_gateway_subnet_address_prefixes = ["172.16.10.0/24"]
}
````

## Private Google Access

Google Cloud APIs (such as Storage, BigQuery, Pub/Sub) typically operate over the public Internet by default. However, in environments where security policies prohibit such configurations, it's possible to access Google APIs using private IP addresses. These addresses can be made accessible to on-premises and other cloud provider environments via VPNs or Interconnects. This capability is referred to as [Private Google Access](https://cloud.google.com/vpc/docs/configure-private-google-access-hybrid).

This Terraform module also enables Private Google Access by advertising the necessary IP addresses to the Azure side via BGP and establishing a private DNS zone. This setup assists the GCP SDK in directing requests through these IP addresses instead of relying on the public Internet. In other words, as soon as this module is set up on your environment, all the Google API requests from Azure side will be routed through the VPN tunnel. At this moment, it is not possible to turn off this feature. Please file a feature request if you need this feature.

If your objective is to restrict Google APIs solely to private IPs and block public Internet access altogether, you may want to explore [VPC Service Controls](https://cloud.google.com/vpc-service-controls).`

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 2 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.7, < 6 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 5.7, < 6 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 2 |
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.7, < 6 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.4 |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_virtual_network.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_project.gcp_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_asn"></a> [azure\_asn](#input\_azure\_asn) | Specifies the ASN of Azure side of the BGP session | `number` | `65515` | no |
| <a name="input_azure_bgp_ips"></a> [azure\_bgp\_ips](#input\_azure\_bgp\_ips) | n/a | `list(string)` | <pre>[<br>  "169.254.21.1",<br>  "169.254.22.1"<br>]</pre> | no |
| <a name="input_azure_gateway_subnet_address_prefixes"></a> [azure\_gateway\_subnet\_address\_prefixes](#input\_azure\_gateway\_subnet\_address\_prefixes) | The CIDR of the gateway subnet of a virtual network in which the virtual network gateway will be created. | `list(string)` | n/a | yes |
| <a name="input_azure_public_ip_availability_zone"></a> [azure\_public\_ip\_availability\_zone](#input\_azure\_public\_ip\_availability\_zone) | The availability zone to allocate the Public IP in. Possible values are Zone-Redundant, 1, 2, 3, and No-Zone. Note that standard Public IPs associated with VPN Gateways with AZ VPN skus must have zones configured. | `string` | `"Zone-Redundant"` | no |
| <a name="input_azure_public_ip_sku"></a> [azure\_public\_ip\_sku](#input\_azure\_public\_ip\_sku) | The SKU of the Public IP. Accepted values are Basic and Standard. | `string` | `"Standard"` | no |
| <a name="input_azure_resource_group_name"></a> [azure\_resource\_group\_name](#input\_azure\_resource\_group\_name) | Specifies the name of the resource group the Virtual Network Gateway is located in. | `string` | n/a | yes |
| <a name="input_azure_vnet_name"></a> [azure\_vnet\_name](#input\_azure\_vnet\_name) | Specifies the name of the Azure Virtual Network the Virtual Network Gateway is located in. | `string` | n/a | yes |
| <a name="input_azure_vpn_generation"></a> [azure\_vpn\_generation](#input\_azure\_vpn\_generation) | The Generation of the Virtual Network Gateway. | `string` | `"Generation1"` | no |
| <a name="input_azure_vpn_name"></a> [azure\_vpn\_name](#input\_azure\_vpn\_name) | Specifies the name of the Azure Virtual Network Gateway. | `string` | `"to-gcp"` | no |
| <a name="input_azure_vpn_sku"></a> [azure\_vpn\_sku](#input\_azure\_vpn\_sku) | Configuration of the size and capacity of the Azure Virtual Network Gateway. | `string` | `"VpnGw1AZ"` | no |
| <a name="input_gcp_asn"></a> [gcp\_asn](#input\_gcp\_asn) | Specifies the ASN of GCP side of the BGP session | `number` | `65516` | no |
| <a name="input_gcp_bgp_ips"></a> [gcp\_bgp\_ips](#input\_gcp\_bgp\_ips) | n/a | `list(string)` | <pre>[<br>  "169.254.21.2",<br>  "169.254.22.2"<br>]</pre> | no |
| <a name="input_gcp_network_name"></a> [gcp\_network\_name](#input\_gcp\_network\_name) | Specifies the name of the VPC the VPN will be located in | `string` | n/a | yes |
| <a name="input_gcp_project_id"></a> [gcp\_project\_id](#input\_gcp\_project\_id) | Specifies the project ID of Google project the VPN will be located in | `string` | n/a | yes |
| <a name="input_gcp_vpn_name"></a> [gcp\_vpn\_name](#input\_gcp\_vpn\_name) | Specifies the name of the GCP VPN | `string` | `"to-azure"` | no |
| <a name="input_gcp_vpn_region"></a> [gcp\_vpn\_region](#input\_gcp\_vpn\_region) | Specifies the GCP region the VPN will be located in | `string` | n/a | yes |

## Outputs

No outputs.

## License

[Apache License 2.0](LICENSE)
<!-- END_TF_DOCS -->