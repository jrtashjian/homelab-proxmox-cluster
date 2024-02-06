provider "proxmox" {
  insecure = true

  ssh {
    agent = true
  }
}

# Upload wildcard certificate and private key.
resource "proxmox_virtual_environment_certificate" "int_jrtashjian_com" {
  node_name = var.node_name

  certificate = trimspace(var.int_jrtashjian_com_cert)
  private_key = trimspace(var.int_jrtashjian_com_key)
}