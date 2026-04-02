# Proxmox Cluster Terraform Configuration

This configuration manages the baseline setup of a Proxmox VE cluster. It configures cluster-wide settings including node time zones, network VLANs, firewall aliases and rules, NFS backup storage, daily backup jobs, and InfluxDB metrics reporting. A dedicated Terraform automation user and role are also provisioned with the necessary privileges.

Additionally, this configuration manages ACME certificate issuance for each node via Let's Encrypt with Cloudflare DNS validation, and integrates with Authentik for SSO authentication on the Proxmox web UI.

## Local Development

To run Terraform commands locally, use the provided `.env.example` as a template:

```bash
cp .env.example .env
```

Fill in the values in `.env` using [1Password Secret References](https://developer.1password.com/docs/cli/secret-references/) (e.g. `op://vault/item/field`) or plain values. Then use the [1Password CLI](https://developer.1password.com/docs/cli) to inject secrets at runtime:

```bash
# Preview changes
op run --env-file=".env" -- terraform plan

# Apply changes
op run --env-file=".env" -- terraform apply
```

> [!IMPORTANT]
> Before applying for the first time, import existing node resources into Terraform state for each node:
> ```bash
> op run --env-file=".env" -- ./import-resources.sh <node-name>
> ```

## Variables for CI/CD Pipeline

A GitLab environment is created by the CI/CD pipeline for each Proxmox cluster this Terraform project is deployed to. Each environment is named after the hostname of the primary node in the cluster (`pve-node01`, `pve-node02`, etc).

The pipeline utilizes [1Password Service Account](https://developer.1password.com/docs/service-accounts) for retrieving passwords [defined as variables](https://docs.gitlab.com/ee/ci/variables/#define-a-cicd-variable-in-the-ui) using the [Secret Reference](https://developer.1password.com/docs/cli/secret-references/) syntax.

### GitLab CI/CD Workflow Variables

Required by the GitLab CI/CD workflow itself. Set these as CI/CD variables in the GitLab project settings.

| Variable | Description |
|---|---|
| `OP_SERVICE_ACCOUNT_TOKEN` | The service account token used by the GitLab CI/CD workflow to authenticate with 1Password. |

### Environment Variables

Credentials passed to Terraform at runtime via 1Password secret references. Set these as CI/CD variables in the GitLab environment for each cluster.

| Variable | Description |
|---|---|
| `PROXMOX_VE_ENDPOINT` | The URL of the Proxmox Virtual Environment API endpoint. |
| `PROXMOX_VE_USERNAME` | The username and realm for the Proxmox Virtual Environment API. |
| `PROXMOX_VE_PASSWORD` | The password for the Proxmox Virtual Environment API. |
| `AUTHENTIK_URL` | The URL of the Authentik instance. |
| `AUTHENTIK_TOKEN` | The API token for the Authentik instance. |
| `TF_VAR_terraform_username` | The username and realm Terraform uses to authenticate with the Proxmox Virtual Environment API. |
| `TF_VAR_terraform_password` | The password Terraform uses to authenticate with the Proxmox Virtual Environment API. |
| `TF_VAR_influxdb_token` | InfluxDB token for Proxmox metrics server. |
| `TF_VAR_cloudflare_token` | Cloudflare API token for ACME DNS validation. |
| `TF_VAR_cloudflare_account_id` | Cloudflare Account ID for ACME DNS validation. |
| `TF_VAR_cloudflare_zone_id` | Cloudflare Zone ID for ACME DNS validation. |
