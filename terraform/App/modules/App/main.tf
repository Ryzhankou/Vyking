# Public Git repository (https://github.com/Ryzhankou/Vyking)
resource "argocd_repository" "apps_repo" {
  repo = "https://github.com/Ryzhankou/Vyking.git"
}

resource "argocd_project" "myapp" {
  metadata {
    name      = "myapp"
    namespace = "argocd"
  }

  spec {
    description = "Project for myapp"

    source_repos = [
      argocd_repository.apps_repo.repo
    ]

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "myapp"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "game-frontend"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "game-backend"
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }

    namespace_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

resource "argocd_application" "myapp" {
  metadata {
    name      = "myapp"
    namespace = "argocd"
  }

  wait = true

  spec {
    project = argocd_project.myapp.metadata[0].name

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "myapp"
    }

    source {
      repo_url        = argocd_repository.apps_repo.repo
      path            = "applications/helm_chart"
      target_revision = "main"

      helm {
        release_name = "myapp"
        value_files   = ["values-kind.yaml"]
      }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }

      sync_options = ["CreateNamespace=true"]
    }
  }

  depends_on = [
    argocd_repository.apps_repo,
    argocd_project.myapp
  ]
}