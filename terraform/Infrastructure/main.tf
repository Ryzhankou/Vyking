# Shared Git repository
resource "argocd_repository" "apps_repo" {
  repo = var.repo_url
}

# Infrastructure module: MySQL + backup CronJob (deploys first)
module "Infrastructure" {
  source = "./modules/Infrastructure"

  repo_url        = argocd_repository.apps_repo.repo
  target_revision = var.target_revision
}

# App module: Frontend + Backend (deploys after infrastructure)
# module "App" {
#   source = "./modules/App"

#   repo_url        = argocd_repository.apps_repo.repo
#   target_revision = var.target_revision

#   depends_on = [module.Infrastructure]
# }
