# App module: Frontend and Backend

resource "argocd_project" "app" {
  metadata {
    name      = var.project_name
    namespace = "argocd"
  }

  spec {
    description = "Project for ${var.project_name}"

    source_repos = [
      var.repo_url
    ]

    dynamic "destination" {
      for_each = var.destination_namespaces
      content {
        server    = var.destination_server
        namespace = destination.value
      }
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

resource "argocd_application" "app" {
  metadata {
    name      = var.application_name
    namespace = "argocd"
  }

  wait = true

  spec {
    project = argocd_project.app.metadata[0].name

    destination {
      server    = var.destination_server
      namespace = var.application_name
    }

    source {
      repo_url        = var.repo_url
      path            = var.helm_chart_path
      target_revision = var.target_revision

      helm {
        release_name = var.helm_release_name
        value_files  = var.helm_value_files
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
    argocd_project.app
  ]
}
