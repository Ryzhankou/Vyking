variable "argocd_admin_password" {
  type        = string
  sensitive   = true
  description = "Argo CD admin password for initial setup. Used to set admin password hash in Helm values."
}

variable "argocd_admin_password_mtime" {
  type        = string
  description = "Timestamp when admin password was last changed. Triggers Argo CD secret update (e.g. $(date -u +%Y-%m-%dT%H:%M:%SZ))."
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

variable "kube_config_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Path to kubeconfig for Helm provider."
}

variable "cluster_context" {
  type        = string
  default     = "kind-dev-global-cluster-0"
  description = "Kubernetes context for Helm provider. Override for different clusters."
}