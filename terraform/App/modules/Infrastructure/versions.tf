terraform {
  required_version = "~> 1.14.0"

  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "~> 7.15"
    }
  }
}
