# Shared Git repository
resource "argocd_repository" "apps_repo" {
  repo = var.repo_url
}

# Infrastructure module: MySQL + backup CronJob (deploys first)
# module "Infrastructure" {
#   source = "./modules/Infrastructure"

#   repo_url        = argocd_repository.apps_repo.repo
#   target_revision = var.target_revision
# }

# App module: Frontend + Backend (deploys after infrastructure)
module "App" {
  source = "./modules/App"

  repo_url               = argocd_repository.apps_repo.repo
  target_revision        = var.target_revision
  project_name           = var.app_project_name
  application_name       = var.app_application_name
  destination_namespaces = var.app_destination_namespaces
  destination_server     = var.app_destination_server
  helm_chart_path        = var.app_helm_chart_path
  helm_release_name      = var.app_helm_release_name
  helm_value_files       = var.app_helm_value_files

  # depends_on = [module.Infrastructure]
}
