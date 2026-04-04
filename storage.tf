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
  server = "192.168.30.11"
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