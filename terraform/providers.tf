provider "proxmox" {
  insecure = true

  ssh {
    agent = true
  }
}

provider "authentik" {}