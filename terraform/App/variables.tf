variable "argocd_admin_password" {
  type        = string
  sensitive   = true
  description = "Argo CD admin password for provider authentication."
}

variable "repo_url" {
  type        = string
  default     = "https://github.com/Ryzhankou/Vyking.git"
  description = "Git repository URL for Argo CD Applications."
}

variable "target_revision" {
  type        = string
  default     = "main"
  description = "Git branch or tag for Argo CD to sync. Override with TF_VAR_target_revision=$(git branch --show-current) for current branch."
}

variable "kube_config_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Path to kubeconfig file for Argo CD provider."
}

variable "cluster_context" {
  type        = string
  default     = "kind-dev-global-cluster-0"
  description = "Kubernetes context name. Override for different clusters (dev, staging, prod)."
}

# App module overrides (optional)
variable "app_project_name" {
  type        = string
  default     = "myapp"
  description = "Argo CD project name for the application."
}

variable "app_application_name" {
  type        = string
  default     = "myapp"
  description = "Argo CD Application name."
}

variable "app_destination_namespaces" {
  type        = list(string)
  default     = ["game-frontend", "game-backend", "myapp"]
  description = "Namespaces the App project can deploy to."
}

variable "app_destination_server" {
  type        = string
  default     = "https://kubernetes.default.svc"
  description = "Kubernetes API server for Argo CD destination."
}

variable "app_helm_chart_path" {
  type        = string
  default     = "applications/helm_chart"
  description = "Path to Helm chart in the Git repository."
}

variable "app_helm_release_name" {
  type        = string
  default     = "myapp"
  description = "Helm release name."
}

variable "app_helm_value_files" {
  type        = list(string)
  default     = ["values-kind.yaml"]
  description = "Helm values files. Use [] for default values only."
}
