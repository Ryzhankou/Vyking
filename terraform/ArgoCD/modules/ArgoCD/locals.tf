# Derived values for Argo CD Helm release
locals {
  argocd_admin_password_hash = bcrypt(var.argocd_admin_password, 10)
}