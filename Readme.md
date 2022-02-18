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

## Private Google Access

Google Cloud APIs (e.g. Storage, BigQuery, Pub/Sub) are by default running on public Internet. In environments where security policies do not allow such a setup, it is possible to access to Google APIs through private IP addresses. Those addresses can be made available to on-premise and other cloud provider environments via VPN or Interconnects. This feature is called as [Private Google Access](https://cloud.google.com/vpc/docs/configure-private-google-access-hybrid).

This Terraform stack also sets Private Google Access by announcing the required IP addresses to Azure side via BGP and setting up a private DNS zone to help GCP SDK to send requests through these IPs instead of public Internet.

If you want to restrict Google APIs to private IPs and block public Internet access, check [VPC Service Controls](https://cloud.google.com/vpc-service-controls) out.