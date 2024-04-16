provider "proxmox" {
  insecure = true

  ssh {
    agent = true
  }
}

data "proxmox_virtual_environment_nodes" "nodes" {}

# Upload wildcard certificate and private key.
resource "proxmox_virtual_environment_certificate" "int_jrtashjian_com" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  certificate = trimspace(var.int_jrtashjian_com_cert)
  private_key = trimspace(var.int_jrtashjian_com_key)
}

# Create DMZ VLAN.
resource "proxmox_virtual_environment_network_linux_vlan" "dmz" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  name    = "vlan_dmz"
  comment = "DMZ"

  interface = "vmbr0"
  vlan      = 66
  address   = "192.168.66.0/24"
}

# Add firewall aliases.
resource "proxmox_virtual_environment_firewall_alias" "lan_network" {
  name    = "LAN"
  cidr    = "192.168.10.0/24"
  comment = "Managed by Terraform"
}
resource "proxmox_virtual_environment_firewall_alias" "dmz_network" {
  name    = "DMZ"
  cidr    = "192.168.66.0/24"
  comment = "Managed by Terraform"
}
resource "proxmox_virtual_environment_firewall_alias" "opt1_network" {
  name    = "OPT1"
  cidr    = "192.168.20.0/24"
  comment = "Managed by Terraform"
}
resource "proxmox_virtual_environment_firewall_alias" "opt2_network" {
  name    = "OPT2"
  cidr    = "192.168.30.0/24"
  comment = "Managed by Terraform"
}

# By default, certain network traffic is still permitted at the datacenter level.
# For more details, see: https://pve.proxmox.com/pve-docs/chapter-pve-firewall.html#_datacenter_incoming_outgoing_drop_reject
resource "proxmox_virtual_environment_cluster_firewall" "cluster_firewall" {
  enabled = true

  ebtables      = true
  input_policy  = "DROP"
  output_policy = "ACCEPT"

  log_ratelimit {
    enabled = false
  }
}

# Only allow SSH from the LAN.
resource "proxmox_virtual_environment_cluster_firewall_security_group" "ssh-server" {
  name    = "ssh-server"
  comment = "Managed by Terraform"

  rule {
    type    = "in"
    action  = "ACCEPT"
    macro   = "SSH"
    source  = proxmox_virtual_environment_firewall_alias.lan_network.name
    comment = "Allow SSH from LAN"
    log     = "nolog"
  }

  rule {
    type    = "in"
    action  = "DROP"
    macro   = "SSH"
    comment = "Drop SSH"
    log     = "nolog"
  }
}