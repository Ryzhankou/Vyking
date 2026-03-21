variable "argocd_admin_password" {
  type        = string
  sensitive   = true
  description = "ArgoCD admin password for provider authentication"
}
