provider "proxmox" {
  insecure = true

  ssh {
    agent = true
  }
}

provider "authentik" {}

data "proxmox_virtual_environment_nodes" "nodes" {}

resource "proxmox_virtual_environment_time" "node_time" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value

  time_zone = "America/New_York"
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

resource "proxmox_virtual_environment_storage_zfspool" "machines" {
  nodes = data.proxmox_virtual_environment_nodes.nodes.names

  id       = "machines"
  zfs_pool = "machines"

  content = ["images", "rootdir"]
}

# Backup NFS storage.
resource "proxmox_virtual_environment_storage_nfs" "nfs_backup" {
  nodes = data.proxmox_virtual_environment_nodes.nodes.names

  id     = "nfs-backup"
  server = "192.168.10.11"
  export = "/mnt/kraken_z2_primary/Backups/Proxmox_Virtual_Machines"

  content = ["backup"]

  backups {
    max_protected_backups = 5
    keep_daily            = 7
  }
}

resource "proxmox_backup_job" "daily_backup" {
  id             = "daily-backup"
  schedule       = "21:00" # Every day at 9:00 PM
  storage        = proxmox_virtual_environment_storage_nfs.nfs_backup.id
  all            = true
  mode           = "snapshot"
  compress       = "zstd"
  notes_template = "{{guestname}}"
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

# AUTHENTIK
data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_property_mapping_provider_scope" "oauth" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-offline_access",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

resource "random_password" "pve-node-client-id" {
  length  = 64
  special = false
}

resource "authentik_provider_oauth2" "pve-node" {
  name = "Provider for ${data.proxmox_virtual_environment_nodes.nodes.names[0]}"

  client_id          = random_password.pve-node-client-id.result
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id

  allowed_redirect_uris = [
    for node in data.proxmox_virtual_environment_nodes.nodes.names : {
      matching_mode = "strict"
      url           = "https://${node}.int.jrtashjian.com:8006"
    }
  ]

  sub_mode = "user_email"

  property_mappings = data.authentik_property_mapping_provider_scope.oauth.ids
  signing_key       = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "pve-node" {
  name              = data.proxmox_virtual_environment_nodes.nodes.names[0]
  slug              = data.proxmox_virtual_environment_nodes.nodes.names[0]
  protocol_provider = authentik_provider_oauth2.pve-node.id

  meta_icon        = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/proxmox-light.svg"
  meta_description = "Managed by Terraform"

  group = "Infrastructure"
}

resource "proxmox_virtual_environment_realm_openid" "authentik" {
  realm      = "sso.jrtashjian.com"
  issuer_url = "https://sso.jrtashjian.com/application/o/${data.proxmox_virtual_environment_nodes.nodes.names[0]}/"
  client_id  = authentik_provider_oauth2.pve-node.client_id
  client_key = authentik_provider_oauth2.pve-node.client_secret

  # Username mapping
  username_claim = "username"

  # User provisioning
  autocreate = true

  # Group mapping
  groups_claim      = "groups"
  groups_autocreate = false

  # Scopes and prompt
  scopes         = "email profile"
  query_userinfo = true

  default = true
}

# APT Repository
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
