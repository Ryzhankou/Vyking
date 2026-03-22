variable "argocd_admin_password" {
  type        = string
  sensitive   = true
  description = "Argo CD admin password for provider authentication."
}

variable "repo_url" {
  type        = string
  default     = "https://github.com/Ryzhankou/Vyking.git"
  description = "Git repository URL for Argo CD Application."
}

variable "target_revision" {
  type        = string
  default     = "main"
  description = "Git branch or tag for Argo CD to sync. Override with TF_VAR_target_revision=$(git branch --show-current) for current branch."
}

variable "kube_config_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Path to kubeconfig for Argo CD provider."
}

variable "cluster_context" {
  type        = string
  default     = "kind-dev-global-cluster-0"
  description = "Kubernetes context. Override for different environments."
}

# Infrastructure module overrides (optional)
variable "infra_helm_chart_path" {
  type        = string
  default     = "infrastructure/mysql-chart"
  description = "Path to infrastructure Helm chart (e.g. infrastructure/mysql-chart or applications/database-chart)."
}

variable "infra_destination_namespace" {
  type        = string
  default     = "game-backend"
  description = "Namespace for infrastructure deployment."
}

variable "infra_extra_helm_repos" {
  type = list(object({
    repo = string
    type = string
  }))
  default = [
    {
      repo = "https://charts.bitnami.com/bitnami"
      type = "helm"
    }
  ]
  description = "Extra Helm repos for infrastructure (e.g. Bitnami). Use [] for charts from Git only."
}
