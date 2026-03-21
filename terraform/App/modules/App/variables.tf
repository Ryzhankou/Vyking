variable "repo_url" {
  type        = string
  description = "Git repository URL"
}

variable "target_revision" {
  type        = string
  description = "Git branch or tag to sync (e.g. main, feature/task-compliance)"
}
