resource "proxmox_virtual_environment_apt_standard_repository" "enterprise" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node     = each.value

  handle = "enterprise"
}

resource "proxmox_virtual_environment_apt_repository" "enterprise" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)

  enabled = false

  file_path = proxmox_virtual_environment_apt_standard_repository.enterprise[each.key].file_path
  index     = proxmox_virtual_environment_apt_standard_repository.enterprise[each.key].index
  node      = proxmox_virtual_environment_apt_standard_repository.enterprise[each.key].node
}

resource "proxmox_virtual_environment_apt_standard_repository" "ceph-squid-enterprise" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node     = each.value

  handle = "ceph-squid-enterprise"
}

resource "proxmox_virtual_environment_apt_repository" "ceph-squid-enterprise" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)

  enabled = false

  file_path = proxmox_virtual_environment_apt_standard_repository.ceph-squid-enterprise[each.key].file_path
  index     = proxmox_virtual_environment_apt_standard_repository.ceph-squid-enterprise[each.key].index
  node      = proxmox_virtual_environment_apt_standard_repository.ceph-squid-enterprise[each.key].node
}

resource "proxmox_virtual_environment_apt_standard_repository" "no-subscription" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node     = each.value

  handle = "no-subscription"
}

resource "proxmox_virtual_environment_apt_repository" "no-subscription" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)

  enabled = true

  file_path = proxmox_virtual_environment_apt_standard_repository.no-subscription[each.key].file_path
  index     = proxmox_virtual_environment_apt_standard_repository.no-subscription[each.key].index
  node      = proxmox_virtual_environment_apt_standard_repository.no-subscription[each.key].node
}

resource "proxmox_virtual_environment_apt_standard_repository" "ceph-squid-no-subscription" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node     = each.value

  handle = "ceph-squid-no-subscription"
}

resource "proxmox_virtual_environment_apt_repository" "ceph-squid-no-subscription" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)

  enabled = true

  file_path = proxmox_virtual_environment_apt_standard_repository.ceph-squid-no-subscription[each.key].file_path
  index     = proxmox_virtual_environment_apt_standard_repository.ceph-squid-no-subscription[each.key].index
  node      = proxmox_virtual_environment_apt_standard_repository.ceph-squid-no-subscription[each.key].node
}