resource "proxmox_virtual_environment_acme_account" "letsencrypt" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  name = each.value

  contact   = "hello@jrtashjian.com"
  directory = "https://acme-v02.api.letsencrypt.org/directory"
  tos       = "https://letsencrypt.org/documents/LE-SA-v1.6-August-18-2025.pdf"
}

resource "proxmox_virtual_environment_acme_dns_plugin" "cloudflare" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)

  plugin = "cloudflare"
  api    = "cf"

  # Wait 2 minutes for DNS propagation
  validation_delay = 120

  data = {
    CF_Account_ID = var.cloudflare_account_id
    CF_Token      = var.cloudflare_token
    CF_Zone_ID    = var.cloudflare_zone_id
  }
}

resource "proxmox_virtual_environment_acme_certificate" "node_cert" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value
  account   = proxmox_virtual_environment_acme_account.letsencrypt[each.key].name

  domains = [
    {
      domain = "${each.value}.int.jrtashjian.com"
      plugin = proxmox_virtual_environment_acme_dns_plugin.cloudflare[each.key].plugin
    }
  ]

  depends_on = [
    proxmox_virtual_environment_acme_account.letsencrypt,
    proxmox_virtual_environment_acme_dns_plugin.cloudflare
  ]
}
