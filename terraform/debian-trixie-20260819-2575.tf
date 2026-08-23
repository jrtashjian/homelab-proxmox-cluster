resource "proxmox_virtual_environment_download_file" "debian_13_trixie_cloud_image" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  content_type = "iso"
  datastore_id = local.datastore[each.value].iso

  url = "https://cloud.debian.org/images/cloud/trixie/20260819-2575/debian-13-genericcloud-amd64-20260819-2575.qcow2"

  checksum           = "77429b411b39b43f914dc9d14bf34aa315489a1a12b5429f72e5b483bdda23c65698d33443c85d3f3ad7c3a0828ae60845406d6b99646342554d17abae29c2a3"
  checksum_algorithm = "sha512"

  file_name = "debian-13-trixie.img"
  overwrite = false
}

resource "proxmox_virtual_environment_vm" "debian_13_trixie_template" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  name     = "cloudinit-debian-13-trixie"
  template = true

  machine = "q35,viommu=intel"

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    type = "x86-64-v2-AES"
  }

  disk {
    datastore_id = local.datastore[each.value].images
    file_id      = proxmox_virtual_environment_download_file.debian_13_trixie_cloud_image[each.value].id
    interface    = "scsi0"
    discard      = "on"
    iothread     = true
  }

  scsi_hardware = "virtio-scsi-single"
  boot_order    = ["scsi0"]

  network_device {
    firewall = true
  }

  vga {
    type = "serial0"
  }

  serial_device {}

  initialization {
    datastore_id        = local.datastore[each.value].images
    vendor_data_file_id = proxmox_virtual_environment_file.debian_vendor_config[each.value].id
  }
}
