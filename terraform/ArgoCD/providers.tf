provider "helm" {
    kubernetes {
        config_path = "~/.kube/config"
        config_context = "kind-dev-global-cluster-0"

    }
}