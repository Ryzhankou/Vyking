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
  default     = "myapp"
  description = "Argo CD project name for the application."
}

variable "application_name" {
  type        = string
  default     = "myapp"
  description = "Argo CD Application name."
}

variable "destination_namespaces" {
  type        = list(string)
  default     = ["game-frontend", "game-backend", "myapp"]
  description = "List of namespaces the project can deploy to."
}

variable "destination_server" {
  type        = string
  default     = "https://kubernetes.default.svc"
  description = "Kubernetes API server URL for Argo CD destination."
}

variable "helm_chart_path" {
  type        = string
  default     = "applications/helm_chart"
  description = "Path to Helm chart in the Git repository."
}

variable "helm_release_name" {
  type        = string
  default     = "myapp"
  description = "Helm release name for the application deployment."
}

variable "helm_value_files" {
  type        = list(string)
  default     = ["values-kind.yaml"]
  description = "List of values files to use (relative to chart path). Empty for defaults only."
}
