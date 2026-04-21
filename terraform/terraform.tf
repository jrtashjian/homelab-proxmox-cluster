terraform {
  backend "http" {
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.103.0"
    }

    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.10.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.7"
}
