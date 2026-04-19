data "proxmox_virtual_environment_nodes" "nodes" {}

resource "proxmox_virtual_environment_time" "node_time" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  time_zone = "America/New_York"
}

resource "proxmox_virtual_environment_metrics_server" "influxdb" {
  name   = "influxdb"
  server = "192.168.10.11"
  port   = 30115
  type   = "influxdb"

  influx_organization = "Organization"
  influx_bucket       = "proxmox"
  influx_token        = var.influxdb_token
  influx_db_proto     = "http"

  lifecycle {
    ignore_changes = [influx_token]
  }
}

resource "proxmox_virtual_environment_group" "proxmox_admins" {
  comment  = "Managed by Terraform"
  group_id = "proxmox_admins-sso.jrtashjian.com"

  acl {
    path      = "/"
    propagate = true
    role_id   = "Administrator"
  }
}

resource "proxmox_virtual_environment_role" "terraform-automation" {
  role_id = "terraform-automation"

  privileges = [
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.AllocateTemplate",
    "Datastore.Audit",
    "Pool.Allocate",
    "Pool.Audit",
    "SDN.Use",
    "Sys.Audit",
    "Sys.Console",
    "Sys.Modify",
    "VM.Allocate",
    "VM.Audit",
    "VM.Clone",
    "VM.Config.CDROM",
    "VM.Config.Cloudinit",
    "VM.Config.CPU",
    "VM.Config.Disk",
    "VM.Config.HWType",
    "VM.Config.Memory",
    "VM.Config.Network",
    "VM.Config.Options",
    "VM.GuestAgent.Audit",
    "VM.Migrate",
    "VM.PowerMgmt",
  ]
}

resource "proxmox_virtual_environment_user" "terraform_automation" {
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.terraform-automation.role_id
  }

  comment  = "Managed by Terraform"
  password = var.terraform_password
  user_id  = var.terraform_username
}