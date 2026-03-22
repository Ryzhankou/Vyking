provider "argocd" {
  port_forward_with_namespace = "argocd"

  username = "admin"
  password = var.argocd_admin_password

  config_path = "~/.kube/config"
  context     = "kind-dev-global-cluster-0"
}