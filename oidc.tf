data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_property_mapping_provider_scope" "oauth" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-offline_access",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

resource "random_password" "pve-node-client-id" {
  length  = 64
  special = false
}

resource "authentik_provider_oauth2" "pve-node" {
  name = "Provider for ${data.proxmox_virtual_environment_nodes.nodes.names[0]}"

  client_id          = random_password.pve-node-client-id.result
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id

  allowed_redirect_uris = [
    for node in data.proxmox_virtual_environment_nodes.nodes.names : {
      matching_mode = "strict"
      url           = "https://${node}.int.jrtashjian.com:8006"
    }
  ]

  sub_mode = "user_email"

  property_mappings = data.authentik_property_mapping_provider_scope.oauth.ids
  signing_key       = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "pve-node" {
  name              = data.proxmox_virtual_environment_nodes.nodes.names[0]
  slug              = data.proxmox_virtual_environment_nodes.nodes.names[0]
  protocol_provider = authentik_provider_oauth2.pve-node.id

  meta_icon        = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/proxmox-light.svg"
  meta_description = "Managed by Terraform"

  group = "Infrastructure"
}

resource "proxmox_virtual_environment_realm_openid" "authentik" {
  realm      = "sso.jrtashjian.com"
  issuer_url = "https://sso.jrtashjian.com/application/o/${data.proxmox_virtual_environment_nodes.nodes.names[0]}/"
  client_id  = authentik_provider_oauth2.pve-node.client_id
  client_key = authentik_provider_oauth2.pve-node.client_secret

  # Username mapping
  username_claim = "username"

  # User provisioning
  autocreate = true

  # Group mapping
  groups_claim      = "groups"
  groups_autocreate = false

  # Scopes and prompt
  scopes         = "email profile"
  query_userinfo = true

  default = true
}