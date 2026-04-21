data "proxmox_virtual_environment_datastores" "datastores" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value
}

locals {
  # Build a clean map: node_name => { iso, snippets, vztmpl }
  datastore = {
    for node in data.proxmox_virtual_environment_nodes.nodes.names : node => {
      iso      = one([for ds in data.proxmox_virtual_environment_datastores.datastores[node].datastores : ds.id if contains(ds.content_types, "iso")])
      snippets = one([for ds in data.proxmox_virtual_environment_datastores.datastores[node].datastores : ds.id if contains(ds.content_types, "snippets")])
      vztmpl   = one([for ds in data.proxmox_virtual_environment_datastores.datastores[node].datastores : ds.id if contains(ds.content_types, "vztmpl")])
    }
  }
}

resource "proxmox_virtual_environment_file" "debian_container_template" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  content_type = "vztmpl"
  datastore_id = local.datastore[each.value].vztmpl

  source_file {
    path = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  }
}

resource "proxmox_virtual_environment_file" "debian_vendor_config" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  content_type = "snippets"
  datastore_id = local.datastore[each.value].snippets

  source_raw {
    data = <<-EOF
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
