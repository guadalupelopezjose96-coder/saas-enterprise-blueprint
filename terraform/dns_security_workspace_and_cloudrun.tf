# =============================================================================
# ENDURECIMIENTO GCP ORGANIZATION, CLOUD RUN GEN2, BREAK-GLASS IAM Y DNSSEC
# Integracion con gcp-marketplace-saas (Fourphonix / AuraIntelCore v1.0.0) | DNS-01
# =============================================================================

variable "gcp_org_policies_enforced" {
  type = list(string)
  default = [
    "constraints/iam.disableServiceAccountKeyCreation",
    "constraints/storage.uniformBucketLevelAccess",
    "constraints/storage.publicAccessPrevention",
    "constraints/compute.requireShieldedVm",
    "constraints/iam.allowedPolicyMemberDomains"
  ]
}

variable "workspace_dnssec_and_mail_hardening" {
  type = map(string)
  default = {
    dnssec_state      = "on_ enforced_ds_record"
    spf_policy        = "v=spf1 include:_spf.google.com include:spf.stripe.com -all"
    dmarc_policy      = "v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s"
    caa_restriction   = "0 issue \"pki.goog\"; 0 issue \"letsencrypt.org\""
    cloud_run_runtime = "gcr.io/distroless/python3-debian12:nonroot (UID 65532)"
    superadmin_alert  = "iam_groups_breakglass_critical_metric_alert_enabled"
  }
}
