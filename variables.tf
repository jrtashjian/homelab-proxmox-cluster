variable "influxdb_token" {
  description = "InfluxDB token for Proxmox metrics server"
  type        = string
  sensitive   = true
}

variable "cloudflare_token" {
  description = "Cloudflare API token for ACME DNS validation"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID for ACME DNS validation"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for ACME DNS validation"
  type        = string
}

variable "terraform_username" {
  description = "The username and realm for the Proxmox Virtual Environment API"
  type        = string
}

variable "terraform_password" {
  description = "The password for the Proxmox Virtual Environment API"
  type        = string
  sensitive   = true
}

variable "nodes_with_machines" {
  description = "Nodes that have the 'machines' ZFS pool"
  type        = list(string)
  default     = ["pve-node01", "pve-node02", "pve-node03"]
}

variable "nodes_with_machines_fast" {
  description = "Nodes that have the 'machines-fast' ZFS pool"
  type        = list(string)
  default     = ["pve-node02", "pve-node03"]
}
