variable "repo_url" {
  type        = string
  description = "Git repository URL for Argo CD Application."
}

variable "target_revision" {
  type        = string
  description = "Git branch or tag for Argo CD to sync (e.g. main, feature/task-compliance)."
}

variable "project_name" {
  type        = string
  default     = "infrastructure"
  description = "Argo CD project name for infrastructure."
}

variable "application_name" {
  type        = string
  default     = "infrastructure"
  description = "Argo CD Application name."
}

variable "destination_namespace" {
  type        = string
  default     = "game-backend"
  description = "Kubernetes namespace for infrastructure deployment."
}

variable "destination_server" {
  type        = string
  default     = "https://kubernetes.default.svc"
  description = "Kubernetes API server for Argo CD destination."
}

variable "helm_chart_path" {
  type        = string
  default     = "infrastructure/mysql-chart"
  description = "Path to infrastructure Helm chart in the Git repository."
}

variable "helm_release_name" {
  type        = string
  default     = "infrastructure"
  description = "Helm release name for infrastructure."
}

variable "extra_helm_repos" {
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
  description = "Additional Helm repositories (e.g. Bitnami) for Argo CD project."
}
