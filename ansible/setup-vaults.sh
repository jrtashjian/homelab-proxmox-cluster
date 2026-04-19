#!/usr/bin/env bash

set -o errexit
set -o nounset

# Colors
GREEN_BG='\033[0;42m'
RED_BG='\033[0;41m'
YELLOW_BG='\033[1;43m'
NC='\033[0m' # No Color

log() {
    echo -e "$1"
}

success() {
    echo -e "${GREEN_BG} OK ${NC} $1"
}

warn() {
    echo -e "\n${YELLOW_BG} WARN ${NC} $1\n"
}

error_exit() {
    echo -e "${RED_BG} ERROR ${NC} $1"
    exit 1
}

encrypt_vault_file() {
    local example_file=$1
    local output_file=$2

    log "Processing $output_file..."
    op inject -i $example_file -o $output_file --force > /dev/null
    ansible-vault encrypt $output_file
}

fetch_1password_item() {
    local item_path=$1
    local output_file=$2

    op read "$item_path" -o "$output_file" --force > /dev/null || error_exit "Failed to fetch $item_path"
    success "Fetched $item_path"
}

fetch_1password_item "op://homelab/ansible-user/Credentials/.ansible-vault-password" ".ansible-vault-password"

vault_files=(
    "host_vars/pve-node01.int.jrtashjian.com/vault.yml"
    "host_vars/pve-node02.int.jrtashjian.com/vault.yml"
    "host_vars/pve-node03.int.jrtashjian.com/vault.yml"
)
for file in "${vault_files[@]}"; do
    encrypt_vault_file "${file}.example" "$file"
done
