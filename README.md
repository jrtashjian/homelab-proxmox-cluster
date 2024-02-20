
## Variables for CI/CD Pipeline

A GitLab environment is created by the CI/CD pipeline for each Proxmox cluster this Terraform project is deployed to. Each environment is named after the hostname of the primary node in the cluster (`pve-node01`, `pve-node02`, etc).

The pipeline utilizes [1Password Service Account](https://developer.1password.com/docs/service-accounts) for retrieving passwords [defined as variables](https://docs.gitlab.com/ee/ci/variables/#define-a-cicd-variable-in-the-ui) using the [Secret Reference](https://developer.1password.com/docs/cli/secret-references/) syntax.

### `OP_SERVICE_ACCOUNT_TOKEN`

The service account token of the service account to use.

---

### `PROXMOX_VE_USERNAME`

The username and realm for the Proxmox Virtual Environment API

### `PROXMOX_VE_PASSWORD`

The password for the Proxmox Virtual Environment API

---

### `TF_VAR_int_jrtashjian_com_cert`

The certificate chain.

### `TF_VAR_int_jrtashjian_com_key`

The certificate private key.
