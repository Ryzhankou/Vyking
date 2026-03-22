variable "argocd_admin_password" {
  type        = string
  sensitive   = true
  description = "Argo CD admin password for initial setup."
}

variable "argocd_admin_password_mtime" {
  type        = string
  description = "Timestamp when admin password was last changed. Triggers Argo CD secret update."
}

variable "argocd_namespace" {
  type        = string
  default     = "argocd"
  description = "Kubernetes namespace for Argo CD installation."
}

variable "argocd_chart_repository" {
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
  description = "Helm repository URL for Argo CD chart."
}

variable "argocd_chart_name" {
  type        = string
  default     = "argo-cd"
  description = "Helm chart name for Argo CD."
}