variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Specifies the name of the resource group the Virtual Network Gateway is located in."
}

variable "azure_vpn_name" {
  type        = string
  description = "Specifies the name of the Azure Virtual Network Gateway."
  default     = "to-gcp"
}

variable "azure_vnet_name" {
  type        = string
  description = "Specifies the name of the Azure Virtual Network the Virtual Network Gateway is located in."
}

variable "azure_vpn_sku" {
  type        = string
  description = "Configuration of the size and capacity of the Azure Virtual Network Gateway."
  default     = "VpnGw1AZ"
}

variable "azure_vpn_generation" {
  type        = string
  description = "The Generation of the Virtual Network Gateway."
  default     = "Generation1"
}

variable "azure_public_ip_availability_zone" {
  type        = string
  description = "The availability zone to allocate the Public IP in. Possible values are Zone-Redundant, 1, 2, 3, and No-Zone. Note that standard Public IPs associated with VPN Gateways with AZ VPN skus must have zones configured."
  default     = "Zone-Redundant"
}

variable "azure_public_ip_sku" {
  type        = string
  description = "The SKU of the Public IP. Accepted values are Basic and Standard."
  default     = "Standard"
}

variable "azure_gateway_subnet_address_prefixes" {
  type        = list(string)
  description = "The CIDR of the gateway subnet of a virtual network in which the virtual network gateway will be created."
}

variable "azure_asn" {
  type        = number
  description = "Specifies the ASN of Azure side of the BGP session"
  default     = 65515
}

# GCP variables
variable "gcp_project_id" {
  type        = string
  description = "Specifies the project ID of Google project the VPN will be located in"
}

variable "gcp_network_name" {
  type        = string
  description = "Specifies the name of the VPC the VPN will be located in"
}

variable "gcp_vpn_region" {
  type        = string
  description = "Specifies the GCP region the VPN will be located in"
}

variable "gcp_vpn_name" {
  type        = string
  description = "Specifies the name of the GCP VPN"
  default     = "to-azure"
}

variable "gcp_asn" {
  type        = number
  description = "Specifies the ASN of GCP side of the BGP session"
  default     = 65516
}

variable "azure_bgp_ips" {
  type = list(string)
  default = [
    "169.254.21.1",
    "169.254.22.1"
  ]
}

variable "gcp_bgp_ips" {
  type = list(string)
  default = [
    "169.254.21.2",
    "169.254.22.2"
  ]
}

## Data sources

# Randomly generated IPSec secret is used for both VPNs
resource "random_id" "ipsec_secret" {
  byte_length = 8
}

# Azure infrastructure
data "azurerm_subscription" "current" {
  subscription_id = var.azure_subscription_id
}

data "azurerm_resource_group" "current" {
  name = var.azure_resource_group_name
}

data "azurerm_virtual_network" "current" {
  resource_group_name = data.azurerm_resource_group.current.name
  name                = var.azure_vnet_name
}

# GCP Infrastructure
data "google_project" "gcp_project" {
  project_id = var.gcp_project_id
}

data "google_compute_network" "vpc" {
  project = data.google_project.gcp_project.project_id
  name    = var.gcp_network_name
}