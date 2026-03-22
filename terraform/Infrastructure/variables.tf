variable "argocd_admin_password" {
  type        = string
  sensitive   = true
  description = "ArgoCD admin password for provider authentication"
}

variable "repo_url" {
  type        = string
  default     = "https://github.com/Ryzhankou/Vyking.git"
  description = "Git repository URL"
}

variable "target_revision" {
  type        = string
  default     = "main"
  description = "Git branch or tag for Argo CD to sync. Override with TF_VAR_target_revision=$(git branch --show-current) for current branch"
}
