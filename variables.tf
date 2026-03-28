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
