variable "node_name" {
  description = "proxmox node name"
  type        = string
}

variable "node_datastore" {
  description = "proxmox node default datastore"
  type        = string
  default     = "local-zfs"
}

variable "int_jrtashjian_com_cert" {
  description = "int.jrtashjian.com certificate"
  type        = string
  sensitive   = true
}

variable "int_jrtashjian_com_key" {
  description = "int.jrtashjian.com private key"
  type        = string
  sensitive   = true
}