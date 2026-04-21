
resource "proxmox_virtual_environment_file" "debian_container_template" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  content_type = "vztmpl"
  datastore_id = "local"

  source_file {
    path = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  }
}

resource "proxmox_virtual_environment_download_file" "debian_cloud_image" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  content_type = "iso"
  datastore_id = "local"

  url = "https://cloud.debian.org/images/cloud/trixie/20260402-2435/debian-13-genericcloud-amd64-20260402-2435.qcow2"

  checksum           = "df0f1b09350658b0f42b83337682f36d7b821ea3a438d8257906e25350d2f92b0dcce810b0e6958887fb5210fd48625b8330339673df1ded127ffc0a969c12e5"
  checksum_algorithm = "sha512"

  file_name = "debian-13-genericcloud-amd64.img"
  overwrite = false
}

resource "proxmox_virtual_environment_file" "debian_vendor_config" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data      = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
    EOF

    file_name = "debian-vendor-config.yml"
  }
}