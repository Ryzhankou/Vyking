provider "argocd" {
  port_forward_with_namespace = "argocd"

  username = "admin"
  password = var.argocd_admin_password

  config_path = var.kube_config_path
  context     = var.cluster_context
}