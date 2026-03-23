variable "argocd_admin_password" {
  type        = string
  sensitive   = true
  description = "Argo CD admin password for provider authentication."
}

variable "repo_url" {
  type        = string
  default     = "https://github.com/Ryzhankou/Vyking.git"
  description = "Git repository URL for the root Argo CD Application."
}

variable "target_revision" {
  type        = string
  default     = "main"
  description = "Git branch for the root App of Apps to sync from. Child apps use HEAD (default branch). Override with TF_VAR_target_revision=$(git branch --show-current) for a feature branch."
}

variable "kube_config_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Path to kubeconfig file for Argo CD provider."
}

variable "cluster_context" {
  type        = string
  default     = "kind-dev-global-cluster-0"
  description = "Kubernetes context name. Override for different clusters."
}
