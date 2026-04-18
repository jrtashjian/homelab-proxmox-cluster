#!/usr/bin/env sh

NODE="${1:?Usage: $0 <node-name>}"

terraform import "proxmox_virtual_environment_apt_standard_repository.enterprise[\"${NODE}\"]" "${NODE},enterprise"
terraform import "proxmox_virtual_environment_apt_standard_repository.ceph-squid-enterprise[\"${NODE}\"]" "${NODE},ceph-squid-enterprise"